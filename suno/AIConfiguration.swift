//
//  AIConfiguration.swift
//  suno
//

import Foundation

struct AIConfiguration {
    
    // MARK: - API Keys
    
    /// OpenAI API key for development
    /// DO NOT commit production keys to source control
    /// In production, use environment variables or a secure backend proxy
    static var openAIAPIKey: String? {
        // Try to load from environment variable first
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return envKey
        }
        
        // Try to load from local config file (not committed to git)
        if let key = loadFromConfigFile() {
            return key
        }
        
        // Development fallback - replace with your key for local development
        // IMPORTANT: Never commit this with a real key
        return nil  // Set to your dev key or use config file
    }
    
    // MARK: - Service Selection
    
    /// Whether to use Foundation Models (on-device) when available
    static let preferFoundationModels = true
    
    /// Timeout for AI analysis requests (in seconds)
    static let analysisTimeout: TimeInterval = 120
    
    /// Maximum transcript length to analyze (characters)
    static let maxTranscriptLength = 100_000
    
    // MARK: - Privacy
    
    /// Whether to log full transcripts (disable in production)
    static let enableVerboseLogging = false
    
    // MARK: - Config File Loading
    
    private static func loadFromConfigFile() -> String? {
        let fileManager = FileManager.default
        
        // Look for config file in app support directory
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let configURL = appSupport
            .appendingPathComponent("suno")
            .appendingPathComponent("ai-config.json")
        
        guard fileManager.fileExists(atPath: configURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: configURL)
            let config = try JSONDecoder().decode(ConfigFile.self, from: data)
            return config.openAIAPIKey
        } catch {
            print("⚠️ Failed to load AI config file: \(error)")
            return nil
        }
    }
    
    // MARK: - Config File Structure
    
    private struct ConfigFile: Codable {
        let openAIAPIKey: String?
    }
    
    // MARK: - Setup Instructions
    
    static func printSetupInstructions() {
        print("""
        
        ╔════════════════════════════════════════════════════════════════╗
        ║                   AI Analysis Setup Required                   ║
        ╚════════════════════════════════════════════════════════════════╝
        
        To enable AI meeting analysis, you need to configure an API key.
        
        Option 1: Environment Variable (Recommended for development)
        ────────────────────────────────────────────────────────────────
        Set the OPENAI_API_KEY environment variable:
        
        export OPENAI_API_KEY="your-api-key-here"
        
        Option 2: Config File (Recommended for personal use)
        ────────────────────────────────────────────────────────────────
        Create a file at:
        ~/Library/Application Support/suno/ai-config.json
        
        With contents:
        {
          "openAIAPIKey": "your-api-key-here"
        }
        
        Option 3: Production Backend (Recommended for distribution)
        ────────────────────────────────────────────────────────────────
        Implement a secure backend proxy that:
        - Authenticates users
        - Manages API keys server-side
        - Proxies requests to OpenAI
        - Enforces rate limits and usage quotas
        
        ⚠️  IMPORTANT SECURITY NOTES:
        - NEVER hardcode API keys in source code
        - NEVER commit API keys to version control
        - Add ai-config.json to .gitignore
        - Use environment variables or secure storage
        - Consider a backend proxy for production
        
        ═══════════════════════════════════════════════════════════════
        
        """)
    }
}
