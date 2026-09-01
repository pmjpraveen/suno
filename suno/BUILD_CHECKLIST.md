# Suno - Build Checklist ✅

## Pre-Build Verification

Before building, verify these items in Xcode:

### 1. File Targets ✅
All files must be added to your target. Select each file and check **File Inspector** (⌘⌥1):

**App Files:**
- [ ] `sunoApp.swift`
- [ ] `AppDelegate.swift`
- [ ] `MenuBarManager.swift`

**Models:**
- [ ] `Recording.swift`
- [ ] `RecordingState.swift`
- [ ] `AudioFormat.swift`

**Services:**
- [ ] `AudioRecorderService.swift`
- [ ] `RecordingStorageService.swift`

**ViewModels:**
- [ ] `RecordingViewModel.swift`

**Views:**
- [ ] `PopoverContentView.swift`
- [ ] `RecordingControlsView.swift`
- [ ] `RecordingListView.swift`
- [ ] `RecordingRowView.swift`

**Helpers:**
- [ ] `Extensions.swift`

**Configuration:**
- [ ] `Info.plist` (verify it's set in Build Settings)

---

### 2. Build Settings ⚙️

**Select your target → Build Settings tab:**

| Setting | Value |
|---------|-------|
| **macOS Deployment Target** | 15.0 or later |
| **Swift Language Version** | Swift 6 |
| **Info.plist File** | `Info.plist` |

---

### 3. Info.plist Configuration 📄

**Verify Info.plist contains:**

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Suno needs microphone access to record your meetings.</string>
```

**In Xcode:**
1. Select project → Select target → **Info** tab
2. Verify "Privacy - Microphone Usage Description" exists
3. Value should be: "Suno needs microphone access to record your meetings."

---

### 4. Signing & Capabilities 🔐

**Select your target → Signing & Capabilities tab:**

- [ ] **Automatically manage signing**: ✅ Enabled
- [ ] **Team**: Selected
- [ ] **App Sandbox**: ❌ DISABLED (important!)
- [ ] **Hardened Runtime**: Optional (for distribution)

**Why no App Sandbox?**
We're distributing via DMG, not App Store. Sandbox complicates file access.

---

### 5. Clean Build 🧹

Before first build:

```bash
# In Xcode menu:
Product → Clean Build Folder (⌘⇧K)

# Or delete derived data:
rm -rf ~/Library/Developer/Xcode/DerivedData/suno-*
```

---

## Build Steps 🔨

### Step 1: Verify All Files Compile
```
Product → Build (⌘B)
```

**Expected:** ✅ Build Succeeded

**If errors:** Check `FIXES_APPLIED.md` and `TROUBLESHOOTING.md`

---

### Step 2: Run the App
```
Product → Run (⌘R)
```

**Expected:**
- ✅ App launches
- ✅ No Dock icon appears
- ✅ Status bar icon appears (gray circle)

**If not:** Check Console.app for errors

---

### Step 3: Test Menu Bar Icon

1. **Click the status bar icon**
   - ✅ Popover should appear
   - ✅ Shows recording controls

2. **Right-click the icon**
   - ✅ "Quit Suno" menu appears

---

### Step 4: Test Microphone Permission

1. **Click "Start Recording"**
   - ✅ macOS requests microphone permission
   - ✅ Grant permission
   - ✅ Recording starts

**If permission not requested:**
- Check Info.plist has `NSMicrophoneUsageDescription`
- Reset permissions: `tccutil reset Microphone`
- Restart app

---

### Step 5: Test Recording Flow

1. **Start Recording**
   - ✅ Button changes to "Pause" and "Stop"
   - ✅ Duration starts counting (00:00, 00:01, 00:02...)
   - ✅ Status bar icon turns RED
   - ✅ Icon animates (pulse effect)

2. **Pause Recording**
   - ✅ Duration stops
   - ✅ Button changes to "Resume"
   - ✅ Status bar icon turns YELLOW

3. **Resume Recording**
   - ✅ Duration continues from where it stopped
   - ✅ Status bar icon turns RED again

4. **Stop Recording**
   - ✅ Recording saves
   - ✅ Appears in recordings list
   - ✅ Status bar icon turns GRAY
   - ✅ Shows recording metadata (date, duration, format)

---

### Step 6: Test Recording Management

1. **Hover over a recording**
   - ✅ Folder and trash icons appear

2. **Click folder icon**
   - ✅ Finder opens showing the file
   - ✅ File location: `~/Library/Application Support/suno/Recordings/`

3. **Click trash icon**
   - ✅ Confirmation dialog appears
   - ✅ Recording deleted from list
   - ✅ File removed from disk

4. **Right-click a recording**
   - ✅ Context menu appears
   - ✅ "Show in Finder" works
   - ✅ "Delete" works

---

### Step 7: Test Both Audio Formats

1. **Select M4A format**
   - ✅ Record for 10 seconds
   - ✅ Stop and check file
   - ✅ File extension: `.m4a`
   - ✅ File size: ~150KB (small)

2. **Select WAV format**
   - ✅ Record for 10 seconds
   - ✅ Stop and check file
   - ✅ File extension: `.wav`
   - ✅ File size: ~1.5MB (larger)

3. **Format preference persists**
   - ✅ Select WAV
   - ✅ Quit app (right-click → Quit)
   - ✅ Restart app
   - ✅ WAV still selected

---

### Step 8: Test Persistence

1. **Record a meeting**
2. **Quit the app** (right-click → Quit)
3. **Restart the app**
   - ✅ Previous recordings still appear
   - ✅ Files still playable

4. **Check file system**
   ```bash
   open ~/Library/Application\ Support/suno/
   ```
   - ✅ `Recordings/` folder has audio files
   - ✅ `Metadata/recordings.json` exists

---

## Post-Build Testing 🧪

### Edge Cases to Test:

- [ ] **Rapid start/stop** - No crashes
- [ ] **Long recording** (30+ min) - Works without issues
- [ ] **Multiple recordings** - All save correctly
- [ ] **Delete all recordings** - Empty state appears
- [ ] **Permission denied** - Warning appears in UI
- [ ] **Quit during recording** - Handles gracefully

---

## Common Build Errors 🚨

### Error: "Cannot find 'RecordingViewModel' in scope"
**Fix:** Select file → File Inspector → Check target membership

### Error: "Module 'AVFoundation' not found"
**Fix:** Add AVFoundation framework to target → Build Phases → Link Binary

### Error: "@Observable requires macOS 14.0"
**Fix:** Build Settings → macOS Deployment Target → Set to 15.0

### Error: "Info.plist not found"
**Fix:** Build Settings → Info.plist File → Set to `Info.plist`

### Warning: App Sandbox issues
**Fix:** Signing & Capabilities → Remove App Sandbox

---

## Success Criteria ✅

Your build is successful when:

- ✅ App appears only in menu bar (not Dock)
- ✅ Microphone permission requested
- ✅ Recording starts/pauses/stops
- ✅ Duration updates in real-time
- ✅ Status bar icon changes color
- ✅ Recordings save and persist
- ✅ Both M4A and WAV formats work
- ✅ Delete and show in Finder work
- ✅ App doesn't crash under normal use

---

## Performance Benchmarks 📊

Expected performance:

| Metric | Expected Value |
|--------|----------------|
| **App launch time** | < 1 second |
| **Popover open time** | Instant |
| **Recording start delay** | < 500ms |
| **Memory usage (idle)** | ~20-30 MB |
| **Memory usage (recording)** | ~40-50 MB |
| **CPU usage (recording M4A)** | ~2-5% |
| **CPU usage (recording WAV)** | ~1-3% |

**If higher:** Check for issues in AudioRecorderService timer

---

## Distribution Checklist 📦

When ready to distribute:

### 1. Archive the App
- [ ] Product → Archive
- [ ] Organizer opens
- [ ] Select archive → Distribute App

### 2. Export Options
- [ ] Copy App (for DMG)
- [ ] Save to Desktop

### 3. Test on Clean Mac
- [ ] Copy app to another Mac
- [ ] Test launch and permissions
- [ ] Verify all features work

### 4. Create DMG (Optional)
```bash
brew install create-dmg
create-dmg --volname "Suno" --app-drop-link 450 185 Suno.dmg Suno.app
```

### 5. Notarize (Recommended)
```bash
xcrun notarytool submit Suno.dmg \
  --apple-id "your@email.com" \
  --password "app-specific-password" \
  --team-id "YOUR_TEAM_ID"
```

---

## Final Checklist ✅

Before declaring "DONE":

- [ ] All build errors resolved
- [ ] All features tested
- [ ] No memory leaks (test with Instruments)
- [ ] No crashes in normal usage
- [ ] Recordings playable in QuickTime
- [ ] Documentation reviewed
- [ ] Ready for beta testing

---

## 🎉 You're Ready!

If all checkboxes are ✅, you have a working macOS menu bar meeting recorder!

**Next:**
- Share with beta testers
- Collect feedback
- Plan Milestone 2 (Calendar integration)

**Congratulations!** 🚀

---

**Need help?** See `TROUBLESHOOTING.md`  
**Architecture questions?** See `IMPLEMENTATION_SUMMARY.md`  
**Setup issues?** See `SETUP.md`
