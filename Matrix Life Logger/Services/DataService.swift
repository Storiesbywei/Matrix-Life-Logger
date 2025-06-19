//
//  DataService.swift
//  Matrix Life Logger
//
//  Created by Claude on 6/19/25.
//

import Foundation
import SwiftData
import CoreLocation

import Combine

@MainActor
@Observable
class DataService: ObservableObject {
    private var modelContext: ModelContext?
    private(set) var entries: [JournalEntry] = []
    private(set) var isLoading = false
    
    init() {
        loadSampleData()
    }
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        loadEntries()
    }
    
    private func loadEntries() {
        guard let modelContext = modelContext else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let descriptor = FetchDescriptor<JournalEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            entries = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load journal entries: \(error)")
            entries = []
        }
    }
    
    func addEntry(_ entry: JournalEntry) {
        guard let modelContext = modelContext else { return }
        
        modelContext.insert(entry)
        do {
            try modelContext.save()
            loadEntries()
        } catch {
            print("Failed to save entry: \(error)")
        }
    }
    
    private func loadSampleData() {
        // Sample data for Timeline River visualization
        let sampleEntries = [
            JournalEntry(
                timestamp: Date().addingTimeInterval(-86400 * 7), // 7 days ago
                content: "Started working on Matrix Life Logger project. Excited about bringing spatial computing to life logging!",
                mood: .happy,
                activity: .work,
                visualizationType: .orb
            ),
            JournalEntry(
                timestamp: Date().addingTimeInterval(-86400 * 6), // 6 days ago
                content: "Morning run in the park. Beautiful weather today.",
                mood: .veryHappy,
                activity: .exercise,
                visualizationType: .particle
            ),
            JournalEntry(
                timestamp: Date().addingTimeInterval(-86400 * 5), // 5 days ago
                content: "Coffee with Sarah. Great conversation about spatial computing possibilities.",
                mood: .happy,
                activity: .social,
                visualizationType: .orb
            ),
            JournalEntry(
                timestamp: Date().addingTimeInterval(-86400 * 4), // 4 days ago
                content: "Learning RealityKit. The particle systems are amazing!",
                mood: .happy,
                activity: .learning,
                visualizationType: .constellation
            ),
            JournalEntry(
                timestamp: Date().addingTimeInterval(-86400 * 3), // 3 days ago
                content: "Family dinner. Mom's cooking is the best.",
                mood: .veryHappy,
                activity: .family,
                visualizationType: .orb
            ),
            JournalEntry(
                timestamp: Date().addingTimeInterval(-86400 * 2), // 2 days ago
                content: "Watched a movie. Needed some downtime after intense coding.",
                mood: .neutral,
                activity: .entertainment,
                visualizationType: .particle
            ),
            JournalEntry(
                timestamp: Date().addingTimeInterval(-86400 * 1), // 1 day ago
                content: "Made breakthrough with Timeline River visualization. Hand gestures working perfectly!",
                mood: .veryHappy,
                activity: .work,
                visualizationType: .constellation
            ),
            JournalEntry(
                timestamp: Date(),
                content: "Today I'm implementing the Timeline River in Matrix Life Logger. This is going to be amazing!",
                mood: .veryHappy,
                activity: .work,
                visualizationType: .orb
            )
        ]
        
        entries = sampleEntries
    }
    
    func getEntriesForTimelineRiver() -> [JournalEntry] {
        return entries.sorted { $0.timestamp < $1.timestamp }
    }
}