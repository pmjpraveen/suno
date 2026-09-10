//
//  FloatingPanel.swift
//  suno
//

import SwiftUI
import AppKit

/// Borderless, non-activating panel for the recording pill — no titlebar, no popover arrow,
/// floats above other windows. Fixed size: letting AppKit renegotiate window size against
/// SwiftUI's own auto-layout on every frame (e.g. during the waveform's looping animation)
/// causes a constraint-solving recursion crash, so the pill's SwiftUI content sizes itself
/// to fit within one constant frame instead.
final class FloatingPanel<Content: View>: NSPanel {
    init(view: Content, size: NSSize) {
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        contentViewController = NSHostingController(rootView: view)
    }

    override var canBecomeKey: Bool { true }
}
