//
//  ImportView.swift
//  Matrix Life Logger
//
//  Created by Claude on 6/19/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let modelContext: ModelContext
    @StateObject private var importer: SQLiteImporter
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self._importer = StateObject(wrappedValue: SQLiteImporter(modelContext: modelContext))
    }
    
    @State private var isFilePickerPresented = false
    @State private var selectedFileURL: URL?
    @State private var importResult: SQLiteImporter.ImportResult?
    @State private var showingResult = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down.on.square")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Import Life Logger Data")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Import your existing journal entries from Wei's Life Logger or compatible SQLite databases")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Import Section
                VStack(spacing: 16) {
                    if let selectedURL = selectedFileURL {
                        // Selected File Display
                        HStack {
                            Image(systemName: "doc.circle.fill")
                                .foregroundColor(.green)
                            Text(selectedURL.lastPathComponent)
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Button("Change") {
                                isFilePickerPresented = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        if importer.isImporting {
                            // Import Progress
                            VStack(spacing: 12) {
                                ProgressView(value: importer.importProgress)
                                    .progressViewStyle(LinearProgressViewStyle())
                                
                                Text("Importing entries... \(Int(importer.importProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        } else {
                            // Import Button
                            Button(action: startImport) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Start Import")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                        }
                    } else {
                        // File Picker Button
                        Button(action: { isFilePickerPresented = true }) {
                            VStack(spacing: 12) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 24))
                                Text("Select Database File")
                                    .font(.headline)
                                Text("Choose your SQLite database file (.db, .sqlite)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(20)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            )
                        }
                    }
                    
                    // Error Display
                    if let error = importer.importError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color(.systemRed).opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Tips Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Tips for importing:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Supported formats: SQLite (.db, .sqlite, .sqlite3)")
                        Text("• Existing entries won't be duplicated")
                        Text("• Import progress is shown during the process")
                        Text("• Large databases may take several minutes")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Import Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(importer.isImporting)
                }
            }
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [
                UTType(filenameExtension: "db")!,
                UTType(filenameExtension: "sqlite")!,
                UTType(filenameExtension: "sqlite3")!
            ],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Import Complete", isPresented: $showingResult) {
            Button("OK") {
                dismiss()
            }
        } message: {
            if let result = importResult {
                Text("Successfully imported \(result.entriesImported) entries. \(result.duplicatesSkipped) duplicates skipped.")
            }
        }
        .onReceive(importer.$lastImportedCount) { count in
            if count > 0 && !importer.isImporting {
                showingResult = true
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                selectedFileURL = url
            }
        case .failure(let error):
            importer.importError = "File selection failed: \(error.localizedDescription)"
        }
    }
    
    private func startImport() {
        guard let fileURL = selectedFileURL else { return }
        
        Task {
            do {
                // Start accessing the security-scoped resource
                let accessing = fileURL.startAccessingSecurityScopedResource()
                defer {
                    if accessing {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }
                
                let result = try await importer.importDatabase(from: fileURL.path)
                
                await MainActor.run {
                    self.importResult = result
                    if result.errors.isEmpty {
                        showingResult = true
                    } else {
                        importer.importError = "Import completed with \(result.errors.count) errors"
                    }
                }
                
            } catch {
                await MainActor.run {
                    importer.importError = "Import failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: JournalEntry.self, configurations: config)
    
    return ImportView(modelContext: container.mainContext)
}