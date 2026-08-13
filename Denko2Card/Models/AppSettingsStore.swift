import Foundation
import Observation

/// 試験日・1日の学習枚数などのユーザー設定（UserDefaults永続化）。
/// spec-v1.0.md §画面構成4「設定」
@MainActor
@Observable
final class AppSettingsStore {
    private let defaults: UserDefaults
    private static let examDateKey = "denko2.examDate"
    private static let studiedTodayCountKey = "denko2.studiedTodayCount"
    private static let studiedTodayDateKey = "denko2.studiedTodayDate"
    private static let streakCountKey = "denko2.streakCount"
    private static let lastStudyDateKey = "denko2.lastStudyDate"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var examDate: Date? {
        get { defaults.object(forKey: Self.examDateKey) as? Date }
        set { defaults.set(newValue, forKey: Self.examDateKey) }
    }

    var daysUntilExam: Int? {
        guard let examDate else { return nil }
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: examDate)
        return Calendar.current.dateComponents([.day], from: start, to: end).day
    }

    /// 本日すでに学習した枚数（日付が変わったら自動的に0にリセットされる）
    var studiedTodayCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        if let storedDate = defaults.object(forKey: Self.studiedTodayDateKey) as? Date,
           Calendar.current.isDate(storedDate, inSameDayAs: today) {
            return defaults.integer(forKey: Self.studiedTodayCountKey)
        }
        return 0
    }

    func incrementStudiedToday() {
        let today = Calendar.current.startOfDay(for: Date())
        let current = studiedTodayCount
        defaults.set(current + 1, forKey: Self.studiedTodayCountKey)
        defaults.set(today, forKey: Self.studiedTodayDateKey)
    }

    /// 連続学習日数。学習した日に1度呼ぶ。
    var streakCount: Int { defaults.integer(forKey: Self.streakCountKey) }

    func recordStudyDayIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = defaults.object(forKey: Self.lastStudyDateKey) as? Date
        if let lastDate, Calendar.current.isDate(lastDate, inSameDayAs: today) {
            return // 本日すでに記録済み
        }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)
        let continuing = lastDate.map { Calendar.current.isDate($0, inSameDayAs: yesterday ?? today) } ?? false
        let newStreak = continuing ? streakCount + 1 : 1
        defaults.set(newStreak, forKey: Self.streakCountKey)
        defaults.set(today, forKey: Self.lastStudyDateKey)
    }
}
