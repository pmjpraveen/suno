# Transcription Troubleshooting Guide

## Common Issues & Solutions

### ❌ Transcription Doesn't Start

**Symptom:** Recording completes but transcript status stays "Not transcribed"

**Solutions:**
1. Check speech recognition permission:
   ```
   System Settings → Privacy & Security → Speech Recognition
   ```
2. Check console logs for errors:
   ```
   🚀 Auto-starting transcription for: {filename}
   ```
3. Verify `RecordingViewModel.stopRecording()` calls `startTranscription()`

---

### ❌ Permission Denied Error

**Symptom:** "Speech recognition permission was denied"

**Solutions:**
1. Go to System Settings → Privacy & Security → Speech Recognition
2. Enable permission for "suno"
3. Restart the app
4. Try recording again

**Note:** This is separate from Microphone permission

---

### ❌ Transcription Fails Immediately

**Symptom:** Status goes from "Transcribing..." to "Failed" instantly

**Possible Causes:**
1. **Empty audio file** - Check file size > 0
2. **Corrupted audio** - Try recording again
3. **Unsupported format** - Should work with M4A and WAV
4. **No speech in recording** - Record actual speech, not silence

**Check Console For:**
```
❌ Transcription error: {specific error}
```

---

### ❌ Very Slow Transcription

**Symptom:** Transcription takes longer than expected

**Expected Speed:**
- 1 minute recording → 5-15 seconds
- 10 minute recording → 1-3 minutes
- 1 hour recording → 10-20 minutes

**If Slower:**
1. **Intel Mac** - Slower than Apple Silicon, normal behavior
2. **No network** - May need internet for some languages
3. **Very long recording** - Consider shorter recordings
4. **System load** - Close other intensive apps

---

### ❌ Poor Accuracy

**Symptom:** Transcript text doesn't match audio

**Improvements:**
1. **Speak clearly** - Normal pace, not too fast
2. **Reduce background noise** - Quiet environment
3. **Use better microphone** - Built-in is okay, external is better
4. **Check language** - System language should match spoken language
5. **One speaker at a time** - Multiple overlapping voices reduce accuracy

**Check Confidence Scores:**
- Green dot (>80%) = High confidence
- Orange dot (50-80%) = Medium confidence  
- Red dot (<50%) = Low confidence

Low confidence segments are likely inaccurate.

---

### ❌ Segments Missing Timestamps

**Symptom:** Transcript has text but no clickable segments

**Cause:** Full text provided but segment extraction failed

**Solutions:**
1. This shouldn't happen with Apple Speech (always provides segments)
2. Check console for segment extraction errors
3. Retry transcription

---

### ❌ Audio Seeking Doesn't Work

**Symptom:** Clicking timestamp doesn't seek audio

**Solutions:**
1. Ensure you're in Recording Detail View (not just list)
2. Check audio file still exists at original path
3. Check console for audio player errors
4. Try playing audio first, then seek

---

### ❌ Network Required Error

**Symptom:** "Network connection required for transcription"

**Cause:** On-device recognition not available for this language/system

**Solutions:**
1. **Connect to internet** - Allow server-based transcription
2. **Check macOS version** - On-device requires macOS 13+
3. **Check language** - Some languages only work with server

**Code Check:**
```swift
request.requiresOnDeviceRecognition = false  // Allows server fallback
```

---

### ❌ Transcript Disappears After Restart

**Symptom:** Transcript was there, now it's gone

**Check:**
1. Storage location exists:
   ```
   ~/Library/Application Support/suno/Transcripts/
   ```
2. Files have `.json` extension
3. File naming: `{recordingID}-transcript.json`

**Debug:**
```swift
print("📄 Loaded \(allTranscripts.count) transcripts")
```

Should see this in console on app launch.

---

### ❌ Can't Retry Failed Transcription

**Symptom:** Retry button doesn't appear or doesn't work

**Solutions:**
1. Check transcript status is `.failed` or `.cancelled`
2. Verify original audio file still exists
3. Check `RecordingViewModel.retryTranscription()` is called
4. Check console for errors during retry

---

### ❌ Progress Stuck at 0%

**Symptom:** "Transcribing..." shown but progress never updates

