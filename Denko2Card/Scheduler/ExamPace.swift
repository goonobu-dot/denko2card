import Foundation

/// 試験日ペース判定・詰め込みモード切替（spec-v1.0.md §スケジューラ・演出）
public enum ExamPace {

    /// 詰め込みモードに切り替える閾値（試験まで残り日数）
    public static let cramThresholdDays = 7

    /// 試験日までの残り日数から詰め込みモードかどうかを判定する。
    public static func isCramming(daysUntilExam: Int) -> Bool {
        daysUntilExam <= cramThresholdDays && daysUntilExam >= 0
    }

    /// 未導入カード数と残り日数から、1日あたりの新規導入枚数を提案する。
    /// 詰め込みモード中は新規導入0（復習優先）。
    /// - Parameters:
    ///   - remainingNewCards: まだ学習を始めていないカード枚数
    ///   - daysUntilExam: 試験日までの残り日数（0以下は当日/過去）
    ///   - maxPerDay: 1日の新規導入上限（負荷対策）
    public static func suggestedNewCardsPerDay(
        remainingNewCards: Int,
        daysUntilExam: Int,
        maxPerDay: Int = 30
    ) -> Int {
        guard remainingNewCards > 0 else { return 0 }
        if isCramming(daysUntilExam: daysUntilExam) { return 0 }
        guard daysUntilExam > 0 else { return min(remainingNewCards, maxPerDay) }
        let needed = Int(ceil(Double(remainingNewCards) / Double(daysUntilExam)))
        return min(max(needed, 1), maxPerDay)
    }

    /// 「本番までに間に合うペースか」の簡易判定。
    /// 現在の1日ペースを維持した場合に間に合うかどうか。
    public static func isOnTrack(
        remainingNewCards: Int,
        daysUntilExam: Int,
        currentNewCardsPerDay: Int
    ) -> Bool {
        guard remainingNewCards > 0 else { return true }
        guard daysUntilExam > 0 else { return remainingNewCards <= currentNewCardsPerDay }
        return currentNewCardsPerDay * daysUntilExam >= remainingNewCards
    }
}
