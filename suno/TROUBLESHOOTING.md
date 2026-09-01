# Suno - Troubleshooting Guide

## 🔍 Common Build Issues

### ❌ Error: "Cannot find 'RecordingViewModel' in scope"

**Cause**: File not added to Xcode target

**Solution**:
1. Select the file in Project Navigator
2. Open File Inspector (⌘⌥1)
3. Check "Target Membership" for your app target
4. Clean build folder (⌘⇧K)
5. Rebuild (⌘B)

---

### ❌ Error: "Module 'AVFoundation' has no member 'AVAudioRecorder'"

**Cause**: Wrong import or platform

**Solution**:
1. Ensure `import AVFoundation` is at the top of the file
2. Verify macOS deployment target is 15.0+
3. Make sure it's a macOS target (not iOS)

---

### ❌ Error: "@Observable requires macOS 14.0 or newer"

**Cause**: Deployment target too old

**Solution**:
1. Select project in navigator
2. Select target
3. Go to "Build Settings"
4. Search for "macOS Deployment Target"
5. Set to **macOS 15.0**

---

### ❌ Warning: "Info.plist file not found"

**Cause**: Info.plist not linked to target

**Solution**:
1. Select project in navigator
2. Go to target's "Info" tab
3. Check "Custom macOS Application Target Properties"
4. Or set in Build Settings → "Info.plist File" to `Info.plist`

---

## 🚫 Runtime Issues

### ❌ App doesn't appear anywhere

**Symptoms**: App runs but no icon visible

**Diagnosis**:
1. Check Activity Monitor → "suno" is running
2. App is hidden from Dock (by design)
3. Look for status bar icon in menu bar (near WiFi/battery icons)

**Solution**:
- The app SHOULD only appear in menu bar, not Dock
- If not in menu bar, check AppDelegate initialization
- Restart macOS if menu bar is frozen

---

### ❌ App appears in Dock

**Symptoms**: Dock icon visible (unwanted)

**Solution**:
1. Verify `AppDelegate.swift` has:
   ```swift
   NSApp.setActivationPolicy(.accessory)
   ```
2. Make sure it's called in `applicationDidFinishLaunching`
3. Rebuild and run

---

### ❌ Microphone permission not requested

**Symptoms**: Recording starts but no audio captured

**Diagnosis**:
1. Check Console.app for errors
2. Check System Settings → Privacy → Microphone

**Solution**:
1. Verify `Info.plist` contains:
   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>Suno needs microphone access to record your meetings.</string>
   ```
2. Reset permissions:
   ```bash
   tccutil reset Microphone
   ```
3. Restart app and try again

---

### ❌ Permission denied error when recording

**Symptoms**: Error alert when starting recording

**Solution**:
1. Open **System Settings**
2. Go to **Privacy & Security** → **Microphone**
3. Find "suno" and enable it
4. Restart the app

**Manual Reset**:
```bash
# Reset microphone permissions
tccutil reset Microphone

