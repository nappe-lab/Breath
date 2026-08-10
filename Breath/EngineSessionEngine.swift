//
//  SessionEngine.swift
//  Breath
//

import Foundation
import UIKit

/// Drives a breathing session tick-by-tick, coordinating haptics and progress
@Observable
class SessionEngine {
    // MARK: - Published State

    var isActive = false
    var currentPhaseIndex = 0
    var elapsedTimeInPhase: TimeInterval = 0
    var totalElapsedTime: TimeInterval = 0
    var currentCycle = 1

    // MARK: - Configuration

    private(set) var exercise: BreathingExercise
    private(set) var targetDuration: TimeInterval // in seconds
    private(set) var targetCycles: Int

    // MARK: - Dependencies

    private let hapticEngine: HapticEngine
    private var timer: Timer?

    // The actual haptic pattern is scheduled once, up front, against Core Haptics' own
    // hardware clock (see HapticEngine.startSession) so it keeps accurate time through a
    // lock/background period regardless of whether our own Timer gets throttled. We derive
    // progress from wall-clock time rather than accumulating per-tick deltas so that this
    // UI-facing state resyncs correctly with the haptics once the app comes back to the
    // foreground, instead of drifting behind by however long the screen was locked.
    private var sessionStartDate: Date?

    // MARK: - Callbacks

    var onSessionComplete: ((TimeInterval, Int) -> Void)?

    // MARK: - Computed Properties

    var currentPhase: BreathingPhase {
        exercise.phases[currentPhaseIndex]
    }

    var progressInPhase: Double {
        guard currentPhase.duration > 0 else { return 0 }
        return min(elapsedTimeInPhase / currentPhase.duration, 1.0)
    }

    // MARK: - Initialization

    init(exercise: BreathingExercise, durationMinutes: Int, hapticEngine: HapticEngine) {
        self.exercise = exercise
        self.hapticEngine = hapticEngine

        // Calculate duration and cycles after all stored properties are initialized
        let duration = TimeInterval(durationMinutes * 60)
        self.targetDuration = duration
        self.targetCycles = Int(ceil(duration / exercise.cycleDuration))
    }

    // MARK: - Session Control

    func start() {
        guard !isActive else { return }

        isActive = true
        currentPhaseIndex = 0
        elapsedTimeInPhase = 0
        totalElapsedTime = 0
        currentCycle = 1
        sessionStartDate = Date()

        // Core Haptics cannot run custom patterns once the app leaves the foreground - no
        // combination of background audio mode / engine settings gets around that. So instead
        // of trying to survive a lock, prevent the automatic (inactivity-based) lock entirely
        // for the duration of the session. Note this can't stop someone from manually pressing
        // the physical side button - that will still lock the screen and pause haptics.
        UIApplication.shared.isIdleTimerDisabled = true

        // Background audio is started by the caller before the haptic engine is even
        // created (see SessionView.setupEngine) — CHHapticEngine must be created after
        // the audio session is already configured for background playback, so starting
        // it here would be too late.

        // Schedule the whole session's haptics as one pattern, right now, while still
        // in the foreground (see HapticEngine.startSession for why).
        hapticEngine.startSession(exercise: exercise, targetDuration: targetDuration)

        // Timer only drives the UI (progress ring, phase label, completion check); it does
        // NOT trigger any haptics. It's fine for this to be throttled/coalesced while locked.
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }

        print("▶️ Session started: \(exercise.name), target: \(targetCycles) cycles")
    }

    func stop() {
        guard isActive else { return }

        isActive = false
        timer?.invalidate()
        timer = nil
        sessionStartDate = nil
        UIApplication.shared.isIdleTimerDisabled = false

        hapticEngine.stopSession()
        BackgroundAudioManager.shared.stopBackgroundAudio()

        print("⏹️ Session stopped at \(totalElapsedTime)s")
    }

    // MARK: - Private Methods

    private func tick() {
        guard let sessionStartDate else { return }
        totalElapsedTime = min(Date().timeIntervalSince(sessionStartDate), targetDuration)

        syncPhaseState()

        if totalElapsedTime >= targetDuration {
            completeSession()
        }
    }

    /// Recompute which phase/cycle we're in from `totalElapsedTime`, so this stays correct
    /// even if the timer missed a stretch of ticks while the app was backgrounded.
    private func syncPhaseState() {
        let cycleDuration = exercise.cycleDuration
        guard cycleDuration > 0 else { return }

        let completedCycles = Int(totalElapsedTime / cycleDuration)
        var remaining = totalElapsedTime - TimeInterval(completedCycles) * cycleDuration

        var phaseIndex = exercise.phases.count - 1
        for (index, phase) in exercise.phases.enumerated() {
            if remaining < phase.duration {
                phaseIndex = index
                break
            }
            remaining -= phase.duration
        }

        let newCycle = completedCycles + 1
        if newCycle != currentCycle {
            currentCycle = newCycle
            print("✅ Completed cycle \(currentCycle - 1)")
        }

        currentPhaseIndex = phaseIndex
        elapsedTimeInPhase = remaining
    }

    private func completeSession() {
        let duration = totalElapsedTime
        let cycles = currentCycle - 1 + (currentPhaseIndex > 0 ? 1 : 0) // Count partial cycles

        stop()

        // Notify completion
        onSessionComplete?(duration, cycles)
    }
}
