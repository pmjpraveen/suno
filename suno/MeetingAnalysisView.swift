//
//  MeetingAnalysisView.swift
//  suno
//

import SwiftUI

struct MeetingAnalysisView: View {
    let analysis: MeetingAnalysis?
    let onRetry: () -> Void
    let onToggleActionItem: ((UUID) -> Void)?
    let onSeek: ((TimeInterval) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("AI Summary", systemImage: "brain.head.profile")
                    .font(.headline)
                
                Spacer()
                
                if let analysis = analysis {
                    statusBadge(for: analysis.status)
                }
            }
            
            Divider()
            
            // Content
            Group {
                if let analysis = analysis {
                    analysisContent(analysis)
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
    private func statusBadge(for status: AnalysisStatus) -> some View {
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
    
    private func statusColor(for status: AnalysisStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .analyzing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
    
    // MARK: - Analysis Content
    
    @ViewBuilder
    private func analysisContent(_ analysis: MeetingAnalysis) -> some View {
        switch analysis.status {
        case .pending:
            pendingView
            
        case .analyzing:
            analyzingView
            
        case .completed:
            completedView(analysis: analysis)
            
        case .failed:
            failedView(errorMessage: analysis.errorMessage)
        }
    }
    
    // MARK: - State Views
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("AI summary not generated")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Complete transcription first to enable AI analysis")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    private var pendingView: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            
            Text("Ready to analyze")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button("Generate AI Summary") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var analyzingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .controlSize(.large)
            
            Text("Analyzing meeting...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("This may take a minute")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    private func failedView(errorMessage: String?) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.red)
            
            Text("Analysis failed")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Retry Analysis") {
                onRetry()
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Completed View
    
    private func completedView(analysis: MeetingAnalysis) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Overview
                if !analysis.overview.isEmpty {
                    sectionView(title: "Overview", icon: "doc.text") {
                        Text(analysis.overview)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
                
                // Key Points
                if !analysis.keyPoints.isEmpty {
                    sectionView(title: "Key Discussion Points", icon: "list.bullet") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(analysis.keyPoints.enumerated()), id: \.offset) { index, point in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                    Text(point)
                                        .font(.body)
                                }
                            }
                        }
                    }
                }
                
                // Decisions
                if !analysis.decisions.isEmpty {
                    sectionView(title: "Key Decisions", icon: "checkmark.seal.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(analysis.decisions) { decision in
                                DecisionRow(decision: decision, onSeek: onSeek)
                            }
                        }
                    }
                }
                
                // Action Items
                if !analysis.actionItems.isEmpty {
                    sectionView(title: "Action Items", icon: "checklist") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(analysis.actionItems) { item in
                                ActionItemRow(
                                    actionItem: item,
                                    onToggle: onToggleActionItem,
                                    onSeek: onSeek
                                )
                                
                                if item.id != analysis.actionItems.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                
                // Minutes of Meeting
                if !analysis.mom.isEmpty {
                    sectionView(title: "Minutes of Meeting", icon: "doc.richtext") {
                        Text(analysis.mom)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)
                    }
                }
                
                // Regenerate button
                HStack {
                    Spacer()
                    Button("Regenerate Analysis") {
                        onRetry()
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxHeight: 600)
    }
    
    // MARK: - Section View
    
    @ViewBuilder
    private func sectionView<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)
            
            content()
        }
    }
}

// MARK: - Decision Row

struct DecisionRow: View {
    let decision: Decision
    let onSeek: ((TimeInterval) -> Void)?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundStyle(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(decision.text)
                    .font(.body)
                
                if let timestamp = decision.formattedTimestamp, let onSeek = onSeek {
                    Button(action: {
                        if let ts = decision.sourceTimestamp {
                            onSeek(ts)
                        }
                    }) {
                        Label(timestamp, systemImage: "waveform")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.blue)
                    .help("Jump to this moment in the recording")
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    MeetingAnalysisView(
        analysis: MeetingAnalysis(
            meetingId: "test-meeting",
            transcriptId: UUID(),
            overview: "The team discussed the Q4 roadmap and prioritized features for the next sprint. Key focus areas include performance improvements and user experience enhancements.",
            keyPoints: [
                "Performance optimization is a top priority",
                "User feedback indicates need for better onboarding",
                "Integration with third-party services is planned for Q1"
            ],
            decisions: [
                Decision(
                    text: "Approved budget for additional infrastructure",
                    sourceTimestamp: 245.5
                ),
                Decision(
                    text: "Will launch beta program in December",
                    sourceTimestamp: 567.2
                )
            ],
            actionItems: [
                ActionItem(
                    task: "Create technical spec for performance improvements",
                    assignee: "Sarah",
                    dueDate: Date().addingTimeInterval(86400 * 7),
                    sourceTimestamp: 892.3,
                    completed: false
                ),
                ActionItem(
                    task: "Schedule user research sessions",
                    assignee: "Mike",
                    dueDate: Date().addingTimeInterval(86400 * 3),
                    sourceTimestamp: 1205.8,
                    completed: true
                )
            ],
            mom: """
            Meeting: Q4 Planning Session
            Date: September 2, 2026
            Participants: Sarah, Mike, Alex, Jordan
            
            Purpose:
            Review Q4 objectives and prioritize upcoming sprint work.
            
            Discussion Summary:
            The team reviewed progress on current initiatives and identified key focus areas for Q4. Performance optimization emerged as the highest priority, with user experience improvements as a close second.
            
            Key Decisions:
            1. Approved additional infrastructure budget
            2. Will launch beta program in December
            
            Action Items:
            1. Create technical spec for performance improvements - Sarah (Due: Sep 9)
            2. Schedule user research sessions - Mike (Due: Sep 5)
            
            Next Steps:
            Team will reconvene next week to review technical specifications.
            """,
            status: .completed
        ),
        onRetry: {},
        onToggleActionItem: { _ in },
        onSeek: { _ in }
    )
    .frame(width: 600)
    .padding()
}
