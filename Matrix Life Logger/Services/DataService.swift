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
        // Create date formatter for parsing timestamps
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        
        // Real journal entries data
        let sampleEntries = [
            JournalEntry(
                timestamp: formatter.date(from: "Jun 12, 2025 at 9:40 PM") ?? Date().addingTimeInterval(-86400 * 4),
                content: "Amazing dinner at Zingerman's Roadhouse tonight. The BBQ was incredible, but even better was the conversation with mom and dad. We ended up talking for hours about their early days in Michigan, stories I'd never heard before. Dad told me about his first job at Ford and how different Ann Arbor was in the 80s. These are the moments that matter.",
                latitude: 42.2808,
                longitude: -83.7430,
                tags: ["70°F and Clear", "Zingerman's Roadhouse", "family time"],
                mood: .veryHappy,
                activity: .family,
                visualizationType: .orb
            ),
            JournalEntry(
                timestamp: formatter.date(from: "Jun 13, 2025 at 7:15 AM") ?? Date().addingTimeInterval(-86400 * 3),
                content: "Terrible sleep last night. Kept thinking about the presentation tomorrow. My brain wouldn't shut off - kept running through scenarios and what-ifs. Finally gave up around 2 AM and did some reading instead. Sometimes I think my anxiety brain is both a curse and a superpower.",
                latitude: 42.2808,
                longitude: -83.7430,
                tags: ["65°F and Rainy", "Sleep", "anxiety", "presentation prep"],
                mood: .sad,
                activity: .health,
                visualizationType: .particle
            ),
            JournalEntry(
                timestamp: formatter.date(from: "Jun 14, 2025 at 4:20 PM") ?? Date().addingTimeInterval(-86400 * 2),
                content: "Went for a long walk around the Arb with Sarah. We talked about how technology is changing the way we remember things. She made a good point about how photos used to be special because they were rare, but now we take hundreds and remember none. Makes me think the life logging approach might be onto something - quality over quantity in capturing moments.",
                latitude: 42.2970,
                longitude: -83.7178,
                tags: ["75°F and Overcast", "Personal", "The Arb", "deep conversation"],
                mood: .happy,
                activity: .social,
                visualizationType: .constellation
            ),
            JournalEntry(
                timestamp: formatter.date(from: "Jun 15, 2025 at 10:30 AM") ?? Date().addingTimeInterval(-86400 * 1),
                content: "Had the most productive morning session working on the new Matrix Life Logger project. The spatial computing concepts are finally clicking. There's something magical about visualizing your life data in 3D space - it makes patterns so much more obvious. Grabbed coffee from Literati and spent 3 hours coding without any distractions.",
                latitude: 42.2808,
                longitude: -83.7430,
                tags: ["68°F and Sunny", "Work", "Literati", "productive coding"],
                mood: .veryHappy,
                activity: .work,
                visualizationType: .orb
            ),
            JournalEntry(
                timestamp: formatter.date(from: "Jun 16, 2025 at 8:55 PM") ?? Date(),
                content: "I think my stomach is starting to feel a little better. It was the caffeine withdrawal symptoms rather than nicotine, which I'm very happy about. I can definitely feel my stomach improving. I'm currently at Socotra, a Yemeni coffeehouse on Packard Road. Yes, Yemeni—not \"Yammy\" or \"yummy.\" Wow, Yemeni. I saw a group of friends all wearing motorcycle jackets, and it got me reflecting on youth—the wonders of having a community to be around and do really cool stuff with. I miss that. That was me for about a decade at Starbucks. I thought it was awesome back then, and now looking back, I realize I had it really good.",
                latitude: 42.2808,
                longitude: -83.7430,
                tags: ["73°F and Partly Cloudy", "Socotra coffeehouse", "health improvement", "community reflection"],
                mood: .happy,
                activity: .social,
                visualizationType: .particle
            )
        ]
        
        entries = sampleEntries
    }
    
    func getEntriesForTimelineRiver() -> [JournalEntry] {
        return entries.sorted { $0.timestamp < $1.timestamp }
    }
}