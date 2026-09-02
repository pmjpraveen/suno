//
//  Language.swift
//  suno
//

import Foundation

/// Supported languages for transcription and analysis
enum Language: String, Codable, CaseIterable, Identifiable {
    case auto = "auto"
    
    // Major International Languages
    case english = "en-US"
    case spanish = "es-ES"
    case french = "fr-FR"
    case german = "de-DE"
    case italian = "it-IT"
    case portuguese = "pt-BR"
    case japanese = "ja-JP"
    case korean = "ko-KR"
    case chinese = "zh-CN"
    case russian = "ru-RU"
    case arabic = "ar-SA"
    case dutch = "nl-NL"
    case swedish = "sv-SE"
    case polish = "pl-PL"
    case turkish = "tr-TR"
    case vietnamese = "vi-VN"
    case indonesian = "id-ID"
    case thai = "th-TH"
    case danish = "da-DK"
    case norwegian = "nb-NO"
    case finnish = "fi-FI"
    
    // Indian Languages (in order of speakers)
    case hindi = "hi-IN"          // 528M speakers - National language
    case bengali = "bn-IN"        // 265M speakers - West Bengal, Bangladesh
    case telugu = "te-IN"         // 93M speakers - Andhra Pradesh, Telangana
    case marathi = "mr-IN"        // 83M speakers - Maharashtra
    case tamil = "ta-IN"          // 81M speakers - Tamil Nadu
    case urdu = "ur-IN"           // 70M speakers - Multiple states
    case gujarati = "gu-IN"       // 56M speakers - Gujarat
    case kannada = "kn-IN"        // 44M speakers - Karnataka
    case malayalam = "ml-IN"      // 38M speakers - Kerala
    case punjabi = "pa-IN"        // 33M speakers - Punjab
    case odia = "or-IN"           // 38M speakers - Odisha
    case assamese = "as-IN"       // 15M speakers - Assam
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .auto: return "Auto-Detect"
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .chinese: return "中文"
        case .russian: return "Русский"
        case .arabic: return "العربية"
        case .dutch: return "Nederlands"
        case .swedish: return "Svenska"
        case .polish: return "Polski"
        case .turkish: return "Türkçe"
        case .vietnamese: return "Tiếng Việt"
        case .indonesian: return "Bahasa Indonesia"
        case .thai: return "ไทย"
        case .danish: return "Dansk"
        case .norwegian: return "Norsk"
        case .finnish: return "Suomi"
        