**Cause:** Progress calculation issue or very slow processing

**Check:**
1. Is transcription actually running? (check CPU usage)
2. Console logs showing progress updates?
3. Try shorter recording first
4. File size reasonable? (not corrupted)

**Code Check:**
```swift
progressHandler: { progress in
    Task { @MainActor in
        print("Progress: \(progress)")  // Should see updates
    }
}
```

---

### ❌ Build Errors After Adding Files

**Common Issues:**

**Missing TranscriptionStatus:**
```
Cannot find type 'TranscriptionStatus' in scope
```
**Solution:** Ensure `TranscriptionStatus.swift` is added to target

**Missing TranscriptView:**
```
Cannot find 'TranscriptView' in scope  
```
**Solution:** Ensure all new view files are in target

**Check Target Membership:**
1. Select file in Xcode
2. File Inspector → Target Membership
3. Check "suno" target

---

## Debug Logging

Add to `RecordingViewModel.startTranscription()`:

```swift
print("🎙️ File exists: \(FileManager.default.fileExists(atPath: recording.fileURL.path))")
print("🎙️ File size: \(try? FileManager.default.attributesOfItem(atPath: recording.fileURL.path)[.size])")
print("🎙️ Has permission: \(hasSpeechPermission)")
```

Add to `AppleSpeechTranscriptionService.transcribe()`:

```swift
print("🎤 Recognizer available: \(recognizer.isAvailable)")
print("🎤 Starting recognition for: \(recording.fileURL.lastPathComponent)")
```

---

## Performance Expectations

### Normal Behavior:

| Recording Length | Transcription Time | Progress Updates |
|-----------------|-------------------|------------------|
| 1 minute        | 5-15 seconds      | 5-10 updates     |
| 5 minutes       | 30-60 seconds     | 10-20 updates    |
| 10 minutes      | 1-3 minutes       | 20-30 updates    |
| 30 minutes      | 5-10 minutes      | 30-50 updates    |
| 1 hour          | 10-20 minutes     | 50-100 updates   |

### Platform Differences:

**Apple Silicon (M1/M2/M3):**
- Fast on-device processing
- Rarely needs network
- Progress updates smooth

**Intel Mac:**
- Slower processing
- More likely to use server
- May require network
- Still works, just slower

---

## Permission States

### Speech Recognition

**Authorized:**
```swift
SFSpeechRecognizer.authorizationStatus() == .authorized
```
✅ Transcription works

**Not Determined:**
```swift
SFSpeechRecognizer.authorizationStatus() == .notDetermined
```
⚠️ Will prompt user on first transcription

**Denied:**
```swift
SFSpeechRecognizer.authorizationStatus() == .denied
```
❌ Show error, direct to System Settings

**Restricted:**
```swift
SFSpeechRecognizer.authorizationStatus() == .restricted
```
❌ Device/parental controls prevent use

---

## Testing Checklist

- [ ] Permission granted
- [ ] Short recording (1 min) transcribes successfully
- [ ] Progress shows and updates
- [ ] Segments appear with timestamps
- [ ] Clicking timestamp seeks audio
- [ ] Failed transcription can retry
- [ ] Transcribing can be cancelled
- [ ] Transcript persists after app restart
- [ ] Multiple recordings can transcribe simultaneously
- [ ] Deleting recording doesn't crash (transcript cleaned up)

---

## Still Having Issues?

1. **Check Console.app** for detailed logs
2. **Clean build** (Cmd+Shift+K) then rebuild
3. **Delete app data:**
   ```bash
   rm -rf ~/Library/Application\ Support/suno/
   ```
4. **Reset permissions:**
   ```bash
   tccutil reset SpeechRecognition
   ```
5. **Restart Mac** (sometimes helps with permissions)

---

## Known Limitations

1. ❌ **No real-time transcription** (only post-recording)
2. ❌ **No speaker identification** (multi-speaker not distinguished)
3. ❌ **Language limited** to system language
4. ❌ **Very long recordings** (>2 hours) may timeout
5. ❌ **Background noise** significantly reduces accuracy
6. ⚠️ **Intel Macs** are slower than Apple Silicon

These are inherent to Apple's Speech framework, not bugs.
