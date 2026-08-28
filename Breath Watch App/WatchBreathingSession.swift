//
//  WatchBreathingSession.swift
//  Breath Watch App
//
//  Drives a breathing session for whichever pattern is selected (see
//  WatchBreathingExercise.swift for the pattern library, mirroring the iPhone app's).
//
//  watchOS has no equivalent of iOS's Core Haptics (CHHapticEngine / CHHapticPattern /
//  CHHapticParameterCurve) - there's no continuous-intensity parameter to ramp here. The
//  only API is WKInterfaceDevice.current().play(_:), which fires one of a small, fixed set
//  of pre-authored system haptics (WKHapticType) - see WKHapticType in WKInterfaceDevice.h.
//  An earlier version of this tried to fake extra intensity by stepping each tap through a
//  different WKHapticType (.click -> .start -> .retry -> .notification), but .retry and
//  .notification are multi-pulse "burst" patterns under the hood - mixed in with plain
//  single-pulse .click taps, the ramp read as the *pattern* changing rather than one thing
//  smoothly building, which broke the feel more than it helped. So every phase type below
//  sticks to a single tap type (.click) for its ramp and conveys rise/fall purely through
//  cadence - taps land closer together as they build, farther apart as they fade (the same
//  reason a heartbeat "speeding up" reads as more intense even though each beat is
//  identical). A single directional haptic bookends each ramp as an accent at the phase's
//  most significant instant, and is itself just one clean single-pulse tap, so it doesn't
//  reintroduce the same clash:
//
//    inhale        -> repeated .click taps, gaps SHRINKING throughout, already brisk on the
//                      very first tap (not a slow lead-in) and fastest right at the end. The
//                      last tap (full lungs) is the accent .directionUp.
//    holdFull       -> silent - nothing is changing, so there's nothing to cue.
//    exhale         -> opens on the accent .directionDown (the release from the hold), then
//                      repeated .click taps with gaps GROWING throughout, reading as
//                      intensity fading out as the breath empties.
//    holdEmpty      -> silent, same reasoning as holdFull.
//    doubleInhale   -> two quick .click taps (the "double" in physiological sigh), then the
//                      same shrinking-gap ramp as inhale for whatever time is left in the
//                      phase, ending on the .directionUp accent - mirrors the iPhone app's
//                      "two sharp taps then a ramp" treatment for this phase.
//
//  The ramp's gap sizes are relative weights normalized to each phase's own duration (see
//  `gaps(from:duration:)`), so the same shape - and the same tap count - is reused whether a
//  phase lasts box breathing's 4s or 4-7-8's 8s exhale; only the absolute spacing scales.
//
//  This model is intentionally NOT shared with the iOS target - the phone app's
//  BreathingExercise/PhaseType model drives real Core Haptics curves that don't translate to
//  this API, so duplicating just the phase shape/timing here keeps this target simple and
//  self-contained. If this grows into a real product, pulling shared phase timing into a
//  Swift package both targets depend on would be the natural next step.
//
//  Also worth knowing: this only runs while the app is in the foreground on-screen - a
//  plain Timer doesn't survive the watch going background/wrist-down. Keeping haptics
//  running through that would need a WKExtendedRuntimeSession, which isn't wired up here.

import Foundation
import WatchKit

@Observable
class WatchBreathingSession {
    private(set) var isRunning = false
    private(set) var currentPhase: WatchBreathingPhase
    private(set) var secondsRemaining: Int = 0

    /// The pattern this session runs. Set via `selectExercise(_:)`, not directly - the
    /// setter is a no-op while running, since swapping phases mid-session would leave an
    /// in-flight haptic ramp scheduled against a phase/duration that no longer applies.
    private(set) var exercise: WatchBreathingExercise

    private var phaseIndex = 0
    private var tickTimer: Timer?

    /// Bumped every time a new phase is entered (and on stop) so any in-flight,
    /// self-rescheduling tap chain from a previous phase notices it's stale and
    /// stops recursing instead of bleeding taps into the next phase.
    private var hapticGeneration = 0

