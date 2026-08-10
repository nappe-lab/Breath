//
//  HistoryView.swift
//  Breath
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \SessionHistory.completedAt, order: .reverse)
    private var sessions: [SessionHistory]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if sessions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.25))

                    Text("No sessions yet")
                        .font(.garamond(22, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))

                    Text("Complete a breathing session to see it here")
                        .font(.inter(15))
                        .foregroundStyle(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sessions) { session in
                            HistoryRow(session: session)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct HistoryRow: View {
    let session: SessionHistory

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "circle.circle")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 5) {
                Text(session.exerciseName)
                    .font(.garamond(19, weight: .medium))
                    .foregroundStyle(.white)

                Text(session.formattedDate)
                    .font(.inter(13))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text(session.formattedDuration)
                    .font(.jbMono(15))
                    .foregroundStyle(.white.opacity(0.9))

                Text("\(session.cyclesCompleted) cycles")
                    .font(.jbMono(12))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.05))
        )
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: SessionHistory.self)
}
