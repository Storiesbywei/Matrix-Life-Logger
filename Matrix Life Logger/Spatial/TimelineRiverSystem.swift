//
//  TimelineRiverSystem.swift
//  Matrix Life Logger
//
//  Created by Claude on 6/19/25.
//

import Foundation
import RealityKit
import SwiftUI
import Combine

@MainActor
class TimelineRiverSystem: ObservableObject {
    private let riverLength: Float = 10.0
    private let riverWidth: Float = 2.0
    private let riverHeight: Float = 0.1
    private let particleCount = 50
    
    private var riverEntity: Entity?
    private var particleEntities: [Entity] = []
    private var animationTimer: Timer?
    
    func createTimelineRiver(entries: [JournalEntry]) -> Entity {
        let riverContainer = Entity()
        riverContainer.name = "TimelineRiver"
        
        // Create the river base
        let riverBase = createRiverBase()
        riverContainer.addChild(riverBase)
        
        // Create entry particles
        let particles = createEntryParticles(entries: entries)
        particles.forEach { riverContainer.addChild($0) }
        
        // Add flowing effect
        addFlowingEffect(to: riverContainer)
        
        self.riverEntity = riverContainer
        return riverContainer
    }
    
    private func createRiverBase() -> Entity {
        let mesh = MeshResource.generateBox(
            width: riverWidth,
            height: riverHeight,
            depth: riverLength
        )
        
        // Create a translucent blue material for the river
        var material = UnlitMaterial()
        material.color = .init(tint: UIColor.systemBlue.withAlphaComponent(0.3))
        
        let riverBase = ModelEntity(mesh: mesh, materials: [material])
        riverBase.name = "RiverBase"
        riverBase.position = SIMD3<Float>(0, -0.5, 0)
        
        return riverBase
    }
    
    private func createEntryParticles(entries: [JournalEntry]) -> [Entity] {
        var particles: [Entity] = []
        
        for (index, entry) in entries.enumerated() {
            let particle = createParticleForEntry(entry, index: index, total: entries.count)
            particles.append(particle)
        }
        
        self.particleEntities = particles
        return particles
    }
    
    private func createParticleForEntry(_ entry: JournalEntry, index: Int, total: Int) -> Entity {
        let particle = Entity()
        particle.name = "EntryParticle_\(index)_\(entry.id.uuidString.prefix(8))"
        
        // Create particle geometry based on visualization type
        let mesh: MeshResource
        let size: Float = 0.1 + (entry.mood.intensity * 0.1) // Size based on mood intensity
        
        switch entry.visualizationType {
        case .particle:
            mesh = MeshResource.generateSphere(radius: size)
        case .orb:
            mesh = MeshResource.generateSphere(radius: size * 1.5)
        case .constellation:
            mesh = MeshResource.generateBox(width: size, height: size, depth: size)
        case .path:
            mesh = MeshResource.generateCylinder(height: size * 2, radius: size * 0.5)
        case .cluster:
            mesh = MeshResource.generateSphere(radius: size * 1.2)
        }
        
        // Create material with mood-based color
        var material = UnlitMaterial()
        material.color = .init(tint: entry.mood.color)
        
        // Add emission for glowing effect using available properties
        if entry.mood == .veryHappy || entry.mood == .happy {
            // UnlitMaterial doesn't have emissiveColor, so we'll just use the bright color
            material.color = .init(tint: entry.mood.color)
        }
        
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        particle.addChild(modelEntity)
        
        // Position particle along the river
        let progress = Float(index) / Float(max(total - 1, 1))
        let zPosition = (progress - 0.5) * riverLength
        let xOffset = Float.random(in: -riverWidth/3...riverWidth/3)
        let yPosition = Float(0.2) + Float.random(in: 0...0.3)
        
        particle.position = SIMD3<Float>(xOffset, yPosition, zPosition)
        
        // Store entry data in components
        particle.components.set(EntryDataComponent(entry: entry))
        
        // Add input target component for gesture recognition
        particle.components.set(InputTargetComponent())
        
        // Add collision component for proper hit testing
        let shape: ShapeResource
        switch entry.visualizationType {
        case .particle, .orb, .cluster:
            shape = ShapeResource.generateSphere(radius: size * 1.2) // Slightly larger for easier interaction
        case .constellation:
            shape = ShapeResource.generateBox(size: [size * 1.2, size * 1.2, size * 1.2])
        case .path:
            // Use box for path visualization since generateCylinder is not available
            shape = ShapeResource.generateBox(size: [size * 1.2, size * 2.4, size * 1.2])
        }
        
        particle.components.set(CollisionComponent(shapes: [shape], isStatic: false))
        
        // Enable hover effects
        particle.components.set(HoverEffectComponent())
        
        // Add gentle floating animation
        addFloatingAnimation(to: particle, index: index)
        
        return particle
    }
    