    /// Relative gap-size range across a ramp, largest to smallest. Kept fairly close
    /// together (not a huge spread) so the cadence is already brisk on the very first
    /// tap - not a slow lead-in - and simply tightens further from there. Normalized to
    /// each phase's own duration in `gaps(from:duration:)`.
    private static let rampGapWeights: [Double] = {
        let steps = 8 // gaps between 9 taps
        let start = 1.0
        let end = 0.5
        return (0..<steps).map { i in
            start + (end - start) * (Double(i) / Double(steps - 1))
        }
    }()

    init(exercise: WatchBreathingExercise = .boxBreathing) {
        self.exercise = exercise
        self.currentPhase = exercise.phases[0]
    }

    /// No-op while a session is running - see `exercise`'s doc comment.
    func selectExercise(_ exercise: WatchBreathingExercise) {
        guard !isRunning, !exercise.phases.isEmpty else { return }
        self.exercise = exercise
        phaseIndex = 0
        currentPhase = exercise.phases[0]
    }

    func start() {
        guard !isRunning, !exercise.phases.isEmpty else { return }
        isRunning = true
        enter(phaseIndex: 0)
    }

    func stop() {
        isRunning = false
        tickTimer?.invalidate()
        tickTimer = nil
        hapticGeneration += 1
    }

    private func enter(phaseIndex: Int) {
        self.phaseIndex = phaseIndex
        let phase = exercise.phases[phaseIndex]
        currentPhase = phase
        secondsRemaining = Int(phase.duration)

        hapticGeneration += 1
        let generation = hapticGeneration
        playHaptics(for: phase, generation: generation)

        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard isRunning else { return }
        secondsRemaining -= 1
        guard secondsRemaining <= 0 else { return }

        let nextIndex = (phaseIndex + 1) % exercise.phases.count
        enter(phaseIndex: nextIndex)
    }

    // MARK: - Haptics

    private func playHaptics(for phase: WatchBreathingPhase, generation: Int) {
        switch phase.type {
        case .inhale:
            let gaps = Self.gaps(from: Self.rampGapWeights, duration: phase.duration)
            scheduleTap(atIndex: 0, gaps: gaps, accentIndex: gaps.count, accentType: .directionUp, generation: generation)

        case .exhale:
            let gaps = Self.gaps(from: Array(Self.rampGapWeights.reversed()), duration: phase.duration)
            scheduleTap(atIndex: 0, gaps: gaps, accentIndex: 0, accentType: .directionDown, generation: generation)

        case .doubleInhale:
            playDoubleInhale(duration: phase.duration, generation: generation)

        case .holdFull, .holdEmpty:
            break // intentionally silent - see file header
        }
    }

    private func playDoubleInhale(duration: TimeInterval, generation: Int) {
        let tapGap: TimeInterval = 0.35

        WKInterfaceDevice.current().play(.click)
        DispatchQueue.main.asyncAfter(deadline: .now() + tapGap) { [weak self] in
            guard let self, self.isRunning, generation == self.hapticGeneration else { return }
            WKInterfaceDevice.current().play(.click)

            let rampDuration = max(0, duration - tapGap)
            let gaps = Self.gaps(from: Self.rampGapWeights, duration: rampDuration)
            self.scheduleTap(atIndex: 0, gaps: gaps, accentIndex: gaps.count, accentType: .directionUp, generation: generation)
        }
    }

    /// Fires one .click tap at `index` - or, at `accentIndex`, the single directional accent
    /// haptic marking the phase's key instant - then, unless it was the last tap, schedules
    /// the next one after `gaps[index]`. `generation` guards against a phase change (or
    /// stop()) cutting in while a gap is still pending.
    private func scheduleTap(atIndex index: Int, gaps: [TimeInterval], accentIndex: Int, accentType: WKHapticType, generation: Int) {
        guard isRunning, generation == hapticGeneration else { return }

        WKInterfaceDevice.current().play(index == accentIndex ? accentType : .click)

        guard index < gaps.count else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + gaps[index]) { [weak self] in
            self?.scheduleTap(atIndex: index + 1, gaps: gaps, accentIndex: accentIndex, accentType: accentType, generation: generation)
        }
    }

    /// Normalizes relative weights into gap durations that sum to `duration`.
    private static func gaps(from weights: [Double], duration: TimeInterval) -> [TimeInterval] {
        guard duration > 0 else { return [] }
        let total = weights.reduce(0, +)
        return weights.map { $0 / total * duration }
    }
}
