//
//  BreathApp.swift
//  Breath
//

import SwiftUI
import SwiftData

@main
struct BreathApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: SessionHistory.self)
    }
}
