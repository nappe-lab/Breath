# Setup Checklist for Breathe App

The project uses Xcode's folder-sync group, so files under `Breath/` are picked up automatically — no manual group organization needed. Complete these steps to get the app running:

## ✅ Xcode Configuration

### 1. Deployment Target
- [ ] Set minimum deployment target to **iOS 17.0** or later
  - Project Settings > General > Minimum Deployments

### 2. Background Modes Capability ⚠️ REQUIRED
- [ ] Select your project in Project Navigator
- [ ] Select your app target
- [ ] Go to "Signing & Capabilities" tab
- [ ] Click "+ Capability" button
- [ ] Add "Background Modes"
- [ ] Check "Audio, AirPlay, and Picture in Picture"

### 3. Build Settings (if needed)
- [ ] Ensure Swift Language Version is 5.9 or later
- [ ] Enable "Swift Concurrency" if not already enabled

## ✅ Testing Checklist

### On Physical Device (Required!)
- [ ] Connect a physical iPhone (haptics don't work in Simulator)
- [ ] Build and run the app
- [ ] Test haptic preview in Exercise Library
- [ ] Start a session and feel the haptics
- [ ] Lock device and verify haptics continue
- [ ] Complete a session and check History

### Expected Behavior
- [ ] Home screen shows default exercise and Start button
- [ ] Tapping Start shows session screen with animated glow
- [ ] Haptics change with each breathing phase
- [ ] Sharp marker tap at each phase transition
- [ ] Long press (1.5s) anywhere exits session
- [ ] Completed sessions appear in History (⋯ menu on Home)
- [ ] Settings can change defaults

## ⚠️ Common Issues

### Haptics Not Working
**Problem**: No haptic feedback felt during session
**Solutions**:
- Ensure running on physical device (not Simulator)
- Check System Settings > Sounds & Haptics > System Haptics is ON
- Verify device supports haptics (iPhone 7 or later)

### Background Haptics Stop When Locked
**Problem**: Haptics stop when screen locks
**Solutions**:
- Add Background Modes capability (see step 3 above)
- Ensure "Background Audio" toggle is ON in app Settings
- Check console for "Audio session configured" message

### Build Errors
**Problem**: "Cannot find type" or "Module not found"
**Solutions**:
- Clean build folder (Cmd+Shift+K)
- Ensure all files have correct target membership
- Check deployment target is iOS 17.0+

### SwiftData Errors
**Problem**: SwiftData related errors
**Solutions**:
- Ensure deployment target is iOS 17.0 or later
- Verify @Model macro is available (requires Swift 5.9+)

## 📱 Recommended Test Flow

1. **First Launch**
   - App should open to Home screen
   - Default exercise is "Box Breathing"
   - Default duration is "5 minutes"

2. **Exercise Library**
   - Tap "Change exercise"
   - Preview haptics for each exercise
   - Select a different exercise
   - Return to Home and see it selected

3. **Session Flow**
   - Tap "Start" on Home screen
   - See animated glow appear
   - Feel haptics for each phase:
     * Inhale: gradual ramp up
     * Hold (full): gentle pulses
     * Exhale: gradual fade down
     * Hold (empty): single soft tap
   - Lock device, verify haptics continue
   - Unlock and see animation in sync
   - Long press anywhere to exit

4. **History**
   - Open History from the ⋯ menu on Home
   - See completed session listed
   - Check duration, cycles, timestamp

5. **Settings**
   - Open Settings from Home screen
   - Change default exercise
   - Adjust duration (3/5/10/20 min)
   - Change haptic intensity (0.5x/1x/1.5x)
   - Toggle background audio

## 🎯 Success Criteria

Your app is working correctly when:
- ✅ Haptics feel smooth and match breathing phases
- ✅ Visual animation breathes in sync with haptics
- ✅ Phase transitions have distinct marker taps
- ✅ Haptics continue when screen is locked
- ✅ Sessions save to history
- ✅ Settings persist between launches
- ✅ Long press exits session smoothly

## 📝 Next Steps

After basic functionality works:
1. Test all three exercises thoroughly
2. Test with different intensity multipliers
3. Try different session durations
4. Test edge cases (e.g., exit immediately, very short sessions)
5. Consider adding additional exercises
6. Customize colors/animations to your taste

## 🐛 Debugging Tips

### Console Logging
The app includes helpful console logs:
- `✅ Haptic engine started` - Haptics initialized
- `▶️ Session started` - Session begun
- `✅ Completed cycle N` - Each cycle completion
- `⏹️ Session stopped` - Session ended
- `✅ Session saved to history` - History persisted

### Haptic Issues
Add breakpoints in `EngineHapticEngine.swift`:
- `transitionMarkerEvent(at:)` - Verify called at phase changes
- `playPhaseHaptic()` - Check pattern creation
- `setupEngine()` - Ensure engine initializes

### Background Audio Issues
Check `EngineBackgroundAudioManager.swift`:
- Look for "Audio session configured" log
- Verify silent audio file created in temp directory
- Check `AVAudioSession` category is `.playback`

---

## Questions or Issues?

If you encounter problems not covered here:
1. Check the README.md for detailed implementation notes
2. Review console logs for error messages
3. Ensure all capabilities are properly configured
4. Test on a newer device if haptics seem weak

Happy breathing! 🧘‍♂️
