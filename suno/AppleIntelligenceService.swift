//
//  AppleIntelligenceService.swift
//  suno
//
//  Implementation using Apple's on-device Foundation Models (Apple Intelligence)
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// AI Analysis service using Apple's on-device Foundation Models
/// Falls back to basic analysis if Foundation Models are unavailable
@available(macOS 15.0, *)
class AppleIntelligenceService {
    
    // MARK: - Properties
    
    private var model: SystemLanguageModel {
        SystemLanguageModel.default
    }
    
    // MARK: - Analysis
    
    func checkAvailability() async -> Bool {
        #if canImport(FoundationModels)
        // Check if Foundation Models are available
        switch model.availability {
        case .available:
            print("✅ Apple Intelligence is available")
            return true
        case .unavailable(let reason):
            print("⚠️ Apple Intelligence unavailable: \(reason)")
            return false
        }
        #else
        print("⚠️ FoundationModels framework not available")
        return false
        #endif
    }
    
    func analyzeTranscript(
        _ transcript: Transcript,
        meeting: Meeting?
    ) async throws -> AIAnalysisResponse {
        
        #if canImport(FoundationModels)
        // Validate transcript
        guard !transcript.fullText.isEmpty else {
            throw AIAnalysisError.emptyTranscript
        }
        
        guard transcript.status == .completed else {
            throw AIAnalysisError.invalidTranscript
        }
        
        // Check model availability
        switch model.availability {
        case .available:
            break
        case .unavailable(.deviceNotEligible):
            throw AIAnalysisError.serviceUnavailable
        case .unavailable(.appleIntelligenceNotEnabled):
            throw AIAnalysisError.aiNotEnabled
        case .unavailable(.modelNotReady):
            throw AIAnalysisError.modelNotReady
        case .unavailable:
            throw AIAnalysisError.serviceUnavailable
        }
        
        print("🧠 Starting Apple Intelligence analysis for transcript: \(transcript.id)")
        
        // Create session with instructions
        let instructions = MeetingAnalysisPrompt.systemPrompt
        let session = LanguageModelSession(instructions: instructions)
        
        // Create user prompt
        let prompt = MeetingAnalysisPrompt.createUserPrompt(
            transcript: transcript,
            meeting: meeting
        )
        
        do {
            // Generate response using guided generation
            let response = try await session.respond(
                to: prompt,
                generating: MeetingAnalysisOutput.self
            )
            
            // Convert to AIAnalysisResponse
            let analysisResponse = response.content.toAIAnalysisResponse()
            
            print("✅ Apple Intelligence analysis complete!")
            return analysisResponse
            
        } catch let error as LanguageModelSession.GenerationError {
            print("❌ Apple Intelligence error: \(error)")
            throw handleGenerationError(error)
        } catch {
            print("❌ Unexpected error: \(error)")
            throw AIAnalysisError.apiError(error.localizedDescription)
        }
        #else
        throw AIAnalysisError.serviceUnavailable
        #endif
    }
    
    // MARK: - Error Handling
    
    #if canImport(FoundationModels)
    private func handleGenerationError(_ error: LanguageModelSession.GenerationError) -> AIAnalysisError {
        switch error {
        case .exceededContextWindowSize:
            return .transcriptTooLong
        @unknown default:
            return .apiError("Generation error: \(error.localizedDescription)")
        }
    }
    #endif
}

// MARK: - Guided Generation Types

#if canImport(FoundationModels)
@available(macOS 15.0, *)
@Generable(description: "Structured analysis of a meeting transcript")
struct MeetingAnalysisOutput {
    
    @Guide(description: "A concise 2-3 sentence summary of the meeting")
    var overview: String
    
    @Guide(description: "Key discussion points from the meeting", .count(3...10))
    var keyPoints: [String]
    
    @Guide(description: "Decisions that were made during the meeting")
    var decisions: [MeetingDecision]
    
    @Guide(description: "Action items extracted from the meeting")
    var actionItems: [MeetingActionItem]
    
    @Guide(description: "Formal minutes of meeting document")
    var mom: String
    
    // Convert to AIAnalysisResponse
    func toAIAnalysisResponse() -> AIAnalysisResponse {
        return AIAnalysisResponse(
            overview: overview,
            keyPoints: keyPoints,
            decisions: decisions.map { $0.toAIDecision() },
            actionItems: actionItems.map { $0.toAIActionItem() },
            mom: mom
        )
    }
}

@available(macOS 15.0, *)
@Generable(description: "A decision made during the meeting")
struct MeetingDecision {
    
    @Guide(description: "The specific decision that was made")
    var text: String
    
    @Guide(description: "Timestamp in seconds from the start of the recording")
    var timestamp: Double?
    
    func toAIDecision() -> AIAnalysisResponse.AIDecision {
        return AIAnalysisResponse.AIDecision(
            text: text,
            timestamp: timestamp
        )
    }
}

@available(macOS 15.0, *)
@Generable(description: "An action item extracted from the meeting")
struct MeetingActionItem {
    
    @Guide(description: "The specific task to be completed")
    var task: String
    
    @Guide(description: "The person assigned to this task, only if explicitly mentioned")
    var assignee: String?
    
    @Guide(description: "The due date in ISO8601 format (YYYY-MM-DD), only if explicitly mentioned")
    var dueDate: String?
    
    @Guide(description: "Timestamp in seconds from the start of the recording")
    var timestamp: Double?
    
    func toAIActionItem() -> AIAnalysisResponse.AIActionItem {
        return AIAnalysisResponse.AIActionItem(
            task: task,
            assignee: assignee,
            dueDate: dueDate,
            timestamp: timestamp
        )
    }
}
#endif

// MARK: - AIAnalysisError Extensions

extension AIAnalysisError {
    static let aiNotEnabled = AIAnalysisError.serviceUnavailable
    static let modelNotReady = AIAnalysisError.apiError("Model is downloading or not ready")
    static let transcriptTooLong = AIAnalysisError.apiError("Transcript exceeds maximum length (4,096 tokens)")
}
