//
//  SQLiteImporter.swift
//  Matrix Life Logger
//
//  Created by Claude on 6/19/25.
//

import Foundation
import SQLite3
import CoreLocation
import SwiftData
import Combine

@MainActor
class SQLiteImporter: ObservableObject {
    @Published var importProgress: Double = 0.0
    @Published var isImporting = false
    @Published var importError: String?
    @Published var lastImportedCount = 0
    
    private var db: OpaquePointer?
    private let modelContext: ModelContext
    private lazy var converter = LegacyDataConverter(modelContext: modelContext)
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    struct ImportResult {
        let entriesImported: Int
        let errors: [String]
        let duplicatesSkipped: Int
        let totalProcessed: Int
    }
    
    func importDatabase(from path: String) async throws -> ImportResult {
        isImporting = true
        importError = nil
        importProgress = 0.0
        
        defer {
            closeDatabase()
            isImporting = false
        }
        
        // Open the SQLite database
        guard openDatabase(at: path) else {
            throw ImportError.databaseOpenFailed
        }
        
        // Analyze the database schema first
        let schema = try analyzeSchema()
        print("SQLiteImporter: Detected schema: \(schema)")
        
        // Import data based on detected schema
        let legacyEntries = try await extractLegacyEntries(using: schema)
        
        // Convert legacy entries to JournalEntry models
        let conversionResult = try await converter.convertLegacyEntries(legacyEntries)
        
        let result = ImportResult(
            entriesImported: conversionResult.entriesConverted,
            errors: conversionResult.errors,
            duplicatesSkipped: conversionResult.duplicatesFound,
            totalProcessed: legacyEntries.count
        )
        
        lastImportedCount = result.entriesImported
        return result
    }
    
    private func openDatabase(at path: String) -> Bool {
        let result = sqlite3_open(path, &db)
        if result != SQLITE_OK {
            importError = "Failed to open database: \(String(cString: sqlite3_errmsg(db)))"
            return false
        }
        return true
    }
    
