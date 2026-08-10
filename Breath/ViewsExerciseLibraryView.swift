//
//  ExerciseLibraryView.swift
//  Breath
//

import SwiftUI

struct ExerciseLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var settings: AppSettings

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(BreathingExercise.library) { exercise in
                            ExerciseRow(
                                exercise: exercise,
                                isSelected: exercise == settings.defaultExercise,
                                onSelect: {
                                    settings.defaultExercise = exercise
                                    dismiss()
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.inter(16))
                    .foregroundStyle(.white)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct ExerciseRow: View {
    let exercise: BreathingExercise
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isPreviewingHaptics = false
    @State private var previewEngine: HapticEngine?
    @State private var previewTimer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(.garamond(19, weight: .medium))
                        .foregroundStyle(.white)

                    Text(exercise.patternString)
                        .font(.jbMono(13))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }

            Text(exercise.description)
                .font(.inter(15))
                .foregroundStyle(.white.opacity(0.65))

            HStack {
                Button {
                    if isPreviewingHaptics {
                        stopPreview()
                    } else {
                        startPreview()
                    }
                } label: {
                    Label(
                        isPreviewingHaptics ? "Stop preview" : "Preview haptics",
                        systemImage: isPreviewingHaptics ? "stop.circle" : "hand.tap"
                    )
                    .font(.inter(13))
                    .foregroundStyle(isPreviewingHaptics ? .red : .white.opacity(0.55))
                }

                Spacer()

                if !isSelected {
                    Button("Select") {
                        onSelect()
                    }
                    .font(.inter(13))
                    .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .background(backgroundView)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isSelected {
                onSelect()
            }
        }
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.white.opacity(isSelected ? 0.15 : 0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(isSelected ? 0.3 : 0.1), lineWidth: 1)
            )
    }

    private func startPreview() {
        isPreviewingHaptics = true

        let engine = HapticEngine(intensityMultiplier: 1.0)
        previewEngine = engine

        var phaseIndex = 0
        var elapsedTime: TimeInterval = 0

        func playNextPhase() {
            guard elapsedTime < 10 else {
                stopPreview()
                return
            }

            let phase = exercise.phases[phaseIndex % exercise.phases.count]
            engine.playPhaseHaptic(phase: phase.type, duration: phase.duration)

            elapsedTime += phase.duration
            phaseIndex += 1

            previewTimer = Timer.scheduledTimer(withTimeInterval: phase.duration, repeats: false) { _ in
                playNextPhase()
            }
        }

        playNextPhase()
    }

    private func stopPreview() {
        isPreviewingHaptics = false
        previewTimer?.invalidate()
        previewTimer = nil
        previewEngine?.stopCurrentHaptic()
        previewEngine = nil
    }
}

#Preview {
    ExerciseLibraryView(settings: AppSettings())
}
