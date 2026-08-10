//
//  SessionCompleteView.swift
//  Breath
//

import SwiftUI

struct SessionCompleteView: View {
    let exerciseName: String
    let duration: TimeInterval
    let cycles: Int
    let onStartAgain: () -> Void
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                Image(systemName: "checkmark.circle")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.8))

                VStack(spacing: 16) {
                    Text("Session Complete")
                        .font(.garamond(28, weight: .medium))
                        .foregroundStyle(.white)

                    VStack(spacing: 8) {
                        Text(exerciseName)
                            .font(.garamond(20))
                            .foregroundStyle(.white.opacity(0.75))

                        Text(formattedDuration)
                            .font(.jbMono(16))
                            .foregroundStyle(.white.opacity(0.65))

                        Text("\(cycles) cycle\(cycles == 1 ? "" : "s")")
                            .font(.jbMono(13))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }

                Spacer()

                VStack(spacing: 16) {
                    Button {
                        onStartAgain()
                    } label: {
                        Text("Start Again")
                            .font(.inter(16, weight: .medium))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white)
                            )
                    }

                    Button {
                        onDone()
                    } label: {
                        Text("Done")
                            .font(.inter(16))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.25), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .interactiveDismissDisabled()
    }

    private var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

#Preview {
    SessionCompleteView(
        exerciseName: "Box Breathing",
        duration: 305,
        cycles: 4,
        onStartAgain: {},
        onDone: {}
    )
}
