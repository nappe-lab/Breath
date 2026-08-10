//
//  BreathingExercise.swift
//  Breath
//

import Foundation

/// Defines a complete breathing exercise with multiple phases
struct BreathingExercise: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let phases: [BreathingPhase]
    
    init(id: UUID = UUID(), name: String, description: String, phases: [BreathingPhase]) {
        self.id = id
        self.name = name
        self.description = description
        self.phases = phases
    }
    
    /// Total duration of one complete cycle through all phases
    var cycleDuration: TimeInterval {
        phases.reduce(0) { $0 + $1.duration }
    }
    
    /// Human-readable pattern string (e.g. "4-4-4-4")
    var patternString: String {
        phases.map { String(Int($0.duration)) }.joined(separator: "-")
    }
    
    // MARK: - Preloaded Exercises
    
    static let boxBreathing = BreathingExercise(
        name: "Box Breathing",
        description: "Equal parts inhale, hold, exhale, hold — grounding and centering",
        phases: [
            BreathingPhase(type: .inhale, duration: 4),
            BreathingPhase(type: .holdFull, duration: 4),
            BreathingPhase(type: .exhale, duration: 4),
            BreathingPhase(type: .holdEmpty, duration: 4)
        ]
    )
    
    static let fourSevenEight = BreathingExercise(
        name: "4-7-8 Breathing",
        description: "Dr. Weil's technique for deep relaxation and sleep",
        phases: [
            BreathingPhase(type: .inhale, duration: 4),
            BreathingPhase(type: .holdFull, duration: 7),
            BreathingPhase(type: .exhale, duration: 8)
        ]
    )
    
    static let physiologicalSigh = BreathingExercise(
        name: "Physiological Sigh",
        description: "Double inhale to rapidly reduce stress — from Huberman Lab",
        phases: [
            BreathingPhase(type: .doubleInhale, duration: 2),
            BreathingPhase(type: .exhale, duration: 8)
        ]
    )
    
    static let library = [boxBreathing, fourSevenEight, physiologicalSigh]
}
