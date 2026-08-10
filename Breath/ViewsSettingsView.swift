//
//  SettingsView.swift
//  Breath
//

import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Form {
                // Default Exercise
                Section {
                    Picker("Default Exercise", selection: $settings.defaultExercise) {
                        ForEach(BreathingExercise.library) { exercise in
                            Text(exercise.name)
                                .tag(exercise)
                        }
                    }
                } header: {
                    Text("Default Exercise")
                }
                
                // Default Duration
                Section {
                    Picker("Default Duration", selection: $settings.defaultDurationMinutes) {
                        ForEach(AppSettings.durationOptions, id: \.self) { minutes in
                            Text("\(minutes) min")
                                .tag(minutes)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Default Duration")
                }
                
                // Haptic Intensity
                Section {
                    Picker("Haptic Intensity", selection: $settings.hapticIntensityMultiplier) {
                        ForEach(AppSettings.intensityOptions, id: \.self) { intensity in
                            Text(settings.intensityLabel(for: intensity))
                                .tag(intensity)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Haptic Intensity")
                } footer: {
                    Text("Adjust the strength of haptic feedback during sessions")
                }
                
                // Background Audio
                Section {
                    Toggle("Background Audio", isOn: $settings.backgroundAudioEnabled)
                } footer: {
                    Text("Keeps haptics running when the screen is locked. Uses a silent audio loop.")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        SettingsView(settings: AppSettings())
    }
}
