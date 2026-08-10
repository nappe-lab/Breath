# Breathe App - Complete File List

All files sit flat inside `Breath/`; the naming prefix (`Models`, `Engine`, `Views`) stands in for folders. Xcode's folder-sync group means everything placed in `Breath/` is auto-included in the app target except `Info.plist`, which is wired in via build settings instead.

## Core (2)
- `BreathApp.swift` - App entry point; sets up the SwiftData container and launches `HomeView`
- `Info.plist` - Background Modes (audio) declaration, `UIAppFonts` registration

## Models (4)
- `ModelsBreathingExercise.swift` - Exercise definitions and presets library
- `ModelsAppSettings.swift` - `@Observable` settings store (UserDefaults-backed)
- `ModelsSessionHistory.swift` - SwiftData model for completed sessions
- `BreathingPhase.swift` - Phase types (`PhaseType`) and per-phase duration

## Engine (3)
- `EngineHapticEngine.swift` - Core Haptics pattern generation
- `EngineBackgroundAudioManager.swift` - Silent audio loop to keep the app alive in the background
- `EngineSessionEngine.swift` - Timer-driven session coordinator

## Views (7)
- `ViewsHomeView.swift` - Main screen with Start button; entry point shown by `BreathApp`
- `ViewsSessionView.swift` - Active breathing session screen
- `ViewsBreathingGlowView.swift` - Animated radial glow component
- `ViewsExerciseLibraryView.swift` - Exercise picker with haptic preview
- `ViewsSessionCompleteView.swift` - Post-session summary
- `ViewsHistoryView.swift` - SwiftData-backed session list
- `ViewsSettingsView.swift` - App preferences

## Utilities (2)
- `ColorExtension.swift` - Hex color initialization
- `FontExtension.swift` - Cormorant Garamond / Inter / JetBrains Mono helpers

## Fonts (5, registered in `Info.plist`)
- `CormorantGaramond-Regular.ttf`, `CormorantGaramond-Medium.ttf`
- `Inter-Regular.ttf`, `Inter-Medium.ttf`
- `JetBrainsMono-Regular.ttf`

## Documentation (4, kept outside the Xcode target)
- `README.md` - Implementation guide (repo root)
- `docs/SETUP_CHECKLIST.md` - Step-by-step setup/testing checklist
- `docs/NAVIGATION.md` - Screen flow and data flow
- `docs/FILES.md` - This file

---

## Quick Stats
- Swift files: 16
- Frameworks: SwiftUI, CoreHaptics, AVFoundation, SwiftData
- Min iOS: 17.0