    private func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }
    
    private func analyzeSchema() throws -> DatabaseSchema {
        var schema = DatabaseSchema()
        
        // Get all table names
        let tableQuery = "SELECT name FROM sqlite_master WHERE type='table';"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, tableQuery, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let tableName = String(cString: sqlite3_column_text(statement, 0))
                schema.tables.append(tableName)
            }
        }
        sqlite3_finalize(statement)
        
        // Analyze the most likely entries table
        if let entriesTable = detectEntriesTable(from: schema.tables) {
            schema.entriesTable = entriesTable
            schema.columns = try getTableColumns(entriesTable)
        }
        
        return schema
    }
    
    private func detectEntriesTable(from tables: [String]) -> String? {
        // Look for common table names used in life logging apps
        let candidates = ["entries", "journal_entries", "logs", "life_entries", "diary_entries", "activities"]
        
        for candidate in candidates {
            if tables.contains(candidate) {
                return candidate
            }
        }
        
        // If no exact match, look for tables containing "entry" or "log"
        for table in tables {
            if table.lowercased().contains("entry") || table.lowercased().contains("log") {
                return table
            }
        }
        
        // Fallback to the first non-system table
        return tables.first { !$0.hasPrefix("sqlite_") }
    }
    
    private func getTableColumns(_ tableName: String) throws -> [ColumnInfo] {
        var columns: [ColumnInfo] = []
        let query = "PRAGMA table_info(\(tableName));"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let name = String(cString: sqlite3_column_text(statement, 1))
                let type = String(cString: sqlite3_column_text(statement, 2))
                let column = ColumnInfo(name: name, type: type)
                columns.append(column)
            }
        }
        sqlite3_finalize(statement)
        
        return columns
    }
    
    private func extractLegacyEntries(using schema: DatabaseSchema) async throws -> [LegacyEntry] {
        guard let entriesTable = schema.entriesTable else {
            throw ImportError.noEntriesTableFound
        }
        
        var legacyEntries: [LegacyEntry] = []
        var totalProcessed = 0
        
        // First, count total entries for progress tracking
        let totalEntries = try getTotalEntryCount(from: entriesTable)
        
        // Build dynamic query based on detected columns
        let query = buildSelectQuery(for: entriesTable, columns: schema.columns)
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                totalProcessed += 1
                
                do {
                    let entry = try parseEntry(from: statement, columns: schema.columns)
                    legacyEntries.append(entry)
                    
                    // Update progress
                    await updateProgress(current: totalProcessed, total: totalEntries)
                    
                } catch {
                    print("SQLiteImporter: Failed to parse row \(totalProcessed): \(error)")
                    // Continue processing other entries even if one fails
                }
                
                // Yield control periodically for UI updates
                if totalProcessed % 100 == 0 {
                    try await Task.sleep(nanoseconds: 1_000_000) // 1ms
                }
            }
        } else {
            throw ImportError.queryFailed("Failed to prepare select statement")
        }
        
        sqlite3_finalize(statement)
        
        return legacyEntries
    }
    
    private func getTotalEntryCount(from table: String) throws -> Int {
        let query = "SELECT COUNT(*) FROM \(table);"
        var statement: OpaquePointer?
        var count = 0
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(statement, 0))
            }
        }
        sqlite3_finalize(statement)
        
        return count
    }
    
    private func buildSelectQuery(for table: String, columns: [ColumnInfo]) -> String {
        let columnNames = columns.map { $0.name }.joined(separator: ", ")
        return "SELECT \(columnNames) FROM \(table) ORDER BY rowid;"
    }
    
    private func parseEntry(from statement: OpaquePointer?, columns: [ColumnInfo]) throws -> LegacyEntry {
        var entry = LegacyEntry()
        
        for (index, column) in columns.enumerated() {
            let columnName = column.name.lowercased()
            
            // Map common column names to our data structure
            switch columnName {
            case "id", "entry_id", "_id":
                if let text = sqlite3_column_text(statement, Int32(index)) {
                    entry.originalId = String(cString: text)
                }
                
            case "content", "text", "description", "note", "entry":
                if let text = sqlite3_column_text(statement, Int32(index)) {
                    entry.content = String(cString: text)
                }
                
            case "timestamp", "date", "created_at", "time":
                let timestamp = sqlite3_column_int64(statement, Int32(index))
                entry.timestamp = Date(timeIntervalSince1970: TimeInterval(timestamp))
                
            case "latitude", "lat":
                let latitude = sqlite3_column_double(statement, Int32(index))
                if latitude != 0 {
                    entry.latitude = latitude
                }
                
            case "longitude", "lng", "lon":
                let longitude = sqlite3_column_double(statement, Int32(index))
                if longitude != 0 {
                    entry.longitude = longitude
                }
                
            case "mood", "emotion", "feeling":
                if let text = sqlite3_column_text(statement, Int32(index)) {
                    entry.mood = String(cString: text)
                }
                
            case "activity", "category", "type", "action":
                if let text = sqlite3_column_text(statement, Int32(index)) {
                    entry.activity = String(cString: text)
                }
                
            case "tags", "labels":
                if let text = sqlite3_column_text(statement, Int32(index)) {
                    let tagsString = String(cString: text)
                    entry.tags = tagsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                }
                
            default:
                // Store unknown columns as metadata
                if let text = sqlite3_column_text(statement, Int32(index)) {
                    let value = String(cString: text)
                    entry.metadata[columnName] = value
                }
            }
        }
        
        return entry
    }
    
    
    private func updateProgress(current: Int, total: Int) async {
        let progress = Double(current) / Double(max(total, 1))
        await MainActor.run {
            self.importProgress = progress
        }
    }
}

// MARK: - Supporting Types

struct DatabaseSchema {
    var tables: [String] = []
    var entriesTable: String?
    var columns: [ColumnInfo] = []
}

struct ColumnInfo {
    let name: String
    let type: String
}

struct LegacyEntry {
    var originalId: String?
    var content: String = ""
    var timestamp: Date = Date()
    var latitude: Double?
    var longitude: Double?
    var mood: String?
    var activity: String?
    var tags: [String] = []
    var metadata: [String: String] = [:]
}

enum ImportError: LocalizedError {
    case databaseOpenFailed
    case noEntriesTableFound
    case queryFailed(String)
    case invalidEntryData(String)
    
    var errorDescription: String? {
        switch self {
        case .databaseOpenFailed:
            return "Failed to open the database file"
        case .noEntriesTableFound:
            return "No entries table found in the database"
        case .queryFailed(let message):
            return "Database query failed: \(message)"
        case .invalidEntryData(let message):
            return "Invalid entry data: \(message)"
        }
    }
}