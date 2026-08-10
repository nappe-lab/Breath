//
//  HomeView.swift
//  Breath
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var settings = AppSettings()
    @State private var showingExercisePicker = false
    @State private var showingSession = false
    @State private var showingHistory = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    // Exercise info
                    VStack(spacing: 10) {
                        Text(settings.defaultExercise.name)
                            .font(.garamond(26, weight: .medium))
                            .foregroundStyle(.white)

                        Text("\(settings.defaultDurationMinutes) minutes")
                            .font(.inter(15))
                            .foregroundStyle(.white.opacity(0.55))

                        Text(settings.defaultExercise.patternString)
                            .font(.jbMono(13))
                            .foregroundStyle(.white.opacity(0.35))
                    }

                    Spacer()

                    // Start button — minimal ring
                    Button {
                        showingSession = true
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(.white.opacity(0.12), lineWidth: 1)
                                .frame(width: 200, height: 200)

                            Circle()
                                .stroke(.white.opacity(0.07), lineWidth: 1)
                                .frame(width: 172, height: 172)

                            Text("Begin")
                                .font(.garamond(22))
                                .foregroundStyle(.white.opacity(0.75))
                                .tracking(4)
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Change exercise link
                    Button {
                        showingExercisePicker = true
                    } label: {
                        Text("Change exercise")
                            .font(.inter(14))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.bottom, 40)
                }
                .padding()
            }
            .navigationDestination(isPresented: $showingSession) {
                SessionView(
                    exercise: settings.defaultExercise,
                    durationMinutes: settings.defaultDurationMinutes,
                    hapticIntensity: settings.hapticIntensityMultiplier
                )
            }
            .navigationDestination(isPresented: $showingHistory) {
                HistoryView()
            }
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView(settings: settings)
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExerciseLibraryView(settings: settings)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingHistory = true
                        } label: {
                            Label("History", systemImage: "clock")
                        }
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: SessionHistory.self)
}
