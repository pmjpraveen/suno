# New UI Design - iOS-Inspired Recording Interface

## Overview
Completely redesigned the Recording Controls UI to match a modern, minimalist iOS-style interface with pill-shaped buttons, segmented controls, and clean spacing.

## Design Philosophy
- **Minimalist**: Clean, uncluttered interface with focus on primary actions
- **iOS-inspired**: Rounded corners, pill shapes, and modern typography
- **Clear hierarchy**: Large primary action button with supporting controls
- **Accessible**: High contrast, clear labels, and proper spacing

## Key Components

### 1. **Recording Mode Selector**
```
┌─────────────────────────────┐
│  Meeting  │      Memo       │  ← Segmented Control
└─────────────────────────────┘
```
- Standard iOS segmented control
- Two modes: Meeting and Memo
- Clean, minimal styling

### 2. **Audio Device Selector**
```
┌──────────────────────────────────────┐
│ 🎤  MacBook Pro Microphone    [ On ] │  ← Pill-shaped selector
└──────────────────────────────────────┘
```
- Capsule-shaped button with:
  - Microphone icon on left
  - Device name in center
  - Blue "On" badge on right
- Light blue border for emphasis
- Dropdown menu to select different audio devices

### 3. **Start Recording Button**
```
┌──────────────────────────────────────┐
│    ●  Start recording                │  ← Large black button
└──────────────────────────────────────┘
```
- Large, prominent black button
- Red dot indicator
- White text
- Capsule shape
- Full-width design

## Visual Specifications

### Colors
- **Primary Button**: `Color.black` with white text
- **Recording Dot**: `Color.red`
- **Device Badge**: `Color.blue` with white text
- **Border**: `Color.blue.opacity(0.2)`
- **Background**: `Color(nsColor: .controlBackgroundColor)`

### Typography
- **Button Text**: System font, 17pt, semibold
- **Device Name**: System font, 15pt, regular
- **Badge**: System font, 14pt, semibold
- **Timer**: System font, 48pt, bold, rounded, monospaced

### Spacing
- **Main Container**: 24px padding
- **Between Elements**: 20px spacing
- **Button Padding**: 20px vertical
- **Device Selector**: 16px vertical, 20px horizontal

### Corner Radius
- **Capsule Buttons**: Full capsule (height/2)
- **Cards**: 16px radius

## Recording State UI

### Active Recording View
```
┌────────────────────────────────┐
│  Meeting Badge      [Edit]     │
├────────────────────────────────┤
│  ● Recording                   │
│                                │
│      00:05:23                  │
│                                │
├────────────────────────────────┤
│  ⏸ Pause    │    ⏹ Stop      │
└────────────────────────────────┘
```

Features:
- Meeting badge at top (if applicable)
- Status indicator with label
- **Large timer** (48pt, bold, rounded)
- Control buttons side-by-side
- Rounded cards with icons

### Paused State
- Orange indicator
- "Resume" instead of "Pause"
- Same layout and styling

## Component Breakdown

### 1. **RecordingMode Enum**
```swift
enum RecordingMode: String, CaseIterable {
    case meeting = "Meeting"
    case memo = "Memo"
}
```

### 2. **AudioDevice Struct**
```swift
struct AudioDevice: Identifiable, Hashable {
    let id: String
    let name: String
    
    static var defaultDevice: AudioDevice
    static var availableDevices: [AudioDevice]
}
```

### 3. **State Management**
- `@State private var recordingMode: RecordingMode = .meeting`
- `@State private var selectedAudioDevice: AudioDevice?`
- Uses existing `viewModel` for recording logic

## Accessibility Features
- Proper labels for all interactive elements
- High contrast colors
- Clear visual feedback for actions
- Voice-over friendly structure
- Large touch targets (20px vertical padding minimum)

## Animation & Interactions
- Smooth transitions between idle and recording states
- Pulsing animation on recording indicator
- Hover states on buttons
- Active states with visual feedback

## Permission Warning
```
┌────────────────────────────────────────┐
│ ⚠️  Microphone Access Required        │
│    Grant permission to start recording │
│                                        │
│  [Open System Settings]                │
└────────────────────────────────────────┘
```
- Orange gradient background
- Clear messaging
- Prominent action button
- Rounded corners with border

## Responsive Behavior
- Adapts to different window sizes
- Maintains proportions across states
- Smooth transitions between views
- Proper spacing maintained

## Future Enhancements
- [ ] Waveform visualization while recording
- [ ] Audio level meter in device selector
- [ ] Quick switch between recent devices
- [ ] Keyboard shortcuts display
- [ ] Dark mode optimization
- [ ] Custom recording presets

## Implementation Notes
- Uses SwiftUI for all UI components
- Pure declarative syntax
- No custom UI components needed (uses system controls)
- Compatible with macOS 13.0+
- Follows Apple HIG guidelines

---

**Date:** September 2, 2026  
**Design Inspiration:** iOS Voice Memos  
**Platform:** macOS  
**Framework:** SwiftUI
