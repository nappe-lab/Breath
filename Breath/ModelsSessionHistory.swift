//
//  SessionHistory.swift
//  Breath
//

import Foundation
import SwiftData

/// A completed breathing session, stored in SwiftData
@Model
final class SessionHistory {
    var id: UUID
    var exerciseName: String
    var duration: TimeInterval // actual duration in seconds
    var completedAt: Date
    var cyclesCompleted: Int
    
    init(exerciseName: String, duration: TimeInterval, completedAt: Date = .now, cyclesCompleted: Int) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.duration = duration
        self.completedAt = completedAt
        self.cyclesCompleted = cyclesCompleted
    }
    
    /// Formatted duration string (e.g. "5m 23s")
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: completedAt)
    }
}
