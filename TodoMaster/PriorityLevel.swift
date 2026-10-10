//
//  PriorityLevel.swift
//  TodoMaster
//

import SwiftUI

enum PriorityLevel {
    static let range: ClosedRange<Double> = 1...5
    static let step: Double = 0.25
    static let levels = [1, 2, 3, 4, 5]

    /// 1,00–1,49 → 1, 1,50–2,49 → 2, … 4,50–5,00 → 5
    static func bucket(_ value: Double) -> Int {
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        return Int((clamped + 0.5).rounded(.down)).clamped(to: 1...5)
    }

    static func color(for level: Int) -> Color {
        switch level {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        default: return .blue
        }
    }

    static func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).locale(Locale(identifier: "de_DE")))
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
