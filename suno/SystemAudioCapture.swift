//
//  SystemAudioCapture.swift
//  suno
//
//  Captures macOS system audio output (the other meeting participants) directly via
//  ScreenCaptureKit, instead of relying on the microphone to re-pick-up speaker output —
//  that round-trip is lossy (echo, room noise, distance) and is what drops/garbles words
//  in a mic-only recording.
//

import ScreenCaptureKit
import AVFoundation

final class SystemAudioCapture: NSObject {
    private var stream: SCStream?
    private var audioFile: AVAudioFile?
    private var pendingFileURL: URL?
    private let queue = DispatchQueue(label: "com.suno.systemaudio")

    /// Screen & System Audio Recording — the one TCC permission that gates both.
    static var hasPermission: Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Triggers the system permission prompt if the user hasn't decided yet. If already
    /// denied, this does nothing — the user has to flip it on in System Settings themselves.
    static func requestPermission() {
        CGRequestScreenCaptureAccess()
    }

    func start(writingTo fileURL: URL) async throws {
        pendingFileURL = fileURL

        let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: false)
        guard let display = content.displays.first else {
            throw SystemAudioCaptureError.noDisplayAvailable
        }

        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.excludesCurrentProcessAudio = true
        config.sampleRate = 44100
        config.channelCount = 1
        // We only want the audio track; keep the unavoidable video side of ScreenCaptureKit minimal.
        config.width = 2
        config.height = 2
        config.minimumFrameInterval = CMTime(value: 1, timescale: 1)

        let stream = SCStream(filter: filter, configuration: config, delegate: nil)
        try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: queue)
        try await stream.startCapture()
        self.stream = stream
    }

    /// Returns the file URL actually written to, or nil if no audio was captured
    /// (e.g. permission was denied and the stream never produced a buffer).
    func stop() async -> URL? {
        try? await stream?.stopCapture()
        stream = nil
        let wroteAudio = audioFile != nil
        audioFile = nil
        let url = pendingFileURL
        pendingFileURL = nil
        return wroteAudio ? url : nil
    }
}

extension SystemAudioCapture: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio, sampleBuffer.isValid, let buffer = sampleBuffer.pcmBuffer else { return }

        do {
            if audioFile == nil, let url = pendingFileURL {
                audioFile = try AVAudioFile(forWriting: url, settings: buffer.format.settings)
            }
            try audioFile?.write(from: buffer)
        } catch {
            print("⚠️ Failed to write system audio buffer: \(error.localizedDescription)")
        }
    }
}

enum SystemAudioCaptureError: LocalizedError {
    case noDisplayAvailable

    var errorDescription: String? {
        "No display available to capture system audio from."
    }
}

private extension CMSampleBuffer {
    /// Copies this sample buffer's PCM data into a fresh AVAudioPCMBuffer, matching its own format.
    var pcmBuffer: AVAudioPCMBuffer? {
        guard let formatDescription = CMSampleBufferGetFormatDescription(self),
              let streamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription),
              let format = AVAudioFormat(streamDescription: streamDescription) else {
            return nil
        }

        let numSamples = CMSampleBufferGetNumSamples(self)
        guard numSamples > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(numSamples)) else {
            return nil
        }
        buffer.frameLength = AVAudioFrameCount(numSamples)

        let status = CMSampleBufferCopyPCMDataIntoAudioBufferList(
            self,
            at: 0,
            frameCount: Int32(numSamples),
            into: buffer.mutableAudioBufferList
        )
        return status == noErr ? buffer : nil
    }
}
