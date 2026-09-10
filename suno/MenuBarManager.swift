//
//  MenuBarManager.swift
//  suno
//

import AppKit
import SwiftUI
import Combine

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem
    let viewModel: RecordingViewModel

    private var panel: FloatingPanel<AnyView>?
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    private var recordingsWindow: NSWindow?
    private var settingsWindow: NSWindow?

    @Published var recordingState: RecordingState = .idle {
        didSet {
            updateStatusBarIcon()
        }
    }

    init(statusItem: NSStatusItem, viewModel: RecordingViewModel) {
        self.statusItem = statusItem
        self.viewModel = viewModel

        setupStatusItem()
        // Create eagerly (kept hidden) so its `.onChange(of: recordingState)` keeps the
        // status bar icon in sync even before the pill has ever been opened.
        panel = makePanel()
    }

    private func setupStatusItem() {
        if let button = statusItem.button {
            updateStatusBarIcon()
            button.action = #selector(handleStatusItemClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func updateStatusBarIcon() {
        guard let button = statusItem.button else { return }

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

    // MARK: - Pill Panel

    @objc private func handleStatusItemClick(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp || (event.type == .leftMouseUp && event.modifierFlags.contains(.control)) {
            showContextMenu()
            return
        }

        togglePanel()
    }

    private func togglePanel() {
        if let panel, panel.isVisible {
            closePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard let button = statusItem.button, let buttonWindow = button.window, let panel else { return }

        let buttonFrameOnScreen = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let size = panel.frame.size
        let origin = NSPoint(
            x: buttonFrameOnScreen.midX - size.width / 2,
            y: buttonFrameOnScreen.minY - size.height - 6
        )
        panel.setFrameOrigin(origin)

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        startMonitoringOutsideClicks()
    }

    private func closePanel() {
        panel?.orderOut(nil)
        stopMonitoringOutsideClicks()
    }

    private func makePanel() -> FloatingPanel<AnyView> {
        let content = AnyView(
            RecordingPillView(viewModel: viewModel)
                .environmentObject(self)
        )
        return FloatingPanel(view: content, size: NSSize(width: 240, height: 52))
    }

    private func startMonitoringOutsideClicks() {
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePanel()
        }
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, let panel = self.panel, event.window !== panel else { return event }
            self.closePanel()
            return event
        }
    }

    private func stopMonitoringOutsideClicks() {
        if let monitor = globalClickMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = localClickMonitor { NSEvent.removeMonitor(monitor) }
        globalClickMonitor = nil
        localClickMonitor = nil
    }

    // MARK: - Secondary Windows

    func showRecordings() {
        closePanel()
        if recordingsWindow == nil {
            let hosting = NSHostingController(rootView: RecordingListView(viewModel: viewModel))
            let window = NSWindow(contentViewController: hosting)
            window.title = "Recordings"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: 420, height: 520))
            window.center()
            window.isReleasedWhenClosed = false
            recordingsWindow = window
        }
        recordingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showSettings() {
        closePanel()
        if settingsWindow == nil {
            let hosting = NSHostingController(rootView: SettingsWindowView(viewModel: viewModel))
            let window = NSWindow(contentViewController: hosting)
            window.title = "Settings"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.setContentSize(NSSize(width: 380, height: 460))
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Context Menu

    private func showContextMenu() {
        let menu = NSMenu()

        if !AXIsProcessTrusted() {
            let accessibilityItem = NSMenuItem(title: "⚠️ Grant Accessibility Permission", action: #selector(requestAccessibility), keyEquivalent: "")
            accessibilityItem.target = self
            menu.addItem(accessibilityItem)
            menu.addItem(NSMenuItem.separator())
        }

        let quitItem = NSMenuItem(title: "Quit Suno", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    @objc private func requestAccessibility() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "Suno needs Accessibility permission to detect when you join meetings in Zoom, Teams, or Google Meet.\n\nClick OK to open System Settings, then:\n1. Find 'Suno' in the list\n2. Check the box next to it\n3. Restart Suno"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
