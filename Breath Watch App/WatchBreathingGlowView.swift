//
//  WatchBreathingGlowView.swift
//  Breath Watch App
//
//  A watchOS-scaled port of the iPhone app's BreathingGlowView (see
//  BreathingGlowView.swift in the Breath target). Same idea - concentric
//  radial-gradient halos plus a core dot that expand/brighten on inhale and
//  contract/dim on exhale - just smaller radii and one fewer halo layer to
//  suit the watch's tiny screen, and driven by WatchBreathingPhase (from
//  WatchBreathingExercise.swift) instead of the phone's richer PhaseType.

import SwiftUI

struct WatchBreathingGlowView: View {
    let phase: WatchBreathingPhase

    @State private var glowScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.6
    @State private var dotOpacity: Double = 1.0

    var body: some View {
        ZStack {
            ForEach(0..<4) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(haloOpacity(layer: index)),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: haloRadius(layer: index)
                        )
                    )
                    .frame(width: haloRadius(layer: index) * 2, height: haloRadius(layer: index) * 2)
                    .scaleEffect(glowScale)
                    .opacity(glowOpacity)
                    .blur(radius: CGFloat(index) * 1.5)
            }

            // Core dot (stays fixed size, but fades with the breath like the halos)
            Circle()
                .fill(.white)
                .frame(width: 4, height: 4)
                .opacity(dotOpacity)
        }
        .onChange(of: phase) { _, newPhase in
            animateForPhase(newPhase)
        }
        .onAppear {
            animateForPhase(phase)
        }
    }

    private func haloRadius(layer: Int) -> CGFloat {
        // Scaled down from the phone's [20, 40, 70, 110, 160] to fit a watch screen.
        let baseRadii: [CGFloat] = [10, 20, 35, 55]
        return baseRadii[layer]
    }

    private func haloOpacity(layer: Int) -> Double {
        let baseOpacities: [Double] = [0.8, 0.5, 0.3, 0.15]
        return baseOpacities[layer] * glowOpacity
    }

    private func animateForPhase(_ phase: WatchBreathingPhase) {
        let duration = phase.duration
        switch phase.type {
        case .inhale, .doubleInhale:
            // Expand and brighten
            withAnimation(.easeInOut(duration: duration)) {
                glowScale = 1.5
                glowOpacity = 0.8
                dotOpacity = 1.0
            }

        case .holdFull:
            // Stay stable at expanded size
            withAnimation(.easeInOut(duration: 0.5)) {
                glowScale = 1.5
                glowOpacity = 0.7
                dotOpacity = 1.0
            }

        case .exhale:
            // Contract and dim
            withAnimation(.easeInOut(duration: duration)) {
                glowScale = 1.0
                glowOpacity = 0.4
                dotOpacity = 0.15
            }

        case .holdEmpty:
            // Stay stable at contracted size - darkest point, dot almost fully fades out
            withAnimation(.easeInOut(duration: 0.5)) {
                glowScale = 1.0
                glowOpacity = 0.3
                dotOpacity = 0.05
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        WatchBreathingGlowView(phase: WatchBreathingPhase(type: .inhale, duration: 4))
    }
}
