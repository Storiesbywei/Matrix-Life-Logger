//
//  LegacyDataConverter.swift
//  Matrix Life Logger
//
//  Created by Claude on 6/19/25.
//

import Foundation
import SwiftData
import CoreLocation
import Combine

@MainActor
class LegacyDataConverter: ObservableObject {
    @Published var conversionProgress: Double = 0.0
    @Published var isConverting = false
    @Published var conversionError: String?
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    struct ConversionResult {
        let entriesConverted: Int
        let errors: [String]
        let skipped: Int
        let duplicatesFound: Int
    }
    
    func convertLegacyEntries(_ legacyEntries: [LegacyEntry]) async throws -> ConversionResult {
        isConverting = true
        conversionError = nil
        conversionProgress = 0.0
        
        defer {
            isConverting = false
        }
        
        var convertedCount = 0
        var errors: [String] = []
        var skippedCount = 0
        var duplicatesFound = 0
        
        let totalEntries = legacyEntries.count
        
        for (index, legacyEntry) in legacyEntries.enumerated() {
            do {
                // Check for existing entry to avoid duplicates
                if try await isDuplicateEntry(legacyEntry) {
                    duplicatesFound += 1
                    continue
                }
                
                // Convert legacy entry to JournalEntry
                let journalEntry = try convertToJournalEntry(legacyEntry)
                
                // Validate the converted entry
                if try validateJournalEntry(journalEntry) {
                    // Save to SwiftData
                    modelContext.insert(journalEntry)
                    convertedCount += 1
                } else {
                    skippedCount += 1
                    errors.append("Entry \(index + 1): Failed validation")
                }
                
            } catch {
                errors.append("Entry \(index + 1): \(error.localizedDescription)")
                skippedCount += 1
            }
            
            // Update progress
            conversionProgress = Double(index + 1) / Double(totalEntries)
            
            // Yield control periodically for UI updates
            if index % 50 == 0 {
                try await Task.sleep(nanoseconds: 1_000_000) // 1ms
            }
        }
        
        // Save all changes
        try modelContext.save()
        
        return ConversionResult(
            entriesConverted: convertedCount,
            errors: errors,
            skipped: skippedCount,
            duplicatesFound: duplicatesFound
        )
    }
    
    private func convertToJournalEntry(_ legacyEntry: LegacyEntry) throws -> JournalEntry {
        // Validate required fields
        guard !legacyEntry.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConversionError.emptyContent
        }
        
        // Convert mood string to MoodType
        let mood = convertMood(from: legacyEntry.mood)
        
        // Convert activity string to ActivityType
        let activity = convertActivity(from: legacyEntry.activity)
        
        // Determine visualization type based on content and metadata
        let visualizationType = determineVisualizationType(for: legacyEntry)
        
        // Generate spatial position for timeline river
        let spatialPosition = generateSpatialPosition(for: legacyEntry, mood: mood, activity: activity)
        