# Or reset all permissions
tccutil reset All
```

---

### ❌ Recordings not saving

**Symptoms**: Recording completes but doesn't appear in list

**Diagnosis**:
1. Check Console.app for file system errors
2. Verify directory permissions:
   ```bash
   ls -la ~/Library/Application\ Support/suno/
   ```

**Solution**:
1. Ensure app has permission to write to Application Support
2. Check disk space: `df -h`
3. Manually create directory:
   ```bash
   mkdir -p ~/Library/Application\ Support/suno/Recordings
   mkdir -p ~/Library/Application\ Support/suno/Metadata
   ```
4. Restart app

---

### ❌ Popover doesn't open

**Symptoms**: Click menu bar icon, nothing happens

**Solution**:
1. Check Console.app for errors
2. Verify `PopoverContentView.swift` exists and compiles
3. Check AppDelegate popover initialization
4. Try right-click → Quit → restart app

---

### ❌ Menu bar icon not changing color

**Symptoms**: Icon stays gray during recording

**Solution**:
1. Check `MenuBarManager.swift` `updateStatusBarIcon()` method
2. Verify the timer in `AppDelegate` is updating state
3. Add debug prints to confirm state changes

---

## 🐛 Audio Issues

### ❌ No audio captured (empty/silent recordings)

**Diagnosis**:
1. Check microphone in System Settings
2. Test microphone in another app (QuickTime)
3. Check input level in Sound settings

**Solution**:
1. Select correct input device in System Settings → Sound
2. Ensure microphone is not muted
3. Check privacy settings again
4. Try different audio format (WAV instead of M4A)

---

### ❌ Recording playback is distorted

**Symptoms**: Audio sounds wrong when played back

**Solution**:
1. Verify audio settings in `AudioFormat.swift`
2. Check sample rate (should be 44100)
3. Try WAV format instead of M4A
4. Ensure no other app is using the microphone

---

### ❌ Large file sizes for M4A

**Symptoms**: M4A files larger than expected (~1 MB/min)

**Solution**:
1. Verify `AVEncoderAudioQualityKey` is set to `.high` (not `.max`)
2. Check encoding settings in `AudioFormat.swift`
3. M4A should be compressed; if not, check AVFoundation setup

---

## 🔧 Development Issues

### ❌ Xcode preview crashes

**Symptoms**: SwiftUI previews don't work

**Solution**:
1. Comment out `@Environment(RecordingViewModel.self)` in previews
2. Use mock data:
   ```swift
   #Preview {
       RecordingControlsView()
           .environment(RecordingViewModel())
   }
   ```
3. Restart Xcode
4. Clean derived data: `⌘⇧K`

---

### ❌ "Sandbox: rsync deny file-write"

**Symptoms**: Build error about sandbox

**Solution**:
1. Go to **Signing & Capabilities**
2. **Remove** App Sandbox capability
3. We're not distributing via App Store, so sandbox not needed

---

### ❌ Code signing error

**Symptoms**: Can't build due to signing issues

**Solution**:
1. Go to **Signing & Capabilities**
2. Uncheck "Automatically manage signing"
3. Select your team manually
4. Or use local signing (Debug builds only)

---

## 🧪 Testing Issues

### ❌ Can't test on older macOS

**Symptoms**: Need to test on macOS 14 or earlier

**Solution**:
- This app requires macOS 15.0+ for @Observable
- No workaround without rewriting to use ObservableObject
- Consider conditional compilation if needed

---

### ❌ Recordings folder not visible

**Symptoms**: Can't find recordings in Finder

**Solution**:
1. In Finder, press **⌘⇧G**
2. Paste: `~/Library/Application Support/suno/`
3. Press Enter
4. Or use "Show in Finder" button in app

---

### ❌ JSON file corrupted

**Symptoms**: App crashes on launch or recordings don't load

**Solution**:
1. Locate: `~/Library/Application Support/suno/Metadata/recordings.json`
2. Delete the file
3. Restart app (it will create a new one)
4. Recordings files still exist, just need to be re-indexed manually

---

## 💡 Performance Issues

### ❌ High CPU usage while recording

**Symptoms**: Fan spinning, battery drain

**Solution**:
1. Use M4A format (more efficient than WAV)
2. Close unnecessary apps
3. Check for infinite loops in timer code
4. Consider reducing timer frequency in `AudioRecorderService`

---

### ❌ App slow to open popover

**Symptoms**: Delay when clicking menu bar icon

**Solution**:
1. Reduce number of recordings shown (pagination)
2. Lazy load recording list
3. Optimize `RecordingListView` rendering
4. Profile with Instruments (Time Profiler)

---

## 📱 Distribution Issues

### ❌ "App is damaged and can't be opened" on other Macs

**Symptoms**: Works on your Mac but not others

**Solution**:
1. **Code sign** the app properly
2. **Notarize** with Apple:
   ```bash
   xcrun notarytool submit YourApp.dmg \
     --apple-id "your@email.com" \
     --password "app-specific-password" \
     --team-id "YOUR_TEAM_ID"
   ```
3. **Staple** the notarization:
   ```bash
   xcrun stapler staple YourApp.app
   ```

---

### ❌ Gatekeeper blocks app

**Symptoms**: "Cannot open app from unidentified developer"

**Temporary Workaround** (for testing):
```bash
xattr -cr /path/to/YourApp.app
```

**Proper Solution**: Code sign and notarize (see above)

---

## 🆘 Still Having Issues?

### Debug Steps:

1. **Enable Logging**:
   Add debug prints in critical paths:
   ```swift
   print("DEBUG: Recording state changed to \(recordingState)")
   ```

2. **Check Console.app**:
   - Open Console.app
   - Filter for "suno"
   - Look for errors or warnings

3. **Clean Everything**:
   ```bash
   # In Xcode
   Product → Clean Build Folder (⌘⇧K)
   
   # Or delete derived data
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

4. **Restart Xcode**:
   Sometimes Xcode just needs a restart

5. **Restart Mac**:
   Fixes menu bar and permission issues

---

## 📞 Getting Help

### Check These First:
- [ ] README.md for documentation
- [ ] SETUP.md for initial setup
- [ ] Console.app for runtime errors
- [ ] This troubleshooting guide

### Common Error Patterns:

**Build Errors** → Check file targets and imports  
**Permission Errors** → Check Info.plist and System Settings  
**Runtime Crashes** → Check Console.app  
**Missing Features** → Check architecture/implementation

---

## 🔑 Quick Fixes Checklist

When something doesn't work:

```
[ ] Clean build folder (⌘⇧K)
[ ] Rebuild (⌘B)
[ ] Restart Xcode
[ ] Check Console.app
[ ] Verify Info.plist
[ ] Check System Settings → Privacy
[ ] Reset permissions (tccutil reset)
[ ] Restart the app
[ ] Restart macOS
```

---

**Most issues can be solved by:**
1. Cleaning and rebuilding
2. Checking permissions
3. Reading Console.app logs

**Happy debugging!** 🐛🔧
