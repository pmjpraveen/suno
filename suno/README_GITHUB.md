# Suno 🎙️

A native macOS menu bar app for recording meetings with automatic transcription and AI-generated summaries.

![macOS](https://img.shields.io/badge/macOS-15.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## ✨ Features (Milestone 1)

### 🎯 Core Recording
- ✅ **Menu bar app** - Lives in your status bar, not the Dock
- ✅ **Smart controls** - Start, pause, resume, and stop recordings
- ✅ **Live duration** - Real-time recording duration display
- ✅ **Two formats** - M4A (AAC) for efficiency, WAV for quality
- ✅ **Visual feedback** - Status bar icon changes color and animates

### 📁 Recording Management
- ✅ **Recordings list** - View all your past recordings
- ✅ **Quick actions** - Delete recordings or show in Finder
- ✅ **Persistent storage** - Recordings saved locally with metadata
- ✅ **Smart organization** - Sorted by date, newest first

### 🔐 Privacy & Permissions
- ✅ **Microphone access** - Properly requests and handles permissions
- ✅ **Local storage** - All data stays on your Mac
- ✅ **No tracking** - Your privacy is protected

## 🎬 Demo

```
┌─────────────────────────────────────┐
│  Menu Bar:  🔴 [Recording...]       │
└─────────────────────────────────────┘
              ↓ Click
┌─────────────────────────────────────┐
│  ┌───────────────────────────────┐  │
│  │ 🔴 00:15:32                   │  │
│  │ [⏸ Pause]  [⏹ Stop]          │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ Recordings (5)                │  │
│  │ 🎙 Team Standup - 15:32      │  │
│  │ 🎙 Client Call - 45:12       │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

## 🚀 Quick Start

### Requirements
- macOS 15.0 or later
- Xcode 16.0 or later
- Microphone access

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/suno.git
   cd suno
   ```

2. **Open in Xcode**
   ```bash
   open suno.xcodeproj
   ```

3. **Configure signing**
   - Select your development team in Signing & Capabilities
   - Disable App Sandbox (we're not using App Store)

4. **Build and run**
   - Press `⌘R` or Product → Run
   - Grant microphone permission when prompted
   - Click the menu bar icon to start recording!

## 📖 Documentation

- **[BUILD_CHECKLIST.md](BUILD_CHECKLIST.md)** - Complete build and test guide
- **[SETUP.md](SETUP.md)** - Quick setup instructions
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Architecture overview
- **[FIXES_APPLIED.md](FIXES_APPLIED.md)** - Recent bug fixes

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│         Menu Bar (Status Bar)           │
│    NSStatusItem + MenuBarManager        │
└────────────────┬────────────────────────┘
                 │
         ┌───────┴──────┐
         │   Popover    │
         │   SwiftUI    │
         └───────┬──────┘
                 │
    ┌────────────┼───────────┐
    │            │           │
┌───┴────┐  ┌───┴────┐  ┌──┴──┐
│Controls│  │ViewModel│  │List │
│  View  │  │@Observable│ │View │
└────────┘  └────┬────┘  └─────┘
                 │
          ┌──────┴──────┐
          │             │
  ┌───────┴──────┐  ┌──┴────────┐
  │AudioRecorder │  │  Storage  │
  │   Service    │  │  Service  │
  └──────────────┘  └───────────┘
```

**MVVM Pattern:**
- **Models** - Recording, RecordingState, AudioFormat
- **Views** - SwiftUI views (PopoverContentView, RecordingControlsView, etc.)
- **ViewModels** - RecordingViewModel (business logic)
- **Services** - AudioRecorderService, RecordingStorageService

## 🎯 Roadmap

### ✅ Milestone 1: Recording Foundation (COMPLETE)
- Menu bar app with recording controls
- M4A and WAV format support
- Recording management and persistence

### 🔄 Milestone 2: Calendar Integration (PLANNED)
- Link recordings to calendar events
- Auto-start recording for meetings
- Smart title suggestions from calendar

### 🔮 Milestone 3: AI Features (PLANNED)
- Automatic transcription
- AI-generated summaries
- Minutes of Meeting (MOM) generation
- Searchable transcripts

## 🛠️ Tech Stack

- **Language**: Swift 6.0
- **UI Framework**: SwiftUI
- **Audio**: AVFoundation
- **Storage**: FileManager + JSON
- **State Management**: @Observable macro
- **Platform**: macOS 15.0+

## 📂 Project Structure

```
suno/
├── App/
│   ├── sunoApp.swift           # App entry point
│   ├── AppDelegate.swift       # Menu bar lifecycle
│   └── MenuBarManager.swift    # Status bar controller
├── Models/
│   ├── Recording.swift         # Recording metadata
│   ├── RecordingState.swift    # State enum
│   └── AudioFormat.swift       # Format definitions
├── ViewModels/
│   └── RecordingViewModel.swift # Business logic
├── Services/
│   ├── AudioRecorderService.swift    # Recording engine
│   └── RecordingStorageService.swift # Persistence
└── Views/
    ├── PopoverContentView.swift      # Main popover
    ├── RecordingControlsView.swift   # Controls UI
    ├── RecordingListView.swift       # Recordings list
    └── RecordingRowView.swift        # List row
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with ❤️ using SwiftUI and AVFoundation
- Inspired by the need for better meeting documentation
- Thanks to the Swift and macOS developer community

## 📧 Contact

**Praveenkumar Jogannavar**

- GitHub: [@YOUR_USERNAME](https://github.com/YOUR_USERNAME)
- Email: your.email@example.com

## 🐛 Known Issues

See [Issues](https://github.com/YOUR_USERNAME/suno/issues) for a list of known issues and planned enhancements.

## 📊 Status

- **Status**: ✅ Milestone 1 Complete
- **Version**: 1.0.0
- **Last Updated**: September 2026

---

**Made with ☕ and 🎵**
