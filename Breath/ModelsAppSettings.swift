//
//  AppSettings.swift
//  Breath
//

import Foundation
import SwiftUI

/// Centralized app settings using @AppStorage
@Observable
class AppSettings {
    var defaultExercise: BreathingExercise {
        didSet {
            UserDefaults.standard.set(defaultExercise.id.uuidString, forKey: "defaultExerciseID")
        }
    }

    @ObservationIgnored
    @AppStorage("defaultDurationMinutes") var defaultDurationMinutes: Int = 5

    @ObservationIgnored
    @AppStorage("hapticIntensityMultiplier") var hapticIntensityMultiplier: Double = 1.0

    @ObservationIgnored
    @AppStorage("backgroundAudioEnabled") var backgroundAudioEnabled: Bool = true

    init() {
        if let idString = UserDefaults.standard.string(forKey: "defaultExerciseID"),
           let uuid = UUID(uuidString: idString),
           let exercise = BreathingExercise.library.first(where: { $0.id == uuid }) {
            defaultExercise = exercise
        } else {
            defaultExercise = .boxBreathing
        }
    }
    
    /// Available duration options in minutes
    static let durationOptions = [3, 5, 10, 20]
    
    /// Available haptic intensity multipliers
    static let intensityOptions: [Double] = [0.5, 1.0, 3.0]

    /// Human-readable label for intensity values
    func intensityLabel(for value: Double) -> String {
        if value == 0.5 {
            return "0.5× (Gentle)"
        } else if value == 1.0 {
            return "1.0× (Normal)"
        } else {
            return "3.0× (Strong)"
        }
    }
}
