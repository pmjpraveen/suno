//
//  sunoApp.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import SwiftUI

@main
struct sunoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Empty scene - this is a menu bar only app
        Settings {
            EmptyView()
        }
    }
}
