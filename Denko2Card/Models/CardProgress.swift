import Foundation
import SwiftData

/// カード1枚あたりの学習進捗（SwiftData永続モデル）。
/// カード本体（question/answer等）はJSONデッキ側の`CardDefinition`が正で、
/// このモデルは`cardID`で参照するだけの薄いレコードにする（デッキ差し替え耐性のため）。
@Model
final class CardProgress {
    @Attribute(.unique) var cardID: String
    var subjectRaw: String

    /// FSRS簡易スケジューラの状態
    var stability: Double
    var difficulty: Double

    /// 開始ヒント段階（H0〜H3）。DCRP漸減の記憶。
    var startHintLevelRaw: Int

    /// 次回レビュー予定日（nil=未学習の新規カード）
    var dueDate: Date?
    /// 直近のレビュー日
    var lastReviewedDate: Date?

    /// 累計レビュー回数・ヒント使用の統計（弱点マップ用）
    var totalReviews: Int
    var totalHintedReviews: Int
    var isIntroduced: Bool

    init(cardID: String, subject: Subject) {
        self.cardID = cardID
        self.subjectRaw = subject.rawValue
        self.stability = 0.5
        self.difficulty = 1.0
        self.startHintLevelRaw = HintLevel.h1.rawValue
        self.dueDate = nil
        self.lastReviewedDate = nil
        self.totalReviews = 0
        self.totalHintedReviews = 0
        self.isIntroduced = false
    }

    var subject: Subject { Subject(rawValue: subjectRaw) ?? .kizai }

    var startHintLevel: HintLevel {
        get { HintLevel(rawValue: startHintLevelRaw) ?? .h1 }
        set { startHintLevelRaw = newValue.rawValue }
    }

    var schedulerState: SchedulerState {
        SchedulerState(stability: stability, difficulty: difficulty)
    }

    /// 弱点度（ヒント依存率）。進捗画面の「弱点トピック」ソートに使う。
    var hintDependencyRate: Double {
        guard totalReviews > 0 else { return 0 }
        return Double(totalHintedReviews) / Double(totalReviews)
    }

    /// 卒業判定（H0でラクに思い出せる状態が続いている）
    func isGraduated(asOf date: Date) -> Bool {
        guard startHintLevel == .h0, let due = dueDate else { return false }
        let elapsed = date.timeIntervalSince(due) / 86400 + intervalDaysAtDue
        return Scheduler.isGraduated(hintLevel: 0, elapsedDays: max(elapsed, 0), stability: stability)
    }

    private var intervalDaysAtDue: Double {
        Double(Scheduler.intervalDays(forStability: stability))
    }

    /// このレビューの結果を反映する（純関数Schedulerを呼び出す薄いラッパー）。
    func applyReview(evaluation: SelfEvaluation, hintLevelUsed: Int, reviewedAt date: Date) {
        let result = Scheduler.update(state: schedulerState, evaluation: evaluation, hintLevelUsed: hintLevelUsed)
        stability = result.newState.stability
        startHintLevel = HintStateMachine.nextStartLevel(
            current: HintLevel(rawValue: min(max(hintLevelUsed, 0), 3)) ?? startHintLevel,
            evaluation: evaluation
        )
        lastReviewedDate = date
        dueDate = Calendar.current.date(byAdding: .day, value: result.intervalDays, to: date)
        totalReviews += 1
        if hintLevelUsed > 0 { totalHintedReviews += 1 }
        isIntroduced = true
    }
}
