//
//  AppDelegate.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menuBarManager: MenuBarManager!
    private let viewModel = RecordingViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock - menu bar only app
        NSApp.setActivationPolicy(.accessory)

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Owns the recording pill panel plus the Recordings/Settings windows
        menuBarManager = MenuBarManager(statusItem: statusItem, viewModel: viewModel)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup if needed
    }
}
