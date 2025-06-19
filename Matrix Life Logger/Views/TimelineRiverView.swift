//
//  TimelineRiverView.swift
//  Matrix Life Logger
//
//  Created by Claude on 6/19/25.
//

import SwiftUI
import RealityKit

struct TimelineRiverView: View {
    @Environment(AppModel.self) private var appModel
    @StateObject private var dataService = DataService()
    @StateObject private var riverSystem = TimelineRiverSystem()
    @StateObject private var gestureSystem = GestureInteractionSystem()
    @State private var selectedEntry: JournalEntry?
    @State private var showingEntryDetail = false
    @State private var riverEntity: Entity?
    
    var body: some View {
        RealityView { content in
            // Create the Timeline River
            let entries = dataService.getEntriesForTimelineRiver()
            let river = riverSystem.createTimelineRiver(entries: entries)
            content.add(river)
            
            // Position the river in front of the user
            river.position = gestureSystem.timelinePosition
            river.scale = SIMD3<Float>(repeating: gestureSystem.timelineScale)
            
            self.riverEntity = river
            
        } update: { content in
            // Update river position and scale based on gestures
            if let river = riverEntity {
                river.position = gestureSystem.timelinePosition
                river.scale = SIMD3<Float>(repeating: gestureSystem.timelineScale)
            }
        }
        .gesture(
            // Tap gesture for selecting particles
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { event in
                    handleTap(on: event.entity)
                }
        )
        .gesture(
            // Drag gesture for moving particles
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { event in
                    handleDrag(event)
                }
                .onEnded { event in
                    handleDragEnd(event)
                }
        )
        .gesture(
            // Magnify gesture for scaling timeline
            MagnifyGesture()
                .onChanged { value in
                    gestureSystem.handlePinchGesture(
                        scale: Float(value.magnification),
                        location: SIMD3<Float>(0, 0, 0)
                    )
                }
        )
        .onReceive(NotificationCenter.default.publisher(for: .timelineScaleChanged)) { notification in
            // Handle scale changes from gesture system
            if let scale = notification.userInfo?["scale"] as? Float {
                gestureSystem.timelineScale = scale
            }
        }
        .sheet(isPresented: $showingEntryDetail) {
            if let entry = selectedEntry {
                EntryDetailView(entry: entry)
            }
        }
    }
    
    private func handleTap(on entity: Entity) {
        print("Tap detected on entity: \(entity.name)")
        if let entry = gestureSystem.handleTap(on: entity) {
            print("Found journal entry: \(entry.content)")
            selectedEntry = entry
            showingEntryDetail = true
        } else {
            print("No journal entry found for tapped entity")
        }
    }
    
    private func handleDrag(_ event: EntityTargetValue<DragGesture.Value>) {
        let translation = SIMD3<Float>(
            Float(event.translation.width * 0.001), // Scale down for reasonable movement
            Float(event.translation.height * 0.001),
            0
        )
        gestureSystem.handleDragGesture(translation: translation, entity: event.entity)
    }
    
    private func handleDragEnd(_ event: EntityTargetValue<DragGesture.Value>) {
        gestureSystem.handleDragEnd(entity: event.entity)
    }
}

struct EntryDetailView: View {
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Circle()
                        .fill(Color(entry.mood.color))
                        .frame(width: 20, height: 20)
                    
                    Text(entry.activity.rawValue.capitalized)
                        .font(.headline)
                        .foregroundColor(Color(entry.activity.color))
                    
                    Spacer()
                    
                    Text(entry.timestamp, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Content
                Text(entry.content)
                    .font(.body)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                
                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Mood:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(entry.mood.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Visualization:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(entry.visualizationType.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    if !entry.tags.isEmpty {
                        HStack {
                            Text("Tags:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(entry.tags.joined(separator: ", "))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    TimelineRiverView()
        .environment(AppModel())
}