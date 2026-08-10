# Breathe App - Navigation & Flow

## App Structure

```
┌─────────────────────────────────────────┐
│         BreathApp (@main)               │
│    SwiftData ModelContainer setup       │
└─────────────┬───────────────────────────┘
              │
              ▼
        ┌──────────┐
        │ HomeView │  (NavigationStack root)
        └────┬─────┘
             │
   ┌─────────┼─────────────┬─────────────────┐
   │ Start   │ Change       │ Menu (⋯)         │
   ▼         │ exercise ▼   ▼ History  ▼ Settings
┌──────────┐ │      ┌──────────┐  ┌──────────┐ ┌──────────┐
│ Session  │ │      │ Exercise │  │ History  │ │ Settings │
│  View    │ │      │ Library  │  │   View   │ │   View   │
└────┬─────┘ │      │ (sheet)  │  └──────────┘ └──────────┘
     │       └──────┴──────────┘
     ▼
┌──────────┐
│ Complete │
│  View    │
└──────────┘
```

`HomeView` is the single navigation root shown by `BreathApp`. `SessionView` and `HistoryView`/`SettingsView` are pushed via `navigationDestination`; `ExerciseLibraryView` is presented as a sheet; `SessionCompleteView` is presented as a sheet from within `SessionView`.

## Screen Flow Details

### 1. Home Screen (HomeView)
**Purpose**: Starting point for breathing sessions

**Elements**:
- Exercise name and duration
- Pattern preview (e.g., "4-4-4-4")
- Large circular "Start" button
- "Change exercise" link
- Overflow menu (⋯, top right) with History and Settings

**Navigation**:
- Tap "Start" → `SessionView` (navigation push)
- Tap "Change exercise" → `ExerciseLibraryView` (sheet)
- Tap ⋯ → History → `HistoryView` (navigation push)
- Tap ⋯ → Settings → `SettingsView` (navigation push)

---

### 2. Session Screen (SessionView)
**Purpose**: Active breathing session with haptics

