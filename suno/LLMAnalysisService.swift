//
//  LLMAnalysisService.swift
//  suno
//

import Foundation

/// Implementation of AI analysis using Apple's Foundation Models (on-device LLM)
/// Falls back to OpenAI if Foundation Models are unavailable
class LLMAnalysisService: AIAnalysisService {
    
    private let useFoundationModels: Bool
    private let apiKey: String?
    
    init(useFoundationModels: Bool = true, apiKey: String? = nil) {
        self.useFoundationModels = useFoundationModels
        self.apiKey = apiKey
    }
    
    // MARK: - AIAnalysisService
    
    func checkAvailability() async -> Bool {
        if useFoundationModels {
            return await checkFoundationModelsAvailability()
        } else {
            return apiKey != nil && !apiKey!.isEmpty
        }
    }
    
    func analyzeTranscript(
        _ transcript: Transcript,
        meeting: Meeting?
    ) async throws -> AIAnalysisResponse {
        
        // Validate transcript
        guard !transcript.fullText.isEmpty else {
            throw AIAnalysisError.emptyTranscript
        }
        
        guard transcript.status == .completed else {
            throw AIAnalysisError.invalidTranscript
        }
        
        print("🧠 Starting AI analysis for transcript: \(transcript.id)")
        
        if useFoundationModels {
            return try await analyzeWithFoundationModels(transcript: transcript, meeting: meeting)
        } else {
            return try await analyzeWithOpenAI(transcript: transcript, meeting: meeting)
        }
    }
    
    // MARK: - Foundation Models (On-Device)
    
    @available(macOS 15.0, *)
    private func analyzeWithFoundationModels(
        transcript: Transcript,
        meeting: Meeting?
    ) async throws -> AIAnalysisResponse {
        
        #if compiler(>=6.0)
        // Check availability at runtime
        guard #available(macOS 15.0, *) else {
            throw AIAnalysisError.serviceUnavailable
        }
        
        // Import FoundationModels framework
        // Note: This requires macOS 15+ and appropriate entitlements
        do {
            // For now, we'll use a simulated response since Foundation Models
            // API details may vary. In production, use the actual API:
            //
            // import FoundationModels
            // let model = try await LanguageModel.load()
            // let response = try await model.generate(prompt: userPrompt)
            
            print("⚠️ Foundation Models not yet implemented - using fallback")
            return try await analyzeWithOpenAI(transcript: transcript, meeting: meeting)
            
        } catch {
            print("❌ Foundation Models error: \(error.localizedDescription)")
            throw AIAnalysisError.apiError(error.localizedDescription)
        }
        #else
        // Compiler doesn't support Foundation Models
        throw AIAnalysisError.serviceUnavailable
        #endif
    }
    
    private func checkFoundationModelsAvailability() async -> Bool {
        if #available(macOS 15.0, *) {
            // In production, check if Foundation Models are available
            // For now, return false to use OpenAI fallback
            return false
        }
        return false
    }
    
    // MARK: - OpenAI API (Fallback)
    
    private func analyzeWithOpenAI(
        transcript: Transcript,
        meeting: Meeting?
    ) async throws -> AIAnalysisResponse {
        
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AIAnalysisError.serviceUnavailable
        }
        
        print("🌐 Using OpenAI API for analysis")
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemMessage = MeetingAnalysisPrompt.systemPrompt
        let userMessage = MeetingAnalysisPrompt.createUserPrompt(
            transcript: transcript,
            meeting: meeting
        )
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",  // Using GPT-4o for better structured output
            "messages": [
                ["role": "system", "content": systemMessage],
                ["role": "user", "content": userMessage]
            ],
            "response_format": ["type": "json_object"],  // Force JSON output
            "temperature": 0.3,  // Lower temperature for more consistent output
            "max_tokens": 4000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIAnalysisError.networkError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ OpenAI API error (\(httpResponse.statusCode)): \(errorMessage)")
            throw AIAnalysisError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
        }
        
        // Parse OpenAI response
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let contentString = openAIResponse.choices.first?.message.content else {
            throw AIAnalysisError.decodingError("No content in response")
        }
        
        // Parse the JSON content
        guard let contentData = contentString.data(using: .utf8) else {
            throw AIAnalysisError.decodingError("Could not convert content to data")
        }
        
        let analysisResponse = try JSONDecoder().decode(AIAnalysisResponse.self, from: contentData)
        
        print("✅ AI analysis completed successfully")
        return analysisResponse
    }
    
    // MARK: - OpenAI Response Models
    
    private struct OpenAIResponse: Codable {
        let choices: [Choice]
        
        struct Choice: Codable {
            let message: Message
        }
        
        struct Message: Codable {
            let content: String
        }
    }
}
