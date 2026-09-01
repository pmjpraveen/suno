//
//  Extensions.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import Foundation
import SwiftUI

// MARK: - URL Extensions

extension URL {
    var fileSize: Int64 {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        return attributes?[.size] as? Int64 ?? 0
    }
}

// MARK: - TimeInterval Extensions

extension TimeInterval {
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
