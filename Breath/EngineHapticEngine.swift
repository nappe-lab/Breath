//
//  HapticEngine.swift
//  Breath
//

import AVFoundation
import CoreHaptics

/// Manages Core Haptics patterns for breathing phases
@Observable
class HapticEngine {
    private var engine: CHHapticEngine?
    private var currentPlayer: CHHapticAdvancedPatternPlayer?
    private var sessionPlayer: CHHapticAdvancedPatternPlayer?
    var intensityMultiplier: Double

    // Remembered so a mid-session engine restart (e.g. after an audio interruption) can
    // re-schedule whatever haptics are still left, instead of leaving the engine running
    // but silent for the rest of the session. See resumeSessionIfPossible().
    private var sessionExercise: BreathingExercise?
    private var sessionTargetDuration: TimeInterval?
    private var sessionStartDate: Date?

    private var interruptionObserver: NSObjectProtocol?

    init(intensityMultiplier: Double = 1.0) {
        self.intensityMultiplier = intensityMultiplier
        prepareHaptics()
    }

    deinit {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
    }

    // MARK: - Setup

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("⚠️ Device does not support haptics")
            return
        }

        do {
            engine = try CHHapticEngine()

            // By default iOS is free to shut the engine down as soon as the app resigns
            // active (e.g. the instant the screen locks). Disabling auto-shutdown lets it
            // keep running as long as the app has an active background audio session.
            engine?.isAutoShutdownEnabled = false

            try engine?.start()

            // A full reset (engine + all players invalidated) - safe to restart immediately.
            engine?.resetHandler = { [weak self] in
                print("🔄 Haptic engine reset")
                self?.startEngine()
            }

            // The engine stopped. If it's because the audio session was interrupted (this is
            // what actually happens when the screen locks), restarting *right now* reliably
            // fails with CoreHaptics -4808 "Startup timeout" - the session isn't valid again
            // yet. Instead we wait for the AVAudioSession interruption-ended notification
            // below, which is the real signal that it's safe to restart. For any other stop
            // reason (idle timeout, system error, etc.) restarting immediately is fine.
            engine?.stoppedHandler = { [weak self] reason in
                print("⏹️ Haptic engine stopped: \(reason)")
                guard reason.rawValue != CHHapticEngine.StoppedReason.audioSessionInterrupt.rawValue else { return }
                self?.startEngine()
            }

            // Restart once the interruption (e.g. the lock/unlock transition) has actually
            // ended - this is the reliable moment to call engine.start() again.
            interruptionObserver = NotificationCenter.default.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.handleAudioSessionInterruption(notification)
            }

            print("✅ Haptic engine initialized")
        } catch {
            print("❌ Failed to create haptic engine: \(error)")
        }
    }

    private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: typeValue) == .ended else { return }

        print("🔊 Audio interruption ended - restarting haptic engine")
        startEngine()
    }

    private func startEngine() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            try engine?.start()
            resumeSessionIfPossible()
        } catch {
            print("❌ Failed to restart haptic engine: \(error)")
        }
    }

    // MARK: - Full Session Playback (survives being locked/backgrounded)
    //
    // Core Haptics can keep an *already-scheduled* pattern playing across a lock/background
    // transition, but it cannot reliably create new players or restart the engine once the
    // app is actually backgrounded — attempts made at that point fail with CoreHaptics
    // -4805 ("self.running"), -4808 ("Startup timeout"), or 2003329396 ("what" /
    // AVAudioSessionErrorCodeUnspecified). So instead of re-triggering a fresh player on every
    // phase change from a repeating timer, the entire session's haptics are laid out as ONE
    // pattern up front and started exactly once, while the app is still in the foreground.
    //
    // If the engine does still get stopped mid-session (e.g. a real audio interruption),
    // restarting the engine alone does not resurrect the original player's remaining
    // schedule, so resumeSessionIfPossible() rebuilds and reschedules whatever is left.

    /// Build and start a single pattern covering every phase + transition marker for the
    /// whole session, from now until `targetDuration`.
    func startSession(exercise: BreathingExercise, targetDuration: TimeInterval) {
        stopSession()

        sessionExercise = exercise
        sessionTargetDuration = targetDuration
        sessionStartDate = Date()

        schedulePlayer(resumingAt: 0)
    }

    /// Stop the whole-session pattern (called when the user ends the session, which always
    /// happens in the foreground since they have to unlock to tap "end session").
    func stopSession() {
        if let player = sessionPlayer {
            do {
                try player.stop(atTime: CHHapticTimeImmediate)
            } catch {
                print("❌ Failed to stop session haptics: \(error)")
            }
        }
        sessionPlayer = nil
        sessionExercise = nil
        sessionTargetDuration = nil
        sessionStartDate = nil
    }

    /// Re-schedule whatever haptics are still left in the session, from wherever we currently
    /// are in wall-clock time. Called after any successful engine restart.
    private func resumeSessionIfPossible() {
        guard let startDate = sessionStartDate,
              let targetDuration = sessionTargetDuration else { return }

        let elapsed = Date().timeIntervalSince(startDate)
        guard elapsed < targetDuration else { return } // session already finished naturally

        print("🔁 Resuming session haptics from \(Int(elapsed))s")
        schedulePlayer(resumingAt: elapsed)
    }

    private func schedulePlayer(resumingAt offset: TimeInterval) {
        guard let exercise = sessionExercise, let targetDuration = sessionTargetDuration else { return }

        do {
            let result = sessionEvents(exercise: exercise, targetDuration: targetDuration, resumingAt: offset)
            guard !result.events.isEmpty else { return }
            let pattern = try CHHapticPattern(events: result.events, parameterCurves: result.curves)
            let player = try engine?.makeAdvancedPlayer(with: pattern)
            sessionPlayer = player
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("❌ Failed to \(offset == 0 ? "start" : "resume") session haptics: \(error)")
        }
    }

    /// Lay out every phase + transition marker for the whole session. When resuming partway
    /// through (`resumingAt` > 0), phases that already fully finished are dropped, and the
    /// phase we're currently inside restarts cleanly from its own beginning rather than trying
    /// to splice into the middle of a ramp/pulse pattern.
    private func sessionEvents(exercise: BreathingExercise, targetDuration: TimeInterval, resumingAt resumeOffset: TimeInterval = 0) -> (events: [CHHapticEvent], curves: [CHHapticParameterCurve]) {
        var events: [CHHapticEvent] = []
        var curves: [CHHapticParameterCurve] = []
        var cursor: TimeInterval = 0

        guard !exercise.phases.isEmpty else { return (events, curves) }

        while cursor < targetDuration {
            for phase in exercise.phases {
                guard cursor < targetDuration else { return (events, curves) }

                let remaining = targetDuration - cursor
                let phaseDuration = min(phase.duration, remaining)

                if cursor + phaseDuration > resumeOffset {
                    let localStart = max(cursor, resumeOffset) - resumeOffset
                    events.append(transitionMarkerEvent(at: localStart))
                    // The marker above claims the first 0.1s of the phase, so the phase's own
                    // content has to be shortened by the same amount - otherwise it runs right
                    // up against (and overlaps) the *next* phase's transition marker, garbling
                    // the handoff (e.g. inhale's ramp still climbing to its peak while the next
                    // marker tap fires on top of it).
                    let contentDuration = max(0, phaseDuration - 0.1)
                    let phaseResult = phaseEvents(for: phase.type, duration: contentDuration, startTime: localStart + 0.1)
                    events.append(contentsOf: phaseResult.events)
                    curves.append(contentsOf: phaseResult.curves)
                }

                cursor += phase.duration
            }
        }

        return (events, curves)
    }

    // MARK: - Single-shot Playback (foreground-only preview, e.g. exercise library tap test)

    /// Play haptic pattern for a breathing phase
    func playPhaseHaptic(phase: PhaseType, duration: TimeInterval) {
        stopCurrentHaptic()

        do {
            let result = phaseEvents(for: phase, duration: duration, startTime: 0)
            let pattern = try CHHapticPattern(events: result.events, parameterCurves: result.curves)
            let player = try engine?.makeAdvancedPlayer(with: pattern)
            currentPlayer = player
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("❌ Failed to play haptic for \(phase): \(error)")
        }
    }

    /// Stop any currently playing single-shot haptic
    func stopCurrentHaptic() {
        guard let player = currentPlayer else { return }
        do {
            try player.stop(atTime: CHHapticTimeImmediate)
        } catch {
            print("❌ Failed to stop haptic: \(error)")
        }
        currentPlayer = nil
    }

    // MARK: - Pattern Creation

    /// hapticIntensity is only valid in 0...1 - the intensityMultiplier (e.g. 3.0× for
    /// "Strong") is deliberately allowed to push the raw value past 1.0 so quieter events
    /// saturate at the hardware's true max instead of the boost going to waste; clamp here
    /// rather than relying on CHHapticEventParameter to do it implicitly.
    private func clampedIntensity(_ value: Double) -> Float {
        Float(min(1.0, max(0.0, value)))
    }

    private func transitionMarkerEvent(at startTime: TimeInterval) -> CHHapticEvent {
        // Short, crisp tap to mark transitions
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: clampedIntensity(0.8 * intensityMultiplier))
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)

        return CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensity, sharpness],
            relativeTime: startTime,
            duration: 0.1
        )
    }

    private func phaseEvents(for phase: PhaseType, duration: TimeInterval, startTime: TimeInterval) -> (events: [CHHapticEvent], curves: [CHHapticParameterCurve]) {
        switch phase {
        case .inhale:
            // Intensity builds clearly from 0.2 to 1.0 across the whole inhale
            return createRampPattern(
                from: 0.2 * intensityMultiplier,
                to: 1.0 * intensityMultiplier,
                duration: duration,
                sharpness: 0.3,
                startTime: startTime
            )

        case .holdFull:
            // Steady pulse every 1.5s
            let events = createPulsePattern(
                intensity: 0.5 * intensityMultiplier,
                sharpness: 0.2,
                interval: 1.5,
                duration: duration,
                startTime: startTime
            )
            return (events, [])

        case .exhale:
            // Intensity fades clearly from 1.0 to 0.2 across the whole exhale
            return createRampPattern(
                from: 1.0 * intensityMultiplier,
                to: 0.2 * intensityMultiplier,
                duration: duration,
                sharpness: 0.3,
                startTime: startTime
            )

        case .holdEmpty:
            // Steady pulse every 1.5s, same intensity and cadence as the full hold
            let events = createPulsePattern(
                intensity: 0.5 * intensityMultiplier,
                sharpness: 0.2,
                interval: 1.5,
                duration: duration,
                startTime: startTime
            )
            return (events, [])

        case .doubleInhale:
            // Two sharp taps followed by a ramp
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: clampedIntensity(0.7 * intensityMultiplier))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)

            var events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: startTime),
                CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: startTime + 0.5)
            ]

            // Add ramp after the two taps
            let ramp = createRampPattern(
                from: 0.3 * intensityMultiplier,
                to: 1.0 * intensityMultiplier,
                duration: duration - 0.5,
                sharpness: 0.3,
                startTime: startTime + 0.5
            )
            events.append(contentsOf: ramp.events)
            return (events, ramp.curves)
        }
    }

    /// Create a continuous event whose intensity actually ramps between `startIntensity` and
    /// `endIntensity` over `duration`, via a CHHapticParameterCurve. A plain CHHapticEvent's
    /// parameters are fixed for the whole event, so without a curve the "ramp" would just sit
    /// at a constant `startIntensity` the entire time - a curve is required for a real build/fade.
    private func createRampPattern(from startIntensity: Double, to endIntensity: Double, duration: TimeInterval, sharpness: Float, startTime: TimeInterval) -> (events: [CHHapticEvent], curves: [CHHapticParameterCurve]) {
        guard duration > 0 else { return ([], []) }

        let startValue = clampedIntensity(startIntensity)
        let endValue = clampedIntensity(endIntensity)

        // hapticIntensityControl curve values below scale (multiply) against this event's
        // own hapticIntensity rather than replacing it. Authoring the base at a neutral 1.0
        // means the curve's control points are the actual felt intensity at each instant; if
        // this were authored at startValue instead, the whole ramp would be scaled down by
        // it (e.g. inhale's 0.2 base would keep the curve's 1.0 endpoint from ever feeling
        // stronger than 0.2 - exactly why inhale wasn't reaching exhale's starting level).
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)

        let continuousEvent = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: startTime,
            duration: duration
        )

        let curve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: startValue),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: endValue)
            ],
            relativeTime: startTime
        )

        return ([continuousEvent], [curve])
    }

    /// Create a repeating pulse pattern
    private func createPulsePattern(intensity: Double, sharpness: Float, interval: TimeInterval, duration: TimeInterval, startTime: TimeInterval) -> [CHHapticEvent] {
        var events: [CHHapticEvent] = []
        var elapsed: TimeInterval = 0

        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: clampedIntensity(intensity))
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)

        while elapsed < duration {
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensityParam, sharpnessParam],
                relativeTime: startTime + elapsed
            ))
            elapsed += interval
        }

        return events
    }
}
