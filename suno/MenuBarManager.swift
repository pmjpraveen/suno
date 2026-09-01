//
//  MenuBarManager.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import AppKit
import SwiftUI
import Combine

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    
    @Published var recordingState: RecordingState = .idle {
        didSet {
            updateStatusBarIcon()
        }
    }
    
    init(statusItem: NSStatusItem, popover: NSPopover) {
        self.statusItem = statusItem
        self.popover = popover
        
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        if let button = statusItem.button {
            updateStatusBarIcon()
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    private func updateStatusBarIcon() {
        guard let button = statusItem.button else { return }
        
        // Update icon based on recording state
        let iconConfig = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        
        switch recordingState {
        case .idle:
            let image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "Idle")
            image?.isTemplate = true
            button.image = image?.withSymbolConfiguration(iconConfig)
            button.contentTintColor = .gray
            
        case .recording:
            let image = NSImage(systemSymbolName: "record.circle.fill", accessibilityDescription: "Recording")
            image?.isTemplate = true
            button.image = image?.withSymbolConfiguration(iconConfig)
            button.contentTintColor = .systemRed
            
        case .paused:
            let image = NSImage(systemSymbolName: "pause.circle.fill", accessibilityDescription: "Paused")
            image?.isTemplate = true
            button.image = image?.withSymbolConfiguration(iconConfig)
            button.contentTintColor = .systemYellow
            
        case .stopped:
            let image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "Stopped")
            image?.isTemplate = true
            button.image = image?.withSymbolConfiguration(iconConfig)
            button.contentTintColor = .gray
        }
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        print("🔵 togglePopover called!")
        guard let button = statusItem.button else {
            print("❌ No status button found")
            return
        }
        
        print("🔵 Button found, event type: \(String(describing: NSApp.currentEvent?.type))")
        
        // Check if it's a right-click
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            print("🔵 Right click detected, showing context menu")
            showContextMenu()
            return
        }
        
        // Toggle popover on left click
        print("🔵 Popover isShown: \(popover.isShown)")
        if popover.isShown {
            print("🔵 Closing popover")
            popover.performClose(sender)
        } else {
            print("🔵 Opening popover")
            print("🔵 Popover has content view: \(popover.contentViewController != nil)")
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Activate app to receive keyboard events
            NSApp.activate(ignoringOtherApps: true)
            print("🔵 Popover shown, isShown now: \(popover.isShown)")
        }
    }
    
    private func showContextMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Quit Suno", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        
        // Remove menu after showing (so left-click still works)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.statusItem.menu = nil
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    func closePopover() {
        popover.performClose(nil)
    }
}
