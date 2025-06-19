//
//  GestureInteractionSystem.swift
//  Matrix Life Logger
//
//  Created by Claude on 6/19/25.
//

import Foundation
import RealityKit
import SwiftUI
import Combine

@MainActor
class GestureInteractionSystem: ObservableObject {
    @Published var selectedEntity: Entity?
    @Published var hoveredEntity: Entity?
    @Published var timelineScale: Float = 1.0
    @Published var timelinePosition: SIMD3<Float> = SIMD3<Float>(0, 0, -3)
    
    private var originalPositions: [Entity: SIMD3<Float>] = [:]
    private var isDragging = false
    private var lastDragPosition: SIMD3<Float>?
    
    // Timeline navigation state
    @Published var currentTimeIndex: Int = 0
    @Published var isNavigating = false
    
    func handleTap(on entity: Entity) -> JournalEntry? {
        print("GestureInteractionSystem: Handling tap on entity: \(entity.name)")
        
        // Find entry data in the tapped entity or its parents
        var currentEntity: Entity? = entity
        
        while let checkEntity = currentEntity {
            print("  Checking entity: \(checkEntity.name), has EntryDataComponent: \(checkEntity.components.has(EntryDataComponent.self))")
            
            if let entryComponent = checkEntity.components[EntryDataComponent.self] {
                print("  Found EntryDataComponent with entry: \(entryComponent.entry.content)")
                selectedEntity = checkEntity
                highlightEntity(checkEntity)
                return entryComponent.entry
            }
            currentEntity = checkEntity.parent
        }
        
        print("  No EntryDataComponent found in entity hierarchy")
        return nil
    }
    
    func handleDragGesture(translation: SIMD3<Float>, entity: Entity) {
        guard entity.components[EntryDataComponent.self] != nil else { return }
        
        if !isDragging {
            isDragging = true
            originalPositions[entity] = entity.position
        }
        
        // Move the particle smoothly
        if let originalPosition = originalPositions[entity] {
            entity.position = originalPosition + translation * 0.5
        }
        
        // Add visual feedback
        addDragFeedback(to: entity)
    }
    
    func handleDragEnd(entity: Entity) {
        isDragging = false
        
        // Animate back to original position with spring effect
        if let originalPosition = originalPositions[entity] {
            animateToPosition(entity: entity, targetPosition: originalPosition)
        }
        
        removeDragFeedback(from: entity)
        originalPositions.removeValue(forKey: entity)
    }
    
    func handlePinchGesture(scale: Float, location: SIMD3<Float>) {
        let newScale = max(0.5, min(3.0, timelineScale * scale))
        timelineScale = newScale
        
        // Emit scale change event for river system to handle
        NotificationCenter.default.post(
            name: .timelineScaleChanged,
            object: nil,
            userInfo: ["scale": newScale, "location": location]
        )
    }
    
    func handleSwipeGesture(direction: SwipeDirection, velocity: Float) {
        guard !isNavigating else { return }
        
        isNavigating = true
        
        switch direction {
        case .left:
            navigateToNextTimeperiod()
        case .right:
            navigateToPreviousTimeperiod()
        case .up:
            expandTimelineView()
        case .down:
            collapseTimelineView()
        }
        
        // Reset navigation state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isNavigating = false
        }
    }
    
    private func highlightEntity(_ entity: Entity) {
        // Add highlight effect
        guard let modelEntity = entity.children.first as? ModelEntity else { return }
        
        // Create highlight material
        var highlightMaterial = UnlitMaterial()
        highlightMaterial.color = .init(tint: .white)
        
        // Temporarily change material
        let originalMaterials = modelEntity.model?.materials ?? []
        modelEntity.model?.materials = [highlightMaterial]
        
        // Restore original materials after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            modelEntity.model?.materials = originalMaterials
        }
        
        // Add scale animation
        let scaleUp = Transform(scale: SIMD3<Float>(1.2, 1.2, 1.2))
        let scaleDown = Transform(scale: SIMD3<Float>(1.0, 1.0, 1.0))
        
        let animation = FromToByAnimation(
            from: scaleDown,
            to: scaleUp,
            duration: 0.15,
            timing: .easeInOut,
            bindTarget: .transform,
            repeatMode: .none,
            fillMode: .forwards
        )
        
        if let animationResource = try? AnimationResource.generate(with: animation) {
            entity.playAnimation(animationResource)
        }
    }
    
    private func addDragFeedback(to entity: Entity) {
        // Add trail effect or glow while dragging
        guard let modelEntity = entity.children.first as? ModelEntity else { return }
        
        var glowMaterial = UnlitMaterial()
        glowMaterial.color = .init(tint: .cyan)
        
        modelEntity.model?.materials = [glowMaterial]
    }
    
    private func removeDragFeedback(from entity: Entity) {
        // Restore original materials
        guard let modelEntity = entity.children.first as? ModelEntity,
              let entryComponent = entity.components[EntryDataComponent.self] else { return }
        
        var originalMaterial = UnlitMaterial()
        originalMaterial.color = .init(tint: entryComponent.entry.mood.color)
        
        modelEntity.model?.materials = [originalMaterial]
    }
    
    private func animateToPosition(entity: Entity, targetPosition: SIMD3<Float>) {
        let animation = FromToByAnimation(
            from: Transform(translation: entity.position),
            to: Transform(translation: targetPosition),
            duration: 0.5,
            timing: .easeOut,
            bindTarget: .transform
        )
        
        if let animationResource = try? AnimationResource.generate(with: animation) {
            entity.playAnimation(animationResource)
        }
    }
    
    private func navigateToNextTimeperiod() {
        // Animate timeline movement to show next time period
        NotificationCenter.default.post(
            name: .timelineNavigate,
            object: nil,
            userInfo: ["direction": "next"]
        )
    }
    
    private func navigateToPreviousTimeperiod() {
        // Animate timeline movement to show previous time period
        NotificationCenter.default.post(
            name: .timelineNavigate,
            object: nil,
            userInfo: ["direction": "previous"]
        )
    }
    
    private func expandTimelineView() {
        // Zoom out to show more of the timeline
        timelineScale = min(3.0, timelineScale * 1.5)
        NotificationCenter.default.post(
            name: .timelineScaleChanged,
            object: nil,
            userInfo: ["scale": timelineScale]
        )
    }
    
    private func collapseTimelineView() {
        // Zoom in for detailed view
        timelineScale = max(0.5, timelineScale * 0.75)
        NotificationCenter.default.post(
            name: .timelineScaleChanged,
            object: nil,
            userInfo: ["scale": timelineScale]
        )
    }
}

enum SwipeDirection {
    case left, right, up, down
}

// Notification names for gesture events
extension Notification.Name {
    static let timelineScaleChanged = Notification.Name("timelineScaleChanged")
    static let timelineNavigate = Notification.Name("timelineNavigate")
    static let particleSelected = Notification.Name("particleSelected")
}