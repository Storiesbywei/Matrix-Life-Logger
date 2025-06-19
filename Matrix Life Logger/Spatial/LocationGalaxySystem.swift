//
//  LocationGalaxySystem.swift
//  Matrix Life Logger
//
//  Created by Claude on 6/19/25.
//

import Foundation
import RealityKit
import SwiftUI
import CoreLocation
import simd
import Combine

@MainActor
class LocationGalaxySystem: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    @Published var galaxyEntity: Entity?
    @Published var isGenerating = false
    @Published var totalLocations = 0
    
    private var locationBodies: [LocationBody] = []
    private var galaxyCenter: SIMD3<Float> = SIMD3<Float>(0, 1.5, -2)
    private let galaxyRadius: Float = 8.0
    
    struct LocationBody {
        let entity: Entity
        let location: CLLocation
        let visitCount: Int
        let activities: [String]
        let position: SIMD3<Float>
    }
    
    struct LocationCluster {
        let centerLocation: CLLocation
        let locations: [CLLocation]
        let totalVisits: Int
        let activities: [String]
    }
    
    func generateGalaxy(from entries: [JournalEntry]) async {
        isGenerating = true
        defer { isGenerating = false }
        
        // Extract and cluster locations
        let locationClusters = await clusterLocations(from: entries)
        totalLocations = locationClusters.count
        
        // Create galaxy root entity
        let galaxy = Entity()
        galaxy.name = "LocationGalaxy"
        galaxy.position = galaxyCenter
        
        // Create celestial bodies for each location cluster
        var bodies: [LocationBody] = []
        
        for (index, cluster) in locationClusters.enumerated() {
            let body = await createCelestialBody(for: cluster, at: index, total: locationClusters.count)
            galaxy.addChild(body.entity)
            bodies.append(body)
            
            // Add orbiting activity particles
            await addOrbitingActivities(to: body.entity, activities: cluster.activities)
            
            // Yield control for UI updates
            if index % 10 == 0 {
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
        }
        
        // Add galaxy-wide effects
        await addGalaxyEffects(to: galaxy)
        
        // Store results
        self.galaxyEntity = galaxy
        self.locationBodies = bodies
    }
    
    private func clusterLocations(from entries: [JournalEntry]) async -> [LocationCluster] {
        // Group entries by location (with some clustering tolerance)
        var locationGroups: [String: [JournalEntry]] = [:]
        
        for entry in entries {
            guard let location = entry.location else { continue }
            
            // Create a location key with reduced precision for clustering
            let clusterKey = locationClusterKey(for: location)
            
            if locationGroups[clusterKey] == nil {
                locationGroups[clusterKey] = []
            }
            locationGroups[clusterKey]?.append(entry)
        }
        
        // Convert to LocationCluster objects
        var clusters: [LocationCluster] = []
        
        for (_, entries) in locationGroups {
            guard let firstEntry = entries.first,
                  let centerLocation = firstEntry.location else { continue }
            
            let totalVisits = entries.count
            let activities = entries.map { $0.activity.rawValue }.unique()
            let locations = entries.compactMap { $0.location }
            
            let cluster = LocationCluster(
                centerLocation: centerLocation,
                locations: locations,
                totalVisits: totalVisits,
                activities: activities
            )
            clusters.append(cluster)
        }
        
        // Sort by visit count (most visited first)
        return clusters.sorted { $0.totalVisits > $1.totalVisits }
    }
    
    private func locationClusterKey(for location: CLLocation) -> String {
        // Cluster locations within ~1km radius
        let precision = 0.01 // roughly 1km
        let lat = round(location.coordinate.latitude / precision) * precision
        let lng = round(location.coordinate.longitude / precision) * precision
        return "\(lat),\(lng)"
    }
    
    private func createCelestialBody(for cluster: LocationCluster, at index: Int, total: Int) async -> LocationBody {
        let bodyEntity = Entity()
        bodyEntity.name = "LocationBody_\(index)"
        
        // Position in galaxy using spiral pattern
        let position = calculateGalaxyPosition(for: index, total: total)
        bodyEntity.position = position
        
        // Create the celestial body mesh
        let bodySize = calculateBodySize(visitCount: cluster.totalVisits)
        let bodyColor = calculateBodyColor(activities: cluster.activities)
        
        let mesh = MeshResource.generateSphere(radius: bodySize)
        let material = createCelestialMaterial(color: bodyColor, visitCount: cluster.totalVisits)
        let modelComponent = ModelComponent(mesh: mesh, materials: [material])
        
        bodyEntity.components.set(modelComponent)
        
        // Add interaction components
        let bounds = mesh.bounds
        let collisionShape = ShapeResource.generateSphere(radius: bodySize)
        bodyEntity.components.set(CollisionComponent(shapes: [collisionShape]))
        bodyEntity.components.set(InputTargetComponent())
        bodyEntity.components.set(HoverEffectComponent())
        
        // Add custom component for location data
        bodyEntity.components.set(LocationDataComponent(
            location: cluster.centerLocation,
            visitCount: cluster.totalVisits,
            activities: cluster.activities
        ))
        
        // Add gentle rotation animation
        let rotationAnimation = FromToByAnimation<Transform>(
            from: Transform(rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))),
            to: Transform(rotation: simd_quatf(angle: 2 * .pi, axis: SIMD3<Float>(0, 1, 0))),
            duration: 20.0 + Double(Float.random(in: -5...5)), // Varying rotation speeds
            bindTarget: .transform
        )
        
        let animationResource = try? AnimationResource.generate(with: rotationAnimation)
        if let animationResource = animationResource {
            bodyEntity.playAnimation(animationResource.repeat())
        }
        
        return LocationBody(
            entity: bodyEntity,
            location: cluster.centerLocation,
            visitCount: cluster.totalVisits,
            activities: cluster.activities,
            position: position
        )
    }
    
    private func calculateGalaxyPosition(for index: Int, total: Int) -> SIMD3<Float> {
        // Use a spiral galaxy pattern
        let angle = Float(index) * 2.0 * .pi / Float(total) * 3.0 // Multiple spirals
        let radius = galaxyRadius * (0.3 + 0.7 * Float(index) / Float(total))
        
        let x = radius * cos(angle) + Float.random(in: -0.5...0.5)
        let y = Float.random(in: -1.0...1.0) * 0.3 // Slight vertical variation
        let z = radius * sin(angle) + Float.random(in: -0.5...0.5)
        
        return SIMD3<Float>(x, y, z)
    }
    
    private func calculateBodySize(visitCount: Int) -> Float {
        // Size based on visit frequency
        let minSize: Float = 0.1
        let maxSize: Float = 0.4
        let normalizedVisits = min(Float(visitCount) / 20.0, 1.0) // Cap at 20 visits
        return minSize + (maxSize - minSize) * normalizedVisits
    }
    
    private func calculateBodyColor(activities: [String]) -> UIColor {
        // Color based on dominant activity
        guard let dominantActivity = activities.first else { return UIColor.systemBlue }
        
        if let activityType = ActivityType(rawValue: dominantActivity) {
            return activityType.color
        }
        
        return UIColor.systemBlue
    }
    
    private func createCelestialMaterial(color: UIColor, visitCount: Int) -> RealityKit.Material {
        var material = UnlitMaterial()
        material.color = .init(tint: color)
        
        // Add glow effect for frequently visited locations
        if visitCount > 5 {
            // UnlitMaterial does NOT support emissiveColor, so skip setting it.
            // To simulate glow, increasing alpha tint to 0.7 for visual emphasis
            material.color = .init(tint: color.withAlphaComponent(0.7))
            // material.emissiveColor = .init(color: color.withAlphaComponent(0.3)) <- Not supported in UnlitMaterial
        }
        
        return material
    }
    
    private func addOrbitingActivities(to body: Entity, activities: [String]) async {
        guard activities.count > 1 else { return }
        
        let orbitRadius: Float = 0.8
        
        for (index, activity) in activities.enumerated() {
            let orbitingParticle = Entity()
            orbitingParticle.name = "OrbitingActivity_\(activity)"
            
            // Create small particle
            let particleSize: Float = 0.05
            let mesh = MeshResource.generateSphere(radius: particleSize)
            
            let activityType = ActivityType(rawValue: activity) ?? .unknown
            var material = UnlitMaterial()
            material.color = .init(tint: activityType.color)
            
            orbitingParticle.components.set(ModelComponent(mesh: mesh, materials: [material]))
            
            // Position in orbit
            let angle = Float(index) * 2.0 * .pi / Float(activities.count)
            let x = orbitRadius * cos(angle)
            let z = orbitRadius * sin(angle)
            orbitingParticle.position = SIMD3<Float>(x, 0, z)
            
            // Add orbital animation
            let orbitAnimation = FromToByAnimation<Transform>(
                from: Transform(rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))),
                to: Transform(rotation: simd_quatf(angle: 2 * .pi, axis: SIMD3<Float>(0, 1, 0))),
                duration: Double(15.0 + Float(index) * 2.0),
                bindTarget: .transform
            )
            
            let animationResource = try? AnimationResource.generate(with: orbitAnimation)
            if let animationResource = animationResource {
                orbitingParticle.playAnimation(animationResource.repeat())
            }
            
            body.addChild(orbitingParticle)
        }
    }
    
    private func addGalaxyEffects(to galaxy: Entity) async {
        // Add ambient particles for galaxy atmosphere
        let particleCount = 50
        
        for i in 0..<particleCount {
            let particle = Entity()
            particle.name = "GalaxyParticle_\(i)"
            
            // Random position within galaxy
            let radius = Float.random(in: 2...galaxyRadius * 1.2)
            let angle = Float.random(in: 0...2 * .pi)
            let height = Float.random(in: -2...2)
            
            let x = radius * Float(cos(Double(angle)))
            let y = height
            let z = radius * Float(sin(Double(angle)))
            particle.position = SIMD3<Float>(x, y, z)
            
            // Small glowing particle
            let size = Float.random(in: 0.02...0.08)
            let mesh = MeshResource.generateSphere(radius: size)
            
            var material = UnlitMaterial()
            material.color = .init(tint: UIColor.white.withAlphaComponent(0.3))
            // emissiveColor not available on UnlitMaterial, so skipping:
            // material.emissiveColor = .init(color: UIColor.white.withAlphaComponent(0.1))
            
            particle.components.set(ModelComponent(mesh: mesh, materials: [material]))
            
            // Add floating animation
            let floatAnimation = FromToByAnimation<Transform>(
                from: Transform(translation: particle.position),
                to: Transform(translation: particle.position + SIMD3<Float>(0, 0.2, 0)),
                duration: Double(3.0 + Float.random(in: -1...1)),
                bindTarget: .transform
            )
            
            let animationResource = try? AnimationResource.generate(with: floatAnimation)
            if let animationResource = animationResource {
                // There is no supported ping-pong mode in playAnimation; to mimic ping-pong, use .autoreverses if available, otherwise just repeat
                particle.playAnimation(animationResource.repeat(), transitionDuration: 0.0)
            }
            
            galaxy.addChild(particle)
        }
    }
    
    func findLocationBody(for location: CLLocation) -> LocationBody? {
        return locationBodies.first { body in
            body.location.distance(from: location) < 1000 // Within 1km
        }
    }
    
    func teleportToLocation(_ body: LocationBody) {
        // Implementation for teleporting to a location
        // This would be used for navigation within the galaxy
    }
}

// MARK: - Supporting Components

struct LocationDataComponent: Component {
    let location: CLLocation
    let visitCount: Int
    let activities: [String]
}

// MARK: - Extensions

extension Array where Element: Hashable {
    func unique() -> [Element] {
        return Array(Set(self))
    }
}