        // Indian Languages
        case .hindi: return "हिन्दी"
        case .bengali: return "বাংলা"
        case .telugu: return "తెలుగు"
        case .marathi: return "मराठी"
        case .tamil: return "தமிழ்"
        case .urdu: return "اردو"
        case .gujarati: return "ગુજરાતી"
        case .kannada: return "ಕನ್ನಡ"
        case .malayalam: return "മലയാളം"
        case .punjabi: return "ਪੰਜਾਬੀ"
        case .odia: return "ଓଡ଼ିଆ"
        case .assamese: return "অসমীয়া"
        }
    }
    
    var nativeDisplayName: String {
        "\(flag) \(displayName)"
    }
    
    var flag: String {
        switch self {
        case .auto: return "🌐"
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .italian: return "🇮🇹"
        case .portuguese: return "🇧🇷"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .chinese: return "🇨🇳"
        case .russian: return "🇷🇺"
        case .arabic: return "🇸🇦"
        case .dutch: return "🇳🇱"
        case .swedish: return "🇸🇪"
        case .polish: return "🇵🇱"
        case .turkish: return "🇹🇷"
        case .vietnamese: return "🇻🇳"
        case .indonesian: return "🇮🇩"
        case .thai: return "🇹🇭"
        case .danish: return "🇩🇰"
        case .norwegian: return "🇳🇴"
        case .finnish: return "🇫🇮"
        
        // Indian Languages - all use 🇮🇳 flag
        case .hindi, .bengali, .telugu, .marathi, .tamil,
             .urdu, .gujarati, .kannada, .malayalam, .punjabi,
             .odia, .assamese:
            return "🇮🇳"
        }
    }
    
    /// Detailed description with state/region info
    var detailedDescription: String {
        switch self {
        case .hindi: return "हिन्दी (Hindi) - National"
        case .bengali: return "বাংলা (Bengali) - West Bengal"
        case .telugu: return "తెలుగు (Telugu) - Andhra Pradesh, Telangana"
        case .marathi: return "मराठी (Marathi) - Maharashtra"
        case .tamil: return "தமிழ் (Tamil) - Tamil Nadu"
        case .urdu: return "اردو (Urdu) - Multiple States"
        case .gujarati: return "ગુજરાતી (Gujarati) - Gujarat"
        case .kannada: return "ಕನ್ನಡ (Kannada) - Karnataka"
        case .malayalam: return "മലയാളം (Malayalam) - Kerala"
        case .punjabi: return "ਪੰਜਾਬੀ (Punjabi) - Punjab"
        case .odia: return "ଓଡ଼ିଆ (Odia) - Odisha"
        case .assamese: return "অসমীয়া (Assamese) - Assam"
        default: return displayName
        }
    }
    
    /// Apple Speech Framework locale identifier
    var locale: Locale? {
        guard self != .auto else { return nil }
        return Locale(identifier: rawValue)
    }
    
    /// ISO 639-1 language code for APIs
    var languageCode: String? {
        switch self {
        case .auto: return nil
        case .english: return "en"
        case .spanish: return "es"
        case .french: return "fr"
        case .german: return "de"
        case .italian: return "it"
        case .portuguese: return "pt"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .chinese: return "zh"
        case .russian: return "ru"
        case .arabic: return "ar"
        case .hindi: return "hi"
        case .dutch: return "nl"
        case .swedish: return "sv"
        case .polish: return "pl"
        case .turkish: return "tr"
        case .vietnamese: return "vi"
        case .indonesian: return "id"
        case .thai: return "th"
        case .danish: return "da"
        case .norwegian: return "nb"
        case .finnish: return "fi"
        
        // Indian Languages
        case .tamil: return "ta"
        case .telugu: return "te"
        case .bengali: return "bn"
        case .marathi: return "mr"
        case .gujarati: return "gu"
        case .kannada: return "kn"
        case .malayalam: return "ml"
        case .punjabi: return "pa"
        case .urdu: return "ur"
        case .odia: return "or"
        case .assamese: return "as"
        }
    }
    
    /// Check if this language is supported by Apple Speech Recognition
    /// Note: Availability may vary by macOS version
    var isSupportedByAppleSpeech: Bool {
        switch self {
        case .auto, .english, .spanish, .french, .german, .italian, .portuguese,
             .japanese, .korean, .chinese, .russian, .arabic, .dutch, .swedish,
             .turkish, .danish, .norwegian, .finnish:
            return true
            
        // Indian languages - limited support, may require network
        case .hindi:
            return true  // Available on macOS 13+
            
        case .tamil, .telugu, .marathi, .gujarati, .kannada, .malayalam,
             .punjabi, .bengali, .urdu, .odia, .assamese:
            // These may be available depending on macOS version and network
            // Best to try and fallback gracefully
            return false  // Mark as requiring verification
            
        case .polish, .vietnamese, .indonesian, .thai:
            return false  // May vary by macOS version
        }
    }
    
    /// Popular languages for quick selection
    static var popular: [Language] {
        [.auto, .english, .hindi, .spanish, .french, .german, .chinese, .japanese, .korean]
    }
    
    /// Indian languages for dedicated section
    static var indianLanguages: [Language] {
        [.hindi, .bengali, .telugu, .marathi, .tamil, .urdu, .gujarati, .kannada, .malayalam, .punjabi, .odia, .assamese]
    }
    
    /// All languages except auto
    static var allLanguages: [Language] {
        allCases.filter { $0 != .auto }
    }
    
    /// Group languages by region
    static var internationalLanguages: [Language] {
        [.english, .spanish, .french, .german, .italian, .portuguese, .japanese, .korean, .chinese, .russian, .arabic, .dutch, .swedish, .polish, .turkish, .vietnamese, .indonesian, .thai, .danish, .norwegian, .finnish]
    }
}
