//
//  JournalEntry.swift
//  Matrix Life Logger
//
//  Created by Claude on 6/19/25.
//

import Foundation
import SwiftData
import CoreLocation
import RealityKit
import UIKit

@Model
class JournalEntry {
    var id: UUID
    var timestamp: Date
    var content: String
    var latitude: Double?
    var longitude: Double?
    var tags: [String]
    var mood: MoodType
    var activity: ActivityType
    var visualizationType: VisualizationType
    var spatialPositionX: Float?
    var spatialPositionY: Float?
    var spatialPositionZ: Float?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        content: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        tags: [String] = [],
        mood: MoodType = .neutral,
        activity: ActivityType = .unknown,
        visualizationType: VisualizationType = .particle,
        spatialPositionX: Float? = nil,
        spatialPositionY: Float? = nil,
        spatialPositionZ: Float? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.content = content
        self.latitude = latitude
        self.longitude = longitude
        self.tags = tags
        self.mood = mood
        self.activity = activity
        self.visualizationType = visualizationType
        self.spatialPositionX = spatialPositionX
        self.spatialPositionY = spatialPositionY
        self.spatialPositionZ = spatialPositionZ
    }
    
    // Computed properties for convenience
    var location: CLLocation? {
        get {
            guard let latitude = latitude, let longitude = longitude else { return nil }
            return CLLocation(latitude: latitude, longitude: longitude)
        }
        set {
            latitude = newValue?.coordinate.latitude
            longitude = newValue?.coordinate.longitude
        }
    }
    
    var spatialPosition: SIMD3<Float>? {
        get {
            guard let x = spatialPositionX, let y = spatialPositionY, let z = spatialPositionZ else { return nil }
            return SIMD3<Float>(x, y, z)
        }
        set {
            spatialPositionX = newValue?.x
            spatialPositionY = newValue?.y
            spatialPositionZ = newValue?.z
        }
    }
}

enum MoodType: String, CaseIterable, Codable {
    case veryHappy = "very_happy"
    case happy = "happy"
    case neutral = "neutral"
    case sad = "sad"
    case verySad = "very_sad"
    
    var color: UIColor {
        switch self {
        case .veryHappy: return .systemYellow
        case .happy: return .systemGreen
        case .neutral: return .systemBlue
        case .sad: return .systemOrange
        case .verySad: return .systemRed
        }
    }
    
    var intensity: Float {
        switch self {
        case .veryHappy: return 1.0
        case .happy: return 0.8
        case .neutral: return 0.5
        case .sad: return 0.3
        case .verySad: return 0.1
        }
    }
}

enum ActivityType: String, CaseIterable, Codable {
    case work = "work"
    case exercise = "exercise"
    case social = "social"
    case food = "food"
    case travel = "travel"
    case learning = "learning"
    case entertainment = "entertainment"
    case health = "health"
    case family = "family"
    case unknown = "unknown"
    
    var color: UIColor {
        switch self {
        case .work: return .systemBlue
        case .exercise: return .systemRed
        case .social: return .systemPink
        case .food: return .systemOrange
        case .travel: return .systemPurple
        case .learning: return .systemGreen
        case .entertainment: return .systemYellow
        case .health: return .systemTeal
        case .family: return .systemIndigo
        case .unknown: return .systemGray
        }
    }
}

enum VisualizationType: String, CaseIterable, Codable {
    case particle = "particle"
    case orb = "orb"
    case constellation = "constellation"
    case path = "path"
    case cluster = "cluster"
}