# Breathe - Haptic-First Breathing App

A minimalist iOS breathing guidance app that uses the iPhone's Taptic Engine as the primary interface. The screen stays nearly dark while haptics guide you through breathing exercises.

## Features

- **Haptic-First Design**: Sophisticated haptic patterns for each breathing phase
- **Three Pre-loaded Exercises**:
  - Box Breathing (4-4-4-4)
  - 4-7-8 Breathing
  - Physiological Sigh (double inhale + long exhale)
- **Minimal Visual Design**: Near-black background with animated radial glow
- **Background Sessions**: Haptics continue when screen is locked
- **Session History**: Track completed sessions with SwiftData
- **Customizable Settings**: Duration, exercise, haptic intensity

## Project Structure

Files live flat inside `Breath/`, grouped by a naming prefix (Xcode's folder-sync group, so there's nothing to organize manually):

```
Breath/
├── BreathApp.swift                 # App entry point (launches HomeView)
│
├── Models*.swift
│   ├── ModelsBreathingExercise.swift  # Exercise definitions and library
│   ├── ModelsAppSettings.swift        # App-wide settings (@Observable)
│   └── ModelsSessionHistory.swift     # SwiftData model for history
├── BreathingPhase.swift            # Phase types and properties
│
├── Engine*.swift
│   ├── EngineHapticEngine.swift        # Core Haptics implementation
│   ├── EngineBackgroundAudioManager.swift  # Silent audio for background haptics
│   └── EngineSessionEngine.swift       # Session timing and coordination
│
├── Views*.swift
│   ├── ViewsHomeView.swift             # Main screen with Start button
│   ├── ViewsSessionView.swift          # Active session screen
│   ├── ViewsBreathingGlowView.swift    # Animated radial glow
│   ├── ViewsExerciseLibraryView.swift  # Exercise picker
│   ├── ViewsSessionCompleteView.swift  # Post-session summary
│   ├── ViewsHistoryView.swift          # Session history list
│   └── ViewsSettingsView.swift         # App settings
│
├── ColorExtension.swift            # Hex color support
├── FontExtension.swift             # Custom font helpers (Cormorant Garamond, Inter, JetBrains Mono)
└── *.ttf                           # Bundled font files (registered in Info.plist)
```

See [`docs/NAVIGATION.md`](docs/NAVIGATION.md) for screen flow and [`docs/FILES.md`](docs/FILES.md) for the full file list.

## Setup Instructions

### 1. Required Capabilities

You **must** add the following capability in Xcode for background haptics to work:

1. Select your project in the Xcode navigator
2. Select your app target
3. Go to the **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **"Background Modes"**
6. Check **"Audio, AirPlay, and Picture in Picture"**

⚠️ Without this, haptics will stop when the screen locks.

### 2. Device Requirements

