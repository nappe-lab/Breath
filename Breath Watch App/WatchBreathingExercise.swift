//
//  WatchBreathingExercise.swift
//  Breath Watch App
//
//  A watch-side mirror of the iPhone app's exercise library (see BreathingExercise.swift /
//  BreathingPhase.swift in the Breath target) - same three patterns, same phase shapes and
//  durations. Not literally shared code: the two targets have no shared framework (see the
//  note in WatchBreathingSession.swift), so this duplicates just the data needed to drive a
//  session and its haptics on watchOS.

import Foundation

enum WatchPhaseType: Equatable {
    case inhale, holdFull, exhale, holdEmpty, doubleInhale

    var label: String {
        switch self {
        case .inhale: "Breathe In"
        case .holdFull: "Hold"
        case .exhale: "Breathe Out"
        case .holdEmpty: "Hold"
        case .doubleInhale: "Breathe In, In"
        }
    }
}

struct WatchBreathingPhase: Equatable {
    let type: WatchPhaseType
    let duration: TimeInterval
}

struct WatchBreathingExercise: Identifiable, Hashable {
    /// Stable, hand-assigned id (not a UUID) so the selected pattern survives across
    /// launches via a plain UserDefaults string - see WatchContentView.
    let id: String
    let name: String
    let phases: [WatchBreathingPhase]

    static func == (lhs: WatchBreathingExercise, rhs: WatchBreathingExercise) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Human-readable pattern string (e.g. "4-4-4-4"), matching the phone app's format.
    var patternString: String {
        phases.map { String(Int($0.duration)) }.joined(separator: "-")
    }

    static let boxBreathing = WatchBreathingExercise(
        id: "boxBreathing",
        name: "Box Breathing",
        phases: [
            WatchBreathingPhase(type: .inhale, duration: 4),
            WatchBreathingPhase(type: .holdFull, duration: 4),
            WatchBreathingPhase(type: .exhale, duration: 4),
            WatchBreathingPhase(type: .holdEmpty, duration: 4)
        ]
    )

    static let fourSevenEight = WatchBreathingExercise(
        id: "fourSevenEight",
        name: "4-7-8 Breathing",
        phases: [
            WatchBreathingPhase(type: .inhale, duration: 4),
            WatchBreathingPhase(type: .holdFull, duration: 7),
            WatchBreathingPhase(type: .exhale, duration: 8)
        ]
    )

    static let physiologicalSigh = WatchBreathingExercise(
        id: "physiologicalSigh",
        name: "Physiological Sigh",
        phases: [
            WatchBreathingPhase(type: .doubleInhale, duration: 2),
            WatchBreathingPhase(type: .exhale, duration: 8)
        ]
    )

    static let library = [boxBreathing, fourSevenEight, physiologicalSigh]
}
