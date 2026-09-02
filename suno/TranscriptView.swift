//
//  TranscriptView.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import SwiftUI

struct TranscriptView: View {
    let transcript: Transcript?
    let recording: Recording
    let onRetry: () -> Void
    let onCancel: () -> Void
    let onSeek: ((TimeInterval) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Transcript")
                    .font(.headline)
                
                // Language indicator
                if let transcript = transcript, let language = transcript.language {
                    Text(language.flag)
                        .font(.caption)
                        .help(language.displayName)
                }
                
                Spacer()
                
                if let transcript = transcript {
                    statusBadge(for: transcript.status)
                }
            }
            
            Divider()
            
            // Content
            Group {
                if let transcript = transcript {
                    transcriptContent(transcript)
                } else {
                    emptyState
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Status Badge
    
    @ViewBuilder
    private func statusBadge(for status: TranscriptionStatus) -> some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption)
            Text(status.displayText)
                .font(.caption)
        }
        .foregroundStyle(statusColor(for: status))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor(for: status).opacity(0.15))
        .cornerRadius(6)
    }
    
    private func statusColor(for status: TranscriptionStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .transcribing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .gray
        }
    }
    
    // MARK: - Transcript Content
    
    @ViewBuilder
    private func transcriptContent(_ transcript: Transcript) -> some View {
        switch transcript.status {
        case .pending:
            pendingView
            
        case .transcribing:
            transcribingView(progress: transcript.progress)
            
        case .completed:
            completedView(transcript: transcript)
            
        case .failed:
            failedView(errorMessage: transcript.errorMessage)
            
        case .cancelled:
            cancelledView
        }
    }
    
    // MARK: - State Views
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.title)
                .foregroundStyle(.secondary)
            
            Text("Not transcribed")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    private var pendingView: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.title)
                .foregroundStyle(.orange)
            
            Text("Transcription pending...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    private func transcribingView(progress: Double) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 16, height: 16)
                
                Text("Transcribing...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if progress > 0 {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 200)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Button("Cancel") {
                onCancel()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    private func completedView(transcript: Transcript) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Stats
            HStack(spacing: 16) {
                statItem(label: "Segments", value: "\(transcript.segmentCount)")
                statItem(label: "Words", value: "\(transcript.wordCount)")
                
                if let completedAt = transcript.completedAt {
                    statItem(label: "Completed", value: relativeTime(completedAt))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            Divider()
            
            // Segments
            if transcript.segments.isEmpty {
                Text(transcript.fullText)
                    .font(.body)
                    .textSelection(.enabled)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(transcript.segments) { segment in
                            TranscriptSegmentView(
                                segment: segment,
                                onTap: onSeek
                            )
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
        }
    }
    
    private func failedView(errorMessage: String?) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(.red)
            
            Text("Transcription failed")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    private var cancelledView: some View {
        VStack(spacing: 12) {
            Image(systemName: "xmark.circle")
                .font(.title)
                .foregroundStyle(.gray)
            
            Text("Transcription cancelled")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Helpers
    
    @ViewBuilder
    private func statItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Transcript Segment View

struct TranscriptSegmentView: View {
    let segment: TranscriptSegment
    let onTap: ((TimeInterval) -> Void)?
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timestamp
            Text(segment.formattedTime)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
                .monospacedDigit()
            
            // Text
            Text(segment.text)
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Confidence indicator (if available)
            if let confidence = segment.confidence {
                confidenceIndicator(confidence)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isHovered ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onTap?(segment.startTime)
        }
        .help(onTap != nil ? "Click to seek to \(segment.formattedTime)" : "")
    }
    
    @ViewBuilder
    private func confidenceIndicator(_ confidence: Float) -> some View {
        let color: Color = {
            if confidence > 0.8 { return .green }
            if confidence > 0.5 { return .orange }
            return .red
        }()
        
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .help("Confidence: \(Int(confidence * 100))%")
    }
}

// MARK: - Previews

#Preview("Completed") {
    TranscriptView(
        transcript: Transcript(
            recordingID: UUID(),
            status: .completed,
            segments: [
                TranscriptSegment(text: "Let's start with the onboarding flow. I think we need to simplify the steps.", startTime: 10.5, duration: 4.2, confidence: 0.95),
                TranscriptSegment(text: "The biggest issue we're seeing is users dropping off at the payment screen.", startTime: 15.3, duration: 5.1, confidence: 0.88),
                TranscriptSegment(text: "What if we add a progress indicator?", startTime: 21.0, duration: 2.8, confidence: 0.92)
            ],
            fullText: "Let's start with the onboarding flow...",
            completedAt: Date().addingTimeInterval(-300)
        ),
        recording: Recording(
            fileName: "Team Meeting.m4a",
            fileURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            format: .m4a,
            startTime: Date(),
            duration: 1800,
            fileSize: 5_000_000
        ),
        onRetry: {},
        onCancel: {},
        onSeek: { time in
            print("Seek to \(time)")
        }
    )
    .frame(width: 600, height: 500)
    .padding()
}

#Preview("Transcribing") {
    TranscriptView(
        transcript: Transcript(
            recordingID: UUID(),
            status: .transcribing,
            progress: 0.45
        ),
        recording: Recording(
            fileName: "Team Meeting.m4a",
            fileURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            format: .m4a,
            startTime: Date(),
            duration: 1800,
            fileSize: 5_000_000
        ),
        onRetry: {},
        onCancel: {},
        onSeek: nil
    )
    .frame(width: 600, height: 300)
    .padding()
}

#Preview("Failed") {
    TranscriptView(
        transcript: Transcript(
            recordingID: UUID(),
            status: .failed,
            errorMessage: "The audio file could not be processed."
        ),
        recording: Recording(
            fileName: "Team Meeting.m4a",
            fileURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            format: .m4a,
            startTime: Date(),
            duration: 1800,
            fileSize: 5_000_000
        ),
        onRetry: {},
        onCancel: {},
        onSeek: nil
    )
    .frame(width: 600, height: 300)
    .padding()
}

#Preview("Not Transcribed") {
    TranscriptView(
        transcript: nil,
        recording: Recording(
            fileName: "Team Meeting.m4a",
            fileURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            format: .m4a,
            startTime: Date(),
            duration: 1800,
            fileSize: 5_000_000
        ),
        onRetry: {},
        onCancel: {},
        onSeek: nil
    )
    .frame(width: 600, height: 300)
    .padding()
}
