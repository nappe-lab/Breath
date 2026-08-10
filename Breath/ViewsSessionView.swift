//
//  SessionView.swift
//  Breath
//

import SwiftUI
import SwiftData

struct SessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let exercise: BreathingExercise
    let durationMinutes: Int
    let hapticIntensity: Double
    
    @State private var engine: SessionEngine?
    @State private var showingComplete = false
    @State private var completedDuration: TimeInterval = 0
    @State private var completedCycles: Int = 0
    
    // Long press state
    @State private var longPressProgress: Double = 0
    @State private var isLongPressing = false
    
    var body: some View {
        ZStack {
            // Near-black background
            Color(hex: "#080808")
                .ignoresSafeArea()
            
            if let engine = engine {
                // Animated glow
                BreathingGlowView(phase: engine.currentPhase.type)
                
                // Cycle count (ghost text at bottom)
                VStack {
                    Spacer()

                    VStack(spacing: 12) {
                        Text("cycle \(engine.currentCycle) of \(engine.targetCycles)")
                            .font(.jbMono(15))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.45))

                        Button {
                            endSession()
                        } label: {
                            Text("end session")
                                .font(.inter(12))
                                .tracking(1)
                                .foregroundStyle(.white.opacity(0.25))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 60)
                }
                
                // Long-press ripple overlay
                if isLongPressing {
                    Circle()
                        .stroke(.white.opacity(0.3), lineWidth: 2)
                        .scaleEffect(1 + longPressProgress * 0.5)
                        .opacity(1 - longPressProgress)
                        .frame(width: 60, height: 60)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .gesture(
            LongPressGesture(minimumDuration: 1.5)
                .onChanged { _ in
                    isLongPressing = true
                    withAnimation(.linear(duration: 1.5)) {
                        longPressProgress = 1.0
                    }
                }
                .onEnded { _ in
                    // Long press completed - end session
                    endSession()
                }
        )
        .simultaneousGesture(
            // Reset if finger lifts early
            DragGesture(minimumDistance: 0)
                .onEnded { _ in
                    if longPressProgress < 1.0 {
                        isLongPressing = false
                        longPressProgress = 0
                    }
                }
        )
        .onAppear {
            setupEngine()
        }
        .onDisappear {
            engine?.stop()
        }
        .sheet(isPresented: $showingComplete) {
            SessionCompleteView(
                exerciseName: exercise.name,
                duration: completedDuration,
                cycles: completedCycles,
                onStartAgain: {
                    showingComplete = false
                    // Reset and start new session
                    engine?.stop()
                    setupEngine()
                },
                onDone: {
                    dismiss()
                }
            )
        }
    }
    
    private func setupEngine() {
        // Configure + activate the background (silent) audio session BEFORE creating the
        // haptic engine. CHHapticEngine rides on the app's AVAudioSession, so if it's created
        // while the session is still in its default (non-background-capable) state, the engine
        // can't survive backgrounding and any later restart attempt fails with an AVAudioSession
        // error (CoreHaptics error 2003329396 / 'what' — AVAudioSessionErrorCodeUnspecified).
        if AppSettings().backgroundAudioEnabled {
            BackgroundAudioManager.shared.startBackgroundAudio()
        }

        let hapticEngine = HapticEngine(intensityMultiplier: hapticIntensity)
        let sessionEngine = SessionEngine(
            exercise: exercise,
            durationMinutes: durationMinutes,
            hapticEngine: hapticEngine
        )
        
        sessionEngine.onSessionComplete = { duration, cycles in
            completedDuration = duration
            completedCycles = cycles
            
            // Save to history
            saveSession(duration: duration, cycles: cycles)
            
            // Show completion screen
            showingComplete = true
        }
        
        self.engine = sessionEngine
        sessionEngine.start()
    }
    
    private func endSession() {
        guard let engine = engine else { return }
        
        completedDuration = engine.totalElapsedTime
        completedCycles = engine.currentCycle - 1
        
        // Save partial session
        if completedDuration > 10 { // Only save if longer than 10 seconds
            saveSession(duration: completedDuration, cycles: completedCycles)
        }
        
        engine.stop()
        dismiss()
    }
    
    private func saveSession(duration: TimeInterval, cycles: Int) {
        let session = SessionHistory(
            exerciseName: exercise.name,
            duration: duration,
            completedAt: .now,
            cyclesCompleted: cycles
        )
        modelContext.insert(session)
        
        do {
            try modelContext.save()
            print("✅ Session saved to history")
        } catch {
            print("❌ Failed to save session: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        SessionView(
            exercise: .boxBreathing,
            durationMinutes: 5,
            hapticIntensity: 1.0
        )
    }
    .modelContainer(for: SessionHistory.self)
}
