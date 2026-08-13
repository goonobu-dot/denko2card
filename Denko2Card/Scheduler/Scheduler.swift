import Foundation

/// 自己評価3択（学習フロー仕様 spec-v1.0.md §学習フロー 3）
public enum SelfEvaluation: String, Codable, Sendable, CaseIterable {
    /// ラクに思い出せた
    case easy
    /// ヒントのおかげ
    case helped
    /// 無理だった
    case couldNotRecall
}

/// FSRS簡易スケジューラの状態。純粋なvalue type（SwiftDataモデルとは分離）。
public struct SchedulerState: Equatable, Sendable {
    /// stability（安定度、日単位）
    public var stability: Double
    /// カードの難易度係数。0.8=易 〜 1.2=難。未指定は1.0。
    public var difficulty: Double

    public init(stability: Double = 0.5, difficulty: Double = 1.0) {
        self.stability = stability
        self.difficulty = difficulty
    }
}

/// スケジューラの1回分の更新結果。
public struct SchedulerUpdateResult: Equatable, Sendable {
    public let newState: SchedulerState
    /// 次回の期日までの日数（1以上）
    public let intervalDays: Int
}

/// FSRS簡易版の純関数群。
/// 係数は `/private/tmp/.../scratchpad/hinttango/sim.py` で60日シミュレーション検証済み
/// （マスター率・負荷中央値・発振率0%を確認したもの）。この値を変更する場合は
/// SchedulerTests の回帰テストと合わせてsim.py側も再検証すること。
public enum Scheduler {

    /// 目標到達率（この値になる日数を次回期日とする）
    public static let targetRetrievability: Double = 0.90

    /// retrievability R(t) = (1 + t / (9S))^-1
    public static func retrievability(elapsedDays t: Double, stability S: Double) -> Double {
        let safeT = max(t, 0.0)
        let safeS = max(S, 0.0001)
        return pow(1 + safeT / (9 * safeS), -1)
    }

    /// R=target になる経過日数（= 次回レビューまでの間隔）。sim.py: interval_for(S) = max(1, round(S))
    public static func intervalDays(forStability S: Double) -> Int {
        max(1, Int(S.rounded()))
    }

    /// 自己評価とヒント使用段階から次のスケジューラ状態を計算する。
    /// - Parameters:
    ///   - state: 現在のスケジューラ状態
    ///   - evaluation: 自己評価（ラク/ヒント/無理）
    ///   - hintLevelUsed: 「わかる」を押した時点の表示ヒント段階（0=素の想起, 1〜3）。
    ///     couldNotRecallの場合は到達した最大段階を渡す。
    public static func update(
        state: SchedulerState,
        evaluation: SelfEvaluation,
        hintLevelUsed: Int
    ) -> SchedulerUpdateResult {
        let lv = Double(min(max(hintLevelUsed, 0), 3))
        let difficultyFactor = 1.1 - (state.difficulty - 1)
        var newS: Double

        switch evaluation {
        case .easy:
            let growth = max(1.15, 2.2 * difficultyFactor)
            newS = min(365, state.stability * growth)
        case .helped:
            let growth = max(1.15, (2.2 - 0.35 * lv) * difficultyFactor)
            newS = min(365, state.stability * growth)
        case .couldNotRecall:
            newS = max(0.3, state.stability * 0.45)
        }

        let newState = SchedulerState(stability: newS, difficulty: state.difficulty)
        return SchedulerUpdateResult(newState: newState, intervalDays: intervalDays(forStability: newS))
    }

    /// 「卒業」判定: H0で楽に思い出せる状態が続き、目標到達率以上であること。
    public static func isGraduated(hintLevel: Int, elapsedDays: Double, stability: Double) -> Bool {
        hintLevel == 0 && retrievability(elapsedDays: elapsedDays, stability: stability) >= targetRetrievability
    }
}
