//
//  PressableButtonStyle.swift
//  suno
//

import SwiftUI

/// Instant press feedback — scales down the moment the pointer goes down, not on release.
/// Critically damped (no overshoot) since the press itself carries no momentum.
/// Falls back to a plain opacity dim when Reduce Motion is on.
struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.96 : 1))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 1.0), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}
