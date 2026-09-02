# Fix: "Speech recognition is not available on this device"

## Problem

You're getting this error because:
1. The transcription service isn't using the language parameter yet
2. The selected language might not be supported
3. Some languages require internet connection

## Quick Fix

### Option 1: Use Auto-Detect (Recommended)

Before recording:
1. Set Language to **🌐 Auto-Detect**
2. This uses your system's default language
3. Most reliable option

### Option 2: Use English

1. Set Language to **🇺🇸 English**
2. English has the best support
3. Works offline on most systems

### Option 3: Check Internet Connection

Many languages require internet:
- All Indian languages except Hindi
- Some international languages

**Make sure you're connected to the internet**

## Root Cause

The `AppleSpeechTranscriptionService.swift` file in the repository **doesn't have the language parameter support yet**.

The file needs to be updated to match the protocol signature:
```swift
// Current (in repo):
func transcribe(recording: Recording, progressHandler: ...) 

// Should be:
func transcribe(recording: Recording, language: Language, progressHandler: ...)
```

## Immediate Workaround

Until the file is updated, you can:

1. **Use Auto-Detect mode**
   - This will use your system language
   - Usually English on most Macs

2. **Check System Language**
   - System Settings → General → Language & Region
   - Make sure a supported language is set

3. **Enable Internet**
   - Many transcription features require network
   - Check WiFi connection

## Supported Languages (Offline)

These work WITHOUT internet:
- 🇺🇸 English
- 🇪🇸 Spanish  
- 🇫🇷 French
- 🇩🇪 German
- 🇯🇵 Japanese
- 🇨🇳 Chinese

## Require Internet

These NEED internet connection:
- 🇮🇳 All Indian languages (Hindi, Tamil, Telugu, etc.)
- Some other languages depending on macOS version

## Testing

### Test 1: English with Auto-Detect

1. Language: **🌐 Auto-Detect**
2. Record in English
3. Should work offline

### Test 2: Check System  Recognizer

Open Terminal and run:
```bash
# Check if speech recognition is available
system_profiler SPAudioDataType | grep -i "speech"
```

### Test 3: Check macOS Version

```bash
sw_vers
```

- **macOS 13+**: Better language support
- **macOS 12**: Limited languages
- **macOS 11 or earlier**: Very limited

## Permanent Fix Needed

The `AppleSpeechTranscriptionService.swift` needs to be updated with the language support code I provided earlier. This includes:

1. Accept `language` parameter
2. Try requested language
3. Fallback to system default if unavailable
4. Fallback to English if system default fails
5. Check `recognizer.isAvailable` properly
6. Handle network requirements

## Console Diagnostics

When transcription starts, you should see:
```
🎙️ Starting transcription for: filename.m4a
🌍 Requested language: Auto-Detect
🗣️ Using system default recognizer: en-US
✅ Final recognizer locale: en-US
🌐 Requires network: false
```

If you see:
```
❌ Transcription failed: Speech recognition is not available
```

It means:
- No recognizer could be created
- System language not supported
- Or recognizer created but `.isAvailable` returned false

## Quick Diagnostic Steps

1. **Check Language Setting**
   - Set to Auto-Detect
   - Try again

2. **Check Internet**
   - Connect to WiFi
   - Try again

3. **Check System Language**
   - System Settings → Language & Region
   - Should show English or supported language

4. **Restart Xcode**
   - Sometimes helps
   - Clean build folder

5. **Check macOS Version**
   - Update to latest if possible
   - macOS 13+ recommended

## Alternative Solution

If speech recognition truly isn't available on your device:

1. **Manual Transcription**: Type notes manually
2. **External Service**: Use a web-based transcription service
3. **Different Device**: Test on another Mac
4. **Update macOS**: Upgrade to get better support

## Summary

**Immediate Fix**: Set language to **🌐 Auto-Detect** and ensure **internet connection**

**Permanent Fix**: Update AppleSpeechTranscriptionService.swift with language support code

**Best Workaround**: Use English or Auto-Detect for now

---

**Current Status**: Language picker UI works, but backend needs language parameter support  
**Next Step**: Try Auto-Detect mode with internet connection