    private func addFloatingAnimation(to entity: Entity, index: Int) {
        // Create a gentle floating motion
        let offsetDelay = Float(index) * 0.1
        let floatHeight: Float = 0.1
        let duration: TimeInterval = 3.0 + Double.random(in: -0.5...0.5)
        
        // Vertical floating motion
        let floatUp = Transform(
            translation: entity.position + SIMD3<Float>(0, floatHeight, 0)
        )
        let floatDown = Transform(
            translation: entity.position - SIMD3<Float>(0, floatHeight, 0)
        )
        
        // Create animation sequence
        let animationDefinition = FromToByAnimation(
            from: floatDown,
            to: floatUp,
            duration: duration,
            timing: .easeInOut,
            isAdditive: false,
            bindTarget: .transform,
            repeatMode: .none,
            fillMode: .forwards
        )
        
        // Start animation with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(offsetDelay)) {
            if let animationResource = try? AnimationResource.generate(with: animationDefinition) {
                entity.playAnimation(animationResource.repeat())
            }
        }
    }
    
    private func addFlowingEffect(to riverContainer: Entity) {
        // Add particle system for flowing water effect
        let particleSystem = createFlowingParticles()
        riverContainer.addChild(particleSystem)
        
        // Start continuous animation
        startRiverFlow()
    }
    
    private func createFlowingParticles() -> Entity {
        let flowContainer = Entity()
        flowContainer.name = "FlowingParticles"
        
        // Create small flowing particles
        for _ in 0..<particleCount {
            let flowParticle = Entity()
            
            let mesh = MeshResource.generateSphere(radius: 0.02)
            var material = UnlitMaterial()
            material.color = .init(tint: UIColor.white.withAlphaComponent(0.6))
            
            let modelEntity = ModelEntity(mesh: mesh, materials: [material])
            flowParticle.addChild(modelEntity)
            
            // Random position along the river
            let x = Float.random(in: -riverWidth/2...riverWidth/2)
            let y = Float.random(in: 0...0.1)
            let z = Float.random(in: -riverLength/2...riverLength/2)
            
            flowParticle.position = SIMD3<Float>(x, y, z)
            flowContainer.addChild(flowParticle)
        }
        
        return flowContainer
    }
    
    private func startRiverFlow() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateFlowingParticles()
            }
        }
    }
    
    private func updateFlowingParticles() {
        guard let riverEntity = riverEntity,
              let flowContainer = riverEntity.findEntity(named: "FlowingParticles") else { return }
        
        // Move flowing particles
        for child in flowContainer.children {
            var position = child.position
            position.z += 0.05 // Flow speed
            
            // Reset particle position when it reaches the end
            if position.z > riverLength/2 {
                position.z = -riverLength/2
                position.x = Float.random(in: -riverWidth/2...riverWidth/2)
                position.y = Float.random(in: 0...0.1)
            }
            
            child.position = position
        }
    }
    
    func stopAnimations() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    deinit {
        // Stop animations immediately without async task
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

// Component to store entry data with particles
struct EntryDataComponent: Component {
    let entry: JournalEntry
}