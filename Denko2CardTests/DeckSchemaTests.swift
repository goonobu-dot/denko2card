import XCTest
@testable import Denko2Card

/// サンプルデッキ（Resources/deck/denko2_sample.json）に対するスキーマ検証テスト。
/// spec-v1.0.md §テスト「デッキスキーマ検証テスト・facts.json数値突合テスト」
final class DeckSchemaTests: XCTestCase {

    private func loadSampleCards() throws -> [CardDefinition] {
        try DeckLoader.loadAll(from: Bundle(for: DeckRepository.self))
    }

    func testDeckLoadsWithoutError() throws {
        let cards = try loadSampleCards()
        XCTAssertFalse(cards.isEmpty)
    }

    func testAllCardsPassValidation() throws {
        let cards = try loadSampleCards()
        let violations = DeckValidator.validate(cards)
        XCTAssertTrue(violations.isEmpty, "スキーマ違反: \(violations.map(\.description).joined(separator: "\n"))")
    }

    func testNoDuplicateIDs() throws {
        let cards = try loadSampleCards()
        let ids = cards.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testAllSubjectsRepresented() throws {
        let cards = try loadSampleCards()
        let subjects = Set(cards.map(\.subject))
        XCTAssertEqual(subjects, Set(Subject.allCases))
    }

    func testAllChoicesHaveExactlyThreeUniqueNonEmptyEntries() throws {
        let cards = try loadSampleCards()
        for card in cards {
            XCTAssertEqual(card.choices.count, 3, card.id)
            XCTAssertEqual(Set(card.choices).count, 3, "\(card.id): choicesに重複")
            XCTAssertTrue(card.choices.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty }, "\(card.id): 空のchoiceがある")
        }
    }

    func testGoroAndGoroNoteNeverEmpty() throws {
        let cards = try loadSampleCards()
        for card in cards {
            XCTAssertFalse(card.goro.isEmpty, card.id)
            XCTAssertFalse(card.goroNote.isEmpty, card.id)
        }
    }

    func testAllHintTemplatesAreKnown() throws {
        let cards = try loadSampleCards()
        for card in cards {
            XCTAssertNotNil(HintTemplateKind(deckValue: card.hintImage.template), "\(card.id): 未知のテンプレ \(card.hintImage.template)")
        }
    }

    func testSampleDeckCoversAllFifteenTemplates() throws {
        let cards = try loadSampleCards()
        let usedTemplates = Set(cards.map(\.hintImage.template))
        XCTAssertEqual(usedTemplates.count, 15, "サンプルデッキは検収用に15種全テンプレを使う想定")
    }
}
