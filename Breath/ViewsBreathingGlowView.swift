//
//  BreathingGlowView.swift
//  Breath
//

import SwiftUI

/// The animated radial glow that responds to breathing phases
struct BreathingGlowView: View {
    let phase: PhaseType

    // Animation parameters
    @State private var glowScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.6
    @State private var dotOpacity: Double = 1.0
    
    var body: some View {
        ZStack {
            // Multiple layers of halos for depth
            ForEach(0..<5) { index in
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
                    .blur(radius: CGFloat(index) * 3)
            }
            
            // Core dot (stays fixed size, but fades with the breath like the halos)
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)
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
        // Base radii for each layer
        let baseRadii: [CGFloat] = [20, 40, 70, 110, 160]
        return baseRadii[layer]
    }
    
    private func haloOpacity(layer: Int) -> Double {
        // Opacity decreases with each outer layer
        let baseOpacities: [Double] = [0.8, 0.5, 0.3, 0.15, 0.08]
        return baseOpacities[layer] * glowOpacity
    }
    
    private func animateForPhase(_ phaseType: PhaseType) {
        switch phaseType {
        case .inhale, .doubleInhale:
            // Expand and brighten
            withAnimation(.easeInOut(duration: currentPhaseDuration)) {
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
            withAnimation(.easeInOut(duration: currentPhaseDuration)) {
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
    
    private var currentPhaseDuration: TimeInterval {
        // This is approximate - in a real app you'd pass the actual phase duration
        // For now, we use reasonable defaults
        switch phase {
        case .inhale: return 4.0
        case .holdFull: return 4.0
        case .exhale: return 4.0
        case .holdEmpty: return 4.0
        case .doubleInhale: return 2.0
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "#080808").ignoresSafeArea()
        
        BreathingGlowView(phase: .inhale)
    }
}
