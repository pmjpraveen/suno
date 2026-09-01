# Suno - Meeting Recorder

A native macOS menu bar app for recording meetings with automatic transcription and AI summaries (coming soon).

## Current Features (Milestone 1)

✅ **Menu Bar App**
- Lives in the macOS menu bar (not in Dock)
- Popover interface appears from status bar
- Status icon changes based on recording state:
  - ⚫️ Idle (gray)
  - 🔴 Recording (red, animated)
  - ⏸️ Paused (yellow)

✅ **Recording Controls**
- Start/Pause/Resume/Stop recording
- Live duration display
- Visual state indicators
- Support for both M4A (AAC) and WAV (Lossless) formats

✅ **Recording Management**
- List all recordings with metadata
- Show recording date, duration, format, and file size
- Delete recordings
- Show in Finder
- Persistent storage using JSON + local files

✅ **Clean Foundation**
- Built with SwiftUI
- MVVM architecture
- Ready for calendar integration
- Ready for AI transcription/summary features

## Requirements

- macOS 15.0+
- Xcode 16.0+
- Microphone permission

## Project Structure

```
suno/
├── App/
│   ├── sunoApp.swift              # App entry point
│   ├── AppDelegate.swift          # Menu bar & lifecycle management
│   └── MenuBarManager.swift       # Status bar icon controller
│
├── Models/
│   ├── Recording.swift            # Recording metadata model
│   ├── RecordingState.swift       # Recording state enum
│   └── AudioFormat.swift          # M4A/WAV format definitions
│
├── ViewModels/
│   └── RecordingViewModel.swift   # Main view model
│
├── Services/
│   ├── AudioRecorderService.swift     # AVFoundation recording
│   └── RecordingStorageService.swift  # File & metadata persistence
│
└── Views/
    ├── PopoverContentView.swift       # Main popover container
    ├── RecordingControlsView.swift    # Recording controls UI
    ├── RecordingListView.swift        # Recordings list
    └── RecordingRowView.swift         # Individual recording row
```

## Building the App

### 1. Setup Project in Xcode

1. Open the project in Xcode
2. Ensure all files are added to the target
3. Verify Info.plist is configured correctly
4. Set deployment target to macOS 15.0+

### 2. Configure Signing

1. Go to **Signing & Capabilities** tab
2. Select your development team
3. Ensure "Automatically manage signing" is enabled
4. **Do NOT enable App Sandbox** (we're not distributing via App Store)

### 3. Build and Run

1. Press **⌘R** to build and run
2. The app will appear in the menu bar (no Dock icon)
3. Click the menu bar icon to open the popover
4. Grant microphone permission when prompted

## Usage

### Recording a Meeting

1. Click the Suno icon in the menu bar
2. Select audio format (M4A or WAV)
3. Click "Start Recording" button
4. The menu bar icon turns red and animates
5. Click "Pause" to temporarily pause recording
6. Click "Stop" to finish and save the recording

### Managing Recordings

- **View recordings**: Listed in the popover with metadata
- **Delete recording**: Hover over a recording and click the trash icon
- **Show in Finder**: Hover and click the folder icon, or right-click → "Show in Finder"

### Keyboard Shortcuts

- Right-click menu bar icon → Quit Suno
- Press **Esc** to close the popover

## Storage Locations

Recordings and metadata are stored in:

```
~/Library/Application Support/suno/
├── Recordings/           # Audio files (.m4a, .wav)
│   ├── <uuid>.m4a
│   └── <uuid>.wav
└── Metadata/            # Recording metadata
    └── recordings.json
```

## Audio Formats

### M4A (AAC) - Default
- **Quality**: High (lossy compression)
- **File Size**: ~1 MB per minute
- **CPU Usage**: Low
- **Best for**: Most meetings, sharing

### WAV (Lossless)
- **Quality**: Maximum (no compression)
- **File Size**: ~10 MB per minute
- **CPU Usage**: Very low
- **Best for**: Archival, professional editing

## Troubleshooting

### No microphone permission

1. Open **System Settings** → **Privacy & Security** → **Microphone**
2. Enable microphone access for Suno
3. Restart the app

### App not appearing in menu bar

1. Check that `NSApp.setActivationPolicy(.accessory)` is called in AppDelegate
2. Verify the app is running (check Activity Monitor)
3. Try restarting the app

### Recordings not saving

1. Check **Console.app** for error messages
2. Verify write permissions to `~/Library/Application Support/`
3. Ensure sufficient disk space

## Future Roadmap

### Milestone 2: Calendar Integration
- Link recordings to calendar events
- Auto-start recording for meetings
- Meeting title suggestions

### Milestone 3: AI Features
- Automatic transcription
- AI-generated summaries
- Minutes of Meeting (MOM) generation

## Architecture Notes

### MVVM Pattern
- **Models**: Data structures (Recording, RecordingState, AudioFormat)
- **Views**: SwiftUI views (PopoverContentView, RecordingControlsView, etc.)
- **ViewModels**: Business logic (RecordingViewModel)
- **Services**: External interactions (AudioRecorderService, RecordingStorageService)

### State Management
- Uses Swift's `@Observable` macro for reactive state
- View model coordinates between services and views
- Menu bar icon updates automatically based on recording state

### Persistence Strategy
- Audio files stored as individual files (easy to access/share)
- Metadata stored as JSON (easy to migrate to SwiftData later)
- Future-ready fields already in the Recording model

## Development Tips

### Testing

1. Test all recording states: idle → recording → paused → recording → stopped
2. Test both M4A and WAV formats
3. Test deletion and "Show in Finder"
4. Test with long recordings (30+ minutes)
5. Test permission denial scenarios

### Debugging

- Use breakpoints in RecordingViewModel for business logic
- Check AudioRecorderService for recording issues
- Monitor Console.app for AVFoundation errors
- Use `po` in LLDB to inspect Recording objects

## Distribution

For DMG distribution (not App Store):

1. Archive the app in Xcode
2. Export as a Mac app (without App Store signing)
3. Optionally notarize the app for Gatekeeper
4. Create a DMG using tools like `create-dmg`
5. Distribute via your website

## License

[Add your license here]

## Credits

Built with ❤️ using SwiftUI and AVFoundation

---

**Version**: 1.0  
**Target**: macOS 15.0+  
**Status**: Milestone 1 Complete ✅
