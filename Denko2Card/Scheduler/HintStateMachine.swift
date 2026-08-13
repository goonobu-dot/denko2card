import Foundation

/// ヒント段階。H0=素の想起, H1=図解, H2=語呂, H3=3択（spec-v1.0.md §学習フロー 2）
public enum HintLevel: Int, Codable, Sendable, Comparable, CaseIterable {
    case h0 = 0
    case h1 = 1
    case h2 = 2
    case h3 = 3

    public static func < (lhs: HintLevel, rhs: HintLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    public var next: HintLevel {
        HintLevel(rawValue: min(rawValue + 1, HintLevel.h3.rawValue)) ?? .h3
    }

    public var previous: HintLevel {
        HintLevel(rawValue: max(rawValue - 1, HintLevel.h0.rawValue)) ?? .h0
    }
}

/// DCRP（Diminishing-Cues Retrieval Practice）のヒント漸減状態機械。
/// カードごとの「開始ヒント段階」を保持し、自己評価に応じて増減させる純関数群。
/// 根拠: notes-h-science.md（Fiechter & Benjamin 2017 / 望ましい困難の境界）。
public enum HintStateMachine {

    /// 1問学習セッション中、「ヒント」タップで次に表示する段階を返す。
    /// 初回タップ（current==h0）は、カードの開始段階まで一気に進む（無駄な素通りを避ける）。
    /// 2回目以降は1段階ずつ進める。
    public static func advance(current: HintLevel, startLevel: HintLevel) -> HintLevel {
        if current == .h0 {
            return max(current.next, startLevel)
        }
        return current.next
    }

    /// 自己評価に応じて次回の「開始ヒント段階」を更新する。
    /// - ラクに思い出せた → 1段階減らす（最小H0）
    /// - ヒントのおかげ → 現状維持
    /// - 無理だった → 1段階増やす（最大H3）
    public static func nextStartLevel(current: HintLevel, evaluation: SelfEvaluation) -> HintLevel {
        switch evaluation {
        case .easy:
            return current.previous
        case .helped:
            return current
        case .couldNotRecall:
            return current.next
        }
    }

    private static func max(_ a: HintLevel, _ b: HintLevel) -> HintLevel {
        a.rawValue >= b.rawValue ? a : b
    }
}