- **iOS 17.0+** (for SwiftData and @Observable)
- **Physical iPhone** (Simulator doesn't support haptics)
- Haptics are not supported on iPad

### 3. Privacy Considerations

The app doesn't require any privacy permissions. It:
- Does not access user data beyond local settings
- Does not use HealthKit (yet)
- Does not send any data externally
- Uses only on-device features

## Implementation Notes

### Haptic Patterns

Each breathing phase has a distinct haptic pattern:

- **Inhale**: Continuous haptic with intensity ramping from 0.2 → 1.0
- **Hold (full)**: Gentle pulses every 1.5s at 0.5 intensity
- **Exhale**: Continuous haptic fading from 1.0 → 0.2
- **Hold (empty)**: Single soft tap at start, then silence
- **Double Inhale**: Two sharp taps followed by a gentle ramp
- **Phase Transitions**: Short, crisp marker tap (0.8 intensity, 0.7 sharpness)

All patterns are created using `CHHapticEngine` with parameter curves for smooth transitions, scheduled once up front against Core Haptics' own hardware clock so timing stays accurate through a lock/background period.

### Background Audio Strategy

To keep haptics running when the screen locks, we:

1. Generate a 1-second silent audio file (44.1kHz, mono, 16-bit)
2. Loop it continuously with `AVAudioPlayer`
3. Use `.playback` category with `.mixWithOthers` option
4. Set volume to 0.0 (completely silent)

This is a standard technique for background haptics on iOS.

### Session Screen Design

The session screen is intentionally minimal:

- **Background**: Near-black (#080808)
- **Core dot**: 6px white circle (fixed position)
- **Halos**: 5 layers of radial gradients with varying opacity
- **Animation**: Scale and opacity changes matching phase duration
- **Cycle counter**: Ghost text at bottom (15% opacity)
- **Long press**: 1.5s anywhere on screen to exit (invisible)

### SwiftData Storage

Session history is stored locally using SwiftData:

```swift
@Model
final class SessionHistory {
    var id: UUID
    var exerciseName: String
    var duration: TimeInterval
    var completedAt: Date
    var cyclesCompleted: Int
}
```

No cloud sync is configured by default.

## Testing

### Testing Haptics

1. Build and run on a **physical device** (haptics don't work in Simulator)
2. Go to Exercise Library from Home screen ("Change exercise")
3. Tap "Preview haptics" on any exercise
4. You should feel the haptic patterns for 10 seconds

### Testing Background Sessions

1. Start a breathing session
2. Lock your device with the power button
3. Haptics should continue if Background Modes is enabled
4. Unlock to see the visual animation still in sync

### Testing Long Press to Exit

1. Start a session
2. Touch and hold anywhere on screen for 1.5 seconds
3. A faint ripple should appear before dismissing
4. Partial sessions > 10 seconds are saved to history

## Customization

### Adding New Exercises

Edit `ModelsBreathingExercise.swift`:

```swift
static let customExercise = BreathingExercise(
    name: "Custom Pattern",
    description: "Your description here",
    phases: [
        BreathingPhase(type: .inhale, duration: 3),
        BreathingPhase(type: .exhale, duration: 6)
    ]
)
```

Then add to the library array:

```swift
static let library: [BreathingExercise] = [
    .boxBreathing,
    .fourSevenEight,
    .physiologicalSigh,
    .customExercise  // Add here
]
```

### Adjusting Haptic Intensity

Users can adjust intensity in Settings (0.5x, 1.0x, 1.5x), but you can also modify the base patterns in `EngineHapticEngine.swift` if needed.

### Changing Animation Timing

The glow animation durations are currently hardcoded in `ViewsBreathingGlowView.swift`. To make them dynamic, pass the actual phase duration from `SessionView`.

## Known Limitations

1. **Simulator**: Haptics don't work—must test on device
2. **iPad**: No Taptic Engine support
3. **Animation Sync**: Glow animations use approximate durations; could be more precise
4. **Long Press Feedback**: Very subtle; could be more obvious for first-time users
5. **No Onboarding**: Users need to discover the long-press gesture

## Future Enhancements

Potential additions (not implemented):

- [ ] HealthKit integration (Mindful Minutes)
- [ ] Live Activities for Lock Screen
- [ ] Dynamic Island support
- [ ] Action Button configuration (iPhone 15 Pro)
- [ ] Custom exercise creator
- [ ] iCloud sync for history
- [ ] Streaks and statistics
- [ ] Guided onboarding
- [ ] Accessibility improvements (VoiceOver support)
- [ ] Apple Watch companion app

## Architecture Decisions

### Why @Observable instead of ObservableObject?

The project uses Swift's `@Observable` macro (iOS 17+) for simpler state management and better performance. It eliminates the need for `@Published` wrappers and provides automatic dependency tracking.

### Why 60 FPS Timer?

The session engine runs at 60 FPS (`1.0 / 60.0` interval) for smooth visual animations. This is overkill for haptics alone, but necessary for the breathing glow animation.

### Why Not Combine?

We use Timer instead of Combine publishers for simplicity. The timing requirements are straightforward and don't benefit from reactive streams.

## Troubleshooting

### Haptics Not Working

1. **Check Device**: Haptics only work on physical iPhones
2. **Check Settings**: System Settings > Sounds & Haptics > System Haptics must be ON
3. **Check Ring/Silent Switch**: Haptics work in both modes, but system settings may vary

### Background Haptics Stop

1. **Check Capability**: Ensure Background Modes capability is added
2. **Check Settings**: Background Audio toggle must be ON in app
3. **Check Audio Category**: Should see "Audio session configured" in console

### Build Errors

1. **"Cannot find type"**: Ensure all files have target membership (folder-sync group should handle this automatically)
2. **SwiftData errors**: Requires iOS 17.0+ deployment target
3. **@Observable errors**: Requires iOS 17.0+ and Swift 5.9+

## License

This is a reference implementation. Adapt and use as needed.

---

**Built with**: Swift, SwiftUI, Core Haptics, AVFoundation, SwiftData
**Platform**: iOS 17.0+
