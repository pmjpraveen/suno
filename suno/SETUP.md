# Suno - Quick Setup Guide

## ✅ Files Created

### App Structure
- ✅ `sunoApp.swift` (modified)
- ✅ `AppDelegate.swift`
- ✅ `MenuBarManager.swift`

### Models
- ✅ `Recording.swift`
- ✅ `RecordingState.swift`
- ✅ `AudioFormat.swift`

### ViewModels
- ✅ `RecordingViewModel.swift`

### Services
- ✅ `AudioRecorderService.swift`
- ✅ `RecordingStorageService.swift`

### Views
- ✅ `PopoverContentView.swift`
- ✅ `RecordingControlsView.swift`
- ✅ `RecordingListView.swift`
- ✅ `RecordingRowView.swift`

### Configuration
- ✅ `Info.plist`
- ✅ `Extensions.swift`

### Documentation
- ✅ `README.md`

---

## 🚀 Next Steps in Xcode

### 1. Add Files to Xcode Project

If files aren't automatically added:

1. Right-click on your project navigator
2. Select "Add Files to 'suno'..."
3. Select all the new `.swift` files
4. Ensure "Copy items if needed" is checked
5. Ensure the target is selected
6. Click "Add"

### 2. Configure Info.plist

1. Select `Info.plist` in the project navigator
2. Verify it contains `NSMicrophoneUsageDescription`
3. Or manually add in project settings:
   - Go to your target's **Info** tab
   - Add a new key: `Privacy - Microphone Usage Description`
   - Value: `Suno needs microphone access to record your meetings.`

### 3. Configure Build Settings

1. Select your project in the navigator
2. Select the **suno** target
3. Go to **Build Settings** tab
4. Search for "macOS Deployment Target"
5. Set to **macOS 15.0** or higher

### 4. Configure Signing

1. Go to **Signing & Capabilities** tab
2. Enable "Automatically manage signing"
3. Select your Team
4. **Important**: Do NOT enable App Sandbox

### 5. Remove ContentView.swift (Optional)

Since we're using `PopoverContentView.swift` instead:

1. Select `ContentView.swift` in navigator
2. Delete it (Move to Trash)

---

## 🧪 Testing Checklist

### Basic Functionality
- [ ] App launches and appears in menu bar
- [ ] App does NOT appear in Dock
- [ ] Click menu bar icon opens popover
- [ ] Click outside popover closes it
- [ ] Right-click menu bar icon shows "Quit Suno"

### Microphone Permission
- [ ] App requests microphone permission on first recording
- [ ] Permission warning appears if denied
- [ ] Recording works after permission granted

### Recording Flow
- [ ] Start recording button works
- [ ] Duration updates in real-time
- [ ] Menu bar icon turns red and animates during recording
- [ ] Pause button works
- [ ] Menu bar icon turns yellow when paused
- [ ] Resume button works
- [ ] Stop button saves recording
- [ ] Recording appears in list

### Format Selection
- [ ] M4A format can be selected
- [ ] WAV format can be selected
- [ ] Selected format persists across app restarts
- [ ] Files are created with correct extensions

### Recording Management
- [ ] Recordings appear in list sorted by date (newest first)
- [ ] Hover shows action buttons
- [ ] Delete button works (with confirmation)
- [ ] "Show in Finder" works
- [ ] Right-click context menu works
- [ ] File size and duration display correctly

### Edge Cases
- [ ] Rapid start/stop works
- [ ] Long recordings (30+ minutes) work
- [ ] Quitting during recording handles gracefully
- [ ] No recordings shows empty state
- [ ] Multiple recordings can be created

---

## 🐛 Common Issues & Solutions

### Issue: "Cannot find 'PopoverContentView' in scope"

**Solution**: Make sure all files are added to the Xcode target:
1. Select the file in navigator
2. Open File Inspector (⌘⌥1)
3. Check that your target is selected under "Target Membership"

### Issue: App appears in Dock

**Solution**: Verify `AppDelegate.swift` has:
```swift
NSApp.setActivationPolicy(.accessory)
```

### Issue: Microphone permission not requested

**Solution**: 
1. Check Info.plist contains `NSMicrophoneUsageDescription`
2. Reset permissions: `tccutil reset Microphone`
3. Restart the app

### Issue: "Module 'Combine' has no member named..."

**Solution**: Make sure you're targeting macOS 15.0+

### Issue: Build errors about @Observable

**Solution**: 
1. Ensure you're using Swift 6.0+
2. Check "Enable upcoming features" in Build Settings if needed

---

## 📦 Build for Distribution (DMG)

### 1. Archive the App

1. Select **Product** → **Archive**
2. Wait for archive to complete
3. Click **Distribute App**
4. Select **Copy App**
5. Save the exported app

### 2. Create DMG (Optional)

Use `create-dmg` or similar tool:

```bash
# Install create-dmg
brew install create-dmg

# Create DMG
create-dmg \
  --volname "Suno Installer" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --app-drop-link 450 185 \
  Suno.dmg \
  /path/to/Suno.app
```

### 3. Notarization (Recommended)

For distribution outside the App Store:

```bash
# Notarize
xcrun notarytool submit Suno.dmg \
  --apple-id "your@email.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "app-specific-password"

# Staple
xcrun stapler staple Suno.dmg
```

---

## 🎯 What's Next?

You now have a fully functional macOS menu bar meeting recorder!

### Immediate improvements you could add:
- Global keyboard shortcuts for quick recording
- Launch at login option
- Custom recording file naming
- Audio playback directly in the popover
- Export recordings to different locations

### Milestone 2 - Calendar Integration:
- EventKit integration
- Link recordings to calendar events
- Auto-suggest meeting titles
- Smart recording start based on calendar

### Milestone 3 - AI Features:
- Speech-to-text transcription
- AI-generated summaries
- Minutes of Meeting (MOM) generation
- Search within transcriptions

---

## 💡 Tips

1. **Test thoroughly** before distributing
2. **Version control** - commit this milestone
3. **User feedback** - share with a few users first
4. **Monitor Console.app** for any runtime issues
5. **Keep it simple** - resist feature creep in v1.0

---

**Need help?** Check the main README.md for detailed documentation.

**Ready to code!** 🚀
