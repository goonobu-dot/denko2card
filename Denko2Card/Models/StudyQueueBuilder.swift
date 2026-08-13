import Foundation

/// 「きょうの学習」キューを組み立てる純関数。復習期日到来カード＋新規導入カードを
/// 詰め込みモード・無料制限を考慮して選ぶ（spec-v1.0.md §画面構成1・スケジューラ§演出）。
public enum StudyQueueBuilder {

    public struct QueueItem: Equatable {
        public let cardID: String
        public let isNew: Bool
    }

    /// - Parameters:
    ///   - dueCardIDs: 期日到来（または未学習で導入済み）の復習カードID
    ///   - notIntroducedCardIDsInOrder: まだ導入していないカードID（デッキ順）
    ///   - today: 判定基準日
    ///   - daysUntilExam: 試験日までの残り日数（nil=試験日未設定）
    ///   - isPro: 課金済みか
    ///   - freeAllowedCardIDs: 無料ユーザーが閲覧可能なカードID集合（無料開放トピック）
    ///   - alreadyStudiedTodayCount: 本日すでに学習した回数
    public static func buildQueue(
        dueCardIDs: [String],
        notIntroducedCardIDsInOrder: [String],
        daysUntilExam: Int?,
        isPro: Bool,
        freeAllowedCardIDs: Set<String>,
        alreadyStudiedTodayCount: Int
    ) -> [QueueItem] {
        var queue: [QueueItem] = dueCardIDs.map { QueueItem(cardID: $0, isNew: false) }

        let cramming = daysUntilExam.map(ExamPace.isCramming) ?? false
        if !cramming {
            let newBudget = daysUntilExam.map {
                ExamPace.suggestedNewCardsPerDay(
                    remainingNewCards: notIntroducedCardIDsInOrder.count,
                    daysUntilExam: $0
                )
            } ?? min(notIntroducedCardIDsInOrder.count, 20)
            queue.append(contentsOf: notIntroducedCardIDsInOrder.prefix(newBudget).map { QueueItem(cardID: $0, isNew: true) })
        }

        guard !isPro else { return queue }

        var result: [QueueItem] = []
        var studiedCount = alreadyStudiedTodayCount
        for item in queue {
            guard freeAllowedCardIDs.contains(item.cardID) else { continue }
            guard studiedCount < StudyLimiter.freeDailyCardLimit else { break }
            result.append(item)
            studiedCount += 1
        }
        return result
    }
}
