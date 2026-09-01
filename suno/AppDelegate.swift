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
    private var menuBarManager: MenuBarManager!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🟢 AppDelegate: applicationDidFinishLaunching started")
        
        // Hide from Dock - menu bar only app
        NSApp.setActivationPolicy(.accessory)
        print("🟢 AppDelegate: Set activation policy to .accessory")
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        print("🟢 AppDelegate: Created status item")
        
        // Create popover first (without content)
        popover = NSPopover()
        popover.contentSize = NSSize(width: 350, height: 500)
        popover.behavior = .transient
        print("🟢 AppDelegate: Created popover")
        
        // Initialize menu bar manager with popover
        menuBarManager = MenuBarManager(statusItem: statusItem, popover: popover)
        print("🟢 AppDelegate: Created MenuBarManager")
        
        // Setup popover content with menu bar manager
        setupPopoverContent()
        print("🟢 AppDelegate: Setup complete!")
    }
    
    private func setupPopoverContent() {
        popover.contentViewController = NSHostingController(
            rootView: PopoverContentView()
                .environmentObject(menuBarManager as MenuBarManager)
        )
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup if needed
    }
}
