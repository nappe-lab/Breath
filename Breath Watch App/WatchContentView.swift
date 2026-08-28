//
//  WatchContentView.swift
//  Breath Watch App
//

import SwiftUI

struct WatchContentView: View {
    @State private var session = WatchBreathingSession()

    // Remembers the chosen pattern across launches, like the phone app's
    // AppSettings.defaultExercise (see ModelsAppSettings.swift) - just a plain
    // UserDefaults-backed id here rather than a full settings model.
    @AppStorage("selectedExerciseID") private var selectedExerciseID = WatchBreathingExercise.boxBreathing.id

    // Long-press-to-end state, mirroring the iPhone app's SessionView: ending an
    // active session is a hard-to-reverse action (it discards the in-progress
    // cycle), so it's gated behind a hold instead of a tap target that could be
    // hit by accident on a small screen.
    @State private var longPressProgress: Double = 0
    @State private var isLongPressing = false

    private var selectedExercise: WatchBreathingExercise {
        WatchBreathingExercise.library.first { $0.id == selectedExerciseID } ?? .boxBreathing
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if session.isRunning {
                    runningView
                } else {
                    idleView
                }
            }
        }
        .onAppear {
            session.selectExercise(selectedExercise)
        }
    }

    private var idleView: some View {
        VStack(spacing: 6) {
            NavigationLink {
                WatchPatternPickerView(
                    selection: Binding(
                        get: { selectedExercise },
                        set: { newExercise in
                            selectedExerciseID = newExercise.id
                            session.selectExercise(newExercise)
                        }
                    )
                )
            } label: {
                VStack(spacing: 2) {
                    Text(selectedExercise.name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text(selectedExercise.patternString)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Button("Start") {
                session.start()
            }
        }
        .padding()
    }

    private var runningView: some View {
        ZStack {
            WatchBreathingGlowView(phase: session.currentPhase)

            VStack {
                Text(session.currentPhase.type.label)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                Spacer(minLength: 0)

                Text("hold to end")
                    .font(.system(size: 10))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.25))
            }
            .padding()

            // Long-press ripple overlay, matching the iPhone app's visual feedback
            if isLongPressing {
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 2)
                    .scaleEffect(1 + longPressProgress * 0.5)
                    .opacity(1 - longPressProgress)
                    .frame(width: 40, height: 40)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            LongPressGesture(minimumDuration: 1.5)
                .onChanged { _ in
                    isLongPressing = true
                    withAnimation(.linear(duration: 1.5)) {
                        longPressProgress = 1.0
                    }
                }
                .onEnded { _ in
                    session.stop()
                    isLongPressing = false
                    longPressProgress = 0
                }
        )
        .simultaneousGesture(
            // Reset if the finger lifts early
            DragGesture(minimumDistance: 0)
                .onEnded { _ in
                    if longPressProgress < 1.0 {
                        isLongPressing = false
                        longPressProgress = 0
                    }
                }
        )
    }
}

#Preview {
    WatchContentView()
}
