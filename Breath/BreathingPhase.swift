//
//  BreathingPhase.swift
//  Breath
//

import Foundation

/// Represents a single phase in a breathing exercise
struct BreathingPhase: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let type: PhaseType
    let duration: TimeInterval // in seconds
    
    init(type: PhaseType, duration: TimeInterval) {
        self.id = UUID()
        self.type = type
        self.duration = duration
    }
}

/// Types of breathing phases, each with distinct haptic patterns
enum PhaseType: String, Codable, CaseIterable {
    case inhale = "Inhale"
    case holdFull = "Hold (full)"
    case exhale = "Exhale"
    case holdEmpty = "Hold (empty)"
    case doubleInhale = "Double Inhale" // Special case for physiological sigh
    
    var systemImage: String {
        switch self {
        case .inhale, .doubleInhale:
            return "arrow.down.circle"
        case .holdFull, .holdEmpty:
            return "pause.circle"
        case .exhale:
            return "arrow.up.circle"
        }
    }
}
