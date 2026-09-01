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
    private var popover: NSPopover!
    var menuBarManager: MenuBarManager!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock - menu bar only app
        NSApp.setActivationPolicy(.accessory)
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Initialize menu bar manager first
        menuBarManager = MenuBarManager(statusItem: statusItem, popover: nil)
        
        // Setup popover with SwiftUI content
        setupPopover()
        
        // Connect popover to menu bar manager
        menuBarManager.popover = popover
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 350, height: 500)
        popover.behavior = .transient // Close when clicking outside
        popover.contentViewController = NSHostingController(
            rootView: PopoverContentView()
                .environmentObject(menuBarManager)
        )
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup if needed
    }
}