**Elements**:
- Near-black background (#080808)
- Animated radial glow (center)
- Cycle counter (bottom, 15% opacity)
- Invisible long-press gesture (1.5s)

**Visual Behavior**:
- Inhale: glow expands and brightens
- Hold: glow stays stable
- Exhale: glow contracts and dims
- Transitions: smooth ease-in-out matching phase duration

**Haptic Behavior**:
- Inhale: continuous ramp (0.2 → 1.0 intensity)
- Hold (full): pulses every 1.5s
- Exhale: continuous fade (1.0 → 0.2)
- Hold (empty): single soft tap
- All transitions: sharp marker tap

**Exit**:
- Long press 1.5s → Shows faint ripple → Dismisses
- Or: Session completes → `SessionCompleteView` (sheet)

**State**:
- `SessionEngine` manages timing
- `HapticEngine` plays patterns
- `BackgroundAudioManager` keeps alive when locked

---

### 3. Exercise Library (ExerciseLibraryView)
**Purpose**: Choose breathing exercise

**Elements**:
- List of 3 exercises:
  1. Box Breathing (4-4-4-4)
  2. 4-7-8 Breathing (4-7-8)
  3. Physiological Sigh (2-8)
- Each row shows:
  - Name and pattern
  - Description
  - "Preview haptics" button (10s preview)
  - Checkmark if selected

**Interaction**:
- Tap row → Selects exercise → Auto-dismiss
- Tap "Preview haptics" → Plays pattern for 10s
- Tap "Done" → Dismiss without change

---

### 4. Session Complete (SessionCompleteView)
**Purpose**: Show session results

**Elements**:
- Checkmark icon
- "Session Complete" title
- Exercise name
- Duration (e.g., "5m 23s")
- Cycles completed
- Two buttons:
  - "Start Again" → Restarts with same exercise
  - "Done" → Returns to Home

**Behavior**:
- Session auto-saved to SwiftData
- Can't dismiss by swipe (interactiveDismissDisabled)
- Must tap a button

---

### 5. History Screen (HistoryView)
**Purpose**: View past sessions

**Elements**:
- List of completed sessions (reverse chronological)
- Each row shows:
  - Exercise name
  - Date and time
  - Duration
  - Cycles completed
- Empty state: "No sessions yet" with icon

**Data**:
- SwiftData `@Query`
- Sorted by `completedAt` descending
- No deletion or editing yet

---

### 6. Settings Screen (SettingsView)
**Purpose**: Configure app defaults

**Sections**:

1. **Default Exercise**
   - Picker: Box / 4-7-8 / Physiological Sigh

2. **Default Duration**
   - Segmented picker: 3 / 5 / 10 / 20 minutes

3. **Haptic Intensity**
   - Segmented picker: 0.5× / 1.0× / 1.5×
   - Footer: Explanation

4. **Background Audio**
   - Toggle: ON/OFF
   - Footer: "Keeps haptics running when screen is locked"

**Persistence**:
- All settings saved to UserDefaults
- Wrapped in `@Observable` `AppSettings`

---

## State Management

### Global State (AppSettings)
- `@Observable` class
- Shared across HomeView, SettingsView
- Persists to UserDefaults

### Session State (SessionEngine)
- `@Observable` class
- Created per-session
- Owns HapticEngine instance
- Runs Timer at 60 FPS
- Publishes: phase, progress, cycle count

### History State (SwiftData)
- `@Query` in HistoryView
- `@Environment(\.modelContext)` for insertion
- SessionHistory model with @Model macro

---

## Data Flow

```
User Action
    │
    ▼
┌──────────────┐
│   HomeView   │ (reads AppSettings)
└──────┬───────┘
       │ Tap "Start"
       ▼
┌──────────────┐
│ SessionView  │ (creates SessionEngine)
└──────┬───────┘
       │
       ├─────────▶ SessionEngine ──▶ HapticEngine ──▶ Core Haptics
       │                    │
       │                    └─────▶ BackgroundAudioManager
       │
       │ On complete
       ▼
┌──────────────┐
│ modelContext │ (SwiftData)
│   .insert()  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ HistoryView  │ (queries SessionHistory)
└──────────────┘
```

---

## Key Interactions

### Starting a Session
1. User taps "Start" in HomeView
2. HomeView reads settings (exercise, duration, intensity)
3. NavigationStack pushes SessionView
4. SessionView creates SessionEngine
5. SessionEngine creates HapticEngine with intensity
6. SessionEngine.start() begins:
   - Starts background audio (if enabled)
   - Plays transition marker
   - Starts first phase haptic
   - Starts 60 FPS timer
7. Timer ticks, updating phase/progress
8. View animates glow based on phase

### Completing a Session
1. SessionEngine detects targetDuration reached
2. Calls completeSession()
3. Invokes onSessionComplete callback
4. SessionView receives callback:
   - Creates SessionHistory object
   - Inserts into modelContext
   - Sets showingComplete = true
5. Sheet appears with SessionCompleteView
6. User taps "Done" → Dismisses back to Home
7. HistoryView now shows new session

### Background Behavior
1. User starts session
2. SessionEngine checks backgroundAudioEnabled
3. BackgroundAudioManager.startBackgroundAudio():
   - Configures AVAudioSession (.playback, .mixWithOthers)
   - Generates silent 1s audio file
   - Loops with AVAudioPlayer at 0.0 volume
4. User locks screen
5. App continues in background (audio mode)
6. Haptics continue via Core Haptics
7. User unlocks → Visual animation catches up

---

## Animation Details

### Glow Animation (BreathingGlowView)

**Structure**:
- 5 concentric circles (halos)
- Each with RadialGradient (white → clear)
- Different radii: 20, 40, 70, 110, 160 pts
- Different opacities: 0.8, 0.5, 0.3, 0.15, 0.08
- Blur radius: 0, 3, 6, 9, 12 pts
- Fixed 6pt core dot (no animation)

**Animation States**:
```
Inhale:
  - Scale: 1.0 → 1.5
  - Opacity: 0.6 → 0.8
  - Duration: phase duration (e.g., 4s)
  - Easing: .easeInOut

Hold (full):
  - Scale: stays at 1.5
  - Opacity: 0.7 (stable)
  - Duration: 0.5s (quick settle)

Exhale:
  - Scale: 1.5 → 1.0
  - Opacity: 0.8 → 0.4
  - Duration: phase duration (e.g., 4s)
  - Easing: .easeInOut

Hold (empty):
  - Scale: stays at 1.0
  - Opacity: 0.3 (stable)
  - Duration: 0.5s
```

**Synchronization**:
- onChange(of: phase) triggers animation
- Animation duration matches phase duration
- No discrete steps—smooth transitions only

---

## Performance Considerations

### Timer Frequency
- 60 FPS (1/60s = ~16.67ms)
- Needed for smooth visual animation
- Overkill for haptics (could be 30 FPS)
- Negligible battery impact for short sessions

### Memory
- SessionEngine holds one Timer
- HapticEngine holds CHHapticEngine + one player
- No leaks if weak self used in closures
- SwiftData handles history persistence

### Background Battery
- Silent audio playback: minimal impact
- Core Haptics: very efficient
- Timer in background: normal for audio apps
- 5-20 min sessions: acceptable drain

---

## Edge Cases Handled

1. **Early Exit**: Long press saves partial session if > 10s
2. **App Backgrounding**: Haptics continue, visuals pause
3. **Session Interruption**: Engine stops on view disappear
4. **No Haptics Device**: Engine fails gracefully with logs
5. **System Haptics Disabled**: App still runs, just silent
6. **Multiple Sessions**: Each creates new engine instance

---

## Future Enhancement Ideas

- **Onboarding**: Tutorial for long-press gesture
- **Custom Exercises**: User-defined phase patterns
- **Visual Progress**: Optional progress ring for sighted users
- **Accessibility**: VoiceOver announcements for phases
- **Watch Companion**: Haptics on wrist
- **Dynamic Island**: Live Activity during session
- **HealthKit**: Log as Mindful Minutes
- **Shortcuts**: Siri integration ("Start box breathing")
- **Focus Modes**: Auto-trigger based on focus
- **Streaks**: Gamification for daily practice

---

**End of Navigation & Flow Documentation**