        return JournalEntry(
            timestamp: legacyEntry.timestamp,
            content: legacyEntry.content.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: legacyEntry.latitude,
            longitude: legacyEntry.longitude,
            tags: cleanTags(legacyEntry.tags),
            mood: mood,
            activity: activity,
            visualizationType: visualizationType,
            spatialPositionX: spatialPosition.x,
            spatialPositionY: spatialPosition.y,
            spatialPositionZ: spatialPosition.z
        )
    }
    
    private func convertMood(from moodString: String?) -> MoodType {
        guard let moodString = moodString?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) else {
            return .neutral
        }
        
        // Map common mood strings to MoodType
        switch moodString {
        case "very happy", "excited", "ecstatic", "joyful", "elated", "5":
            return .veryHappy
        case "happy", "good", "positive", "cheerful", "content", "4":
            return .happy
        case "neutral", "okay", "fine", "normal", "average", "3":
            return .neutral
        case "sad", "down", "low", "unhappy", "melancholy", "2":
            return .sad
        case "very sad", "depressed", "terrible", "awful", "devastated", "1":
            return .verySad
        default:
            // Try to parse numeric mood scales (1-5 or 1-10)
            if let numericMood = Int(moodString) {
                switch numericMood {
                case 9...10, 5: return .veryHappy
                case 7...8, 4: return .happy
                case 5...6, 3: return .neutral
                case 3...4, 2: return .sad
                case 1...2, 1: return .verySad
                default: return .neutral
                }
            }
            
            // Check for mood keywords in longer strings
            if moodString.contains("happy") || moodString.contains("great") || moodString.contains("excellent") {
                return .happy
            } else if moodString.contains("sad") || moodString.contains("bad") || moodString.contains("awful") {
                return .sad
            }
            
            return .neutral
        }
    }
    
    private func convertActivity(from activityString: String?) -> ActivityType {
        guard let activityString = activityString?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) else {
            return .unknown
        }
        
        // Map common activity strings to ActivityType
        switch activityString {
        case "work", "job", "office", "meeting", "business", "career", "professional":
            return .work
        case "exercise", "workout", "gym", "running", "fitness", "sports", "training":
            return .exercise
        case "social", "friends", "party", "gathering", "socializing", "meetup":
            return .social
        case "food", "eating", "meal", "restaurant", "cooking", "dining", "lunch", "dinner", "breakfast":
            return .food
        case "travel", "trip", "vacation", "journey", "adventure", "touring", "exploring":
            return .travel
        case "learning", "study", "education", "reading", "course", "school":
            return .learning
        case "entertainment", "movie", "tv", "gaming", "music", "concert", "show", "fun":
            return .entertainment
        case "health", "medical", "doctor", "therapy", "wellness", "healthcare":
            return .health
        case "family", "parents", "children", "relatives", "home", "kids":
            return .family
        default:
            // Check for activity keywords in longer strings
            if activityString.contains("work") || activityString.contains("office") {
                return .work
            } else if activityString.contains("exercise") || activityString.contains("gym") {
                return .exercise
            } else if activityString.contains("friend") || activityString.contains("social") {
                return .social
            } else if activityString.contains("food") || activityString.contains("eat") {
                return .food
            } else if activityString.contains("travel") || activityString.contains("trip") {
                return .travel
            } else if activityString.contains("learn") || activityString.contains("study") {
                return .learning
            } else if activityString.contains("family") || activityString.contains("home") {
                return .family
            }
            
            return .unknown
        }
    }
    
    private func determineVisualizationType(for entry: LegacyEntry) -> VisualizationType {
        // Determine visualization type based on content, activity, and metadata
        
        // If location data exists, prefer location-based visualizations
        if entry.latitude != nil && entry.longitude != nil {
            return .cluster
        }
        
        // For activities that benefit from path visualization
        if entry.activity?.lowercased().contains("travel") == true ||
           entry.activity?.lowercased().contains("exercise") == true {
            return .path
        }
        
        // For social activities, use constellation
        if entry.activity?.lowercased().contains("social") == true ||
           entry.activity?.lowercased().contains("family") == true {
            return .constellation
        }
        
        // For significant or emotional entries, use orb
        if entry.content.count > 200 ||
           entry.mood?.lowercased().contains("very") == true {
            return .orb
        }
        
        // Default to particle for standard entries
        return .particle
    }
    
    private func generateSpatialPosition(for entry: LegacyEntry, mood: MoodType, activity: ActivityType) -> SIMD3<Float> {
        // Generate spatial position for Timeline River visualization
        
        // X position: timeline position (will be set by Timeline River system)
        let x: Float = 0.0
        
        // Y position: based on mood (higher for happier moods)
        let y: Float = mood.intensity * 2.0 - 1.0 // Range: -1.0 to 1.0
        
        // Z position: based on activity type to create lanes
        let z: Float = {
            switch activity {
            case .work: return -1.5
            case .exercise: return -1.0
            case .social: return -0.5
            case .food: return 0.0
            case .travel: return 0.5
            case .learning: return 1.0
            case .entertainment: return 1.5
            case .health: return -2.0
            case .family: return 2.0
            case .unknown: return 0.0
            }
        }()
        
        return SIMD3<Float>(x, y, z)
    }
    
    private func cleanTags(_ tags: [String]) -> [String] {
        return tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
    }
    
    private func validateJournalEntry(_ entry: JournalEntry) throws -> Bool {
        // Validate that the journal entry meets minimum requirements
        
        guard !entry.content.isEmpty else {
            throw ConversionError.emptyContent
        }
        
        guard entry.content.count <= 10000 else {
            throw ConversionError.contentTooLong
        }
        
        // Validate location data if present
        if let latitude = entry.latitude, let longitude = entry.longitude {
            guard abs(latitude) <= 90 && abs(longitude) <= 180 else {
                throw ConversionError.invalidLocation
            }
        }
        
        return true
    }
    
    private func isDuplicateEntry(_ legacyEntry: LegacyEntry) async throws -> Bool {
        // Check for duplicate entries based on content and timestamp
        let descriptor = FetchDescriptor<JournalEntry>()
        let existingEntries = try modelContext.fetch(descriptor)
        
        return existingEntries.contains { entry in
            entry.content == legacyEntry.content &&
            entry.timestamp == legacyEntry.timestamp
        }
    }
}

// MARK: - Supporting Types

enum ConversionError: LocalizedError {
    case emptyContent
    case contentTooLong
    case invalidLocation
    case invalidTimestamp
    
    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "Entry content cannot be empty"
        case .contentTooLong:
            return "Entry content exceeds maximum length"
        case .invalidLocation:
            return "Invalid location coordinates"
        case .invalidTimestamp:
            return "Invalid timestamp"
        }
    }
}