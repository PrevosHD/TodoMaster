//
//  PrioritySlider.swift
//  TodoMaster
//

import SwiftUI

/// Optionaler Prioritätswert von 1 bis 5 in Viertelschritten. Das X links steht für keine Priorität.
struct PrioritySlider: View {
    @Binding var priority: Double?

    private static let neutralValue: Double = 3

    private var sliderValue: Binding<Double> {
        Binding(
            get: { priority ?? Self.neutralValue },
            set: { priority = $0 }
        )
    }

    private var tint: Color {
        priority.map { PriorityLevel.color(for: PriorityLevel.bucket($0)) } ?? .secondary
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                priority = nil
            } label: {
                Image(systemName: priority == nil ? "xmark.circle.fill" : "xmark.circle")
                    .font(.title2)
                    .foregroundStyle(priority == nil ? Color.primary : Color.secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .accessibilityLabel("Keine Priorität")

            VStack(spacing: 2) {
                Slider(value: sliderValue, in: PriorityLevel.range, step: PriorityLevel.step) { editing in
                    if editing, priority == nil {
                        priority = Self.neutralValue
                    }
                }
                .tint(tint)
                .opacity(priority == nil ? 0.45 : 1)
                .accessibilityValue(priority.map { "Priorität \(PriorityLevel.format($0))" } ?? "Keine Priorität")

                HStack(spacing: 0) {
                    ForEach(PriorityLevel.levels, id: \.self) { level in
                        Text("\(level)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(PriorityLevel.color(for: level))
                            .frame(width: 14)
                        if level != PriorityLevel.levels.last {
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.horizontal, 7)
                .accessibilityHidden(true)

                Text(priority.map { "Priorität \(PriorityLevel.format($0))" } ?? "Keine Priorität")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
    }
}

#Preview {
    struct Wrapper: View {
        @State var priority: Double? = 2.25
        var body: some View {
            PrioritySlider(priority: $priority).padding()
        }
    }
    return Wrapper()
}
