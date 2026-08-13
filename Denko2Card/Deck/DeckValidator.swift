import Foundation

/// デッキスキーマ検証（spec-v1.0.md §テスト: 必須フィールド・choices重複なし・goro空でない）
public enum DeckValidator {

    public struct Violation: Equatable, CustomStringConvertible {
        public let cardID: String
        public let reason: String
        public var description: String { "[\(cardID)] \(reason)" }
    }

    /// 1枚のカードを検証する。
    public static func validate(_ card: CardDefinition) -> [Violation] {
        var violations: [Violation] = []
        func fail(_ reason: String) { violations.append(Violation(cardID: card.id, reason: reason)) }

        if card.id.trimmingCharacters(in: .whitespaces).isEmpty { fail("idが空") }
        if card.topic.trimmingCharacters(in: .whitespaces).isEmpty { fail("topicが空") }
        if card.question.trimmingCharacters(in: .whitespaces).isEmpty { fail("questionが空") }
        if card.answer.trimmingCharacters(in: .whitespaces).isEmpty { fail("answerが空") }
        if card.goro.trimmingCharacters(in: .whitespaces).isEmpty { fail("goroが空") }
        if card.goroNote.trimmingCharacters(in: .whitespaces).isEmpty { fail("goroNoteが空") }
        if card.source.trimmingCharacters(in: .whitespaces).isEmpty { fail("sourceが空") }
        if card.hintImage.template.trimmingCharacters(in: .whitespaces).isEmpty { fail("hintImage.templateが空") }

        if card.choices.count != 3 {
            fail("choicesは3件必須（実際: \(card.choices.count)件）")
        }
        let trimmedChoices = card.choices.map { $0.trimmingCharacters(in: .whitespaces) }
        if trimmedChoices.contains(where: { $0.isEmpty }) {
            fail("choicesに空文字が含まれる")
        }
        if Set(trimmedChoices).count != trimmedChoices.count {
            fail("choicesに重複がある")
        }
        if card.choices.contains(where: { $0.trimmingCharacters(in: .whitespaces) == card.answer.trimmingCharacters(in: .whitespaces) }) {
            fail("choicesは誤答のみ（answerを含めてはならない）")
        }
        if card.choices.count != 3 {
            fail("choicesは誤答ちょうど3つ")
        }

        return violations
    }

    /// デッキ全体を検証する。カード間の重複IDも検出する。
    public static func validate(_ cards: [CardDefinition]) -> [Violation] {
        var violations = cards.flatMap { validate($0) }
        var seenIDs = Set<String>()
        for card in cards {
            if !seenIDs.insert(card.id).inserted {
                violations.append(Violation(cardID: card.id, reason: "id重複"))
            }
        }
        return violations
    }
}
