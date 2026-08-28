//
//  WatchPatternPickerView.swift
//  Breath Watch App
//
//  A watch-scaled version of the iPhone app's ExerciseLibraryView (see
//  ExerciseLibraryView.swift in the Breath target) - a plain List is the idiomatic watchOS
//  pattern for this kind of picker, rather than porting the phone's card layout.

import SwiftUI

struct WatchPatternPickerView: View {
    @Binding var selection: WatchBreathingExercise
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(WatchBreathingExercise.library, id: \.id) { exercise in
                row(for: exercise)
            }
        }
        .navigationTitle("Pattern")
    }

    @ViewBuilder
    private func row(for exercise: WatchBreathingExercise) -> some View {
        let isSelected = exercise == selection

        Button {
            selection = exercise
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.system(size: 15))
                    Text(exercise.patternString)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        WatchPatternPickerView(selection: .constant(.boxBreathing))
    }
}
