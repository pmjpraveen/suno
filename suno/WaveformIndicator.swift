//
//  WaveformIndicator.swift
//  suno
//

import SwiftUI

/// Animated bars shown while actively recording.
struct WaveformIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var barHeights: [CGFloat] = [0.3, 0.5, 0.8, 0.4, 0.6]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(.primary.opacity(0.7))
                    .frame(width: 3, height: 20 * barHeights[index])
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            animateBars()
        }
    }

    private func animateBars() {
        for index in 0..<5 {
            withAnimation(
                .easeInOut(duration: Double.random(in: 0.3...0.6))
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.1)
            ) {
                barHeights[index] = CGFloat.random(in: 0.3...1.0)
            }
        }
    }
}
