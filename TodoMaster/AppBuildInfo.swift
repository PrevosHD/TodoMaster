//
//  AppBuildInfo.swift
//  TodoMaster
//

import Foundation

enum AppBuildInfo {
    /// Calendar day of this build. The footer is vYEAR.MONTH.DAY-REVISION.
    static let year = 2026
    static let month = 10
    static let day = 10

    /// Same-day revision. The first change of a day is 1, the next is 2, and so on.
    static let revision = 5

    static var versionFooter: String {
        "v\(year).\(month).\(day)-\(revision)"
    }
}
