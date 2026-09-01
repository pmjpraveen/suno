//
//  AudioFormat.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import Foundation
import AVFoundation

enum AudioFormat: String, CaseIterable, Codable {
    case m4a = "M4A (AAC)"
    case wav = "WAV (Lossless)"
    
    var fileExtension: String {
        switch self {
        case .m4a: return "m4a"
        case .wav: return "wav"
        }
    }
    
    var audioSettings: [String: Any] {
        switch self {
        case .m4a:
            return [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
        case .wav:
            return [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false
            ]
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
}
