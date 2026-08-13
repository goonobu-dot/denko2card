import XCTest
@testable import Denko2Card

/// デッキ執筆側が使うテンプレ別名（signboard/distance/structure/colorChip/vapor/static/
/// mixLoad/calendar/personnel/gradeBadge/extinguish）が、このアプリのスキーマで
/// デコード可能であることを固定する回帰テスト。
final class DeckCompatibilityTests: XCTestCase {

    func testSubjectAcceptsJapaneseDisplayNames() {
        XCTAssertEqual(Subject(deckValue: "器具・材料"), .kizai)
        XCTAssertEqual(Subject(deckValue: "kizai"), .kizai)
        XCTAssertEqual(Subject(deckValue: "図記号・複線図"), .zumen)
        XCTAssertEqual(Subject(deckValue: "法令・理論"), .houki)
        XCTAssertNil(Subject(deckValue: "unknown"))
    }

    func testHintTemplateAcceptsEditorialAliases() {
        let aliasMap: [String: HintTemplateKind] = [
            "signboard": .signBoard,
            "distance": .safetyRuler,
            "structure": .crossSection,
            "colorChip": .colorSwatch,
            "vapor": .vaporWeight,
            "static": .staticElectricity,
            "mixLoad": .mixedTable,
            "calendar": .deadlineCalendar,
            "personnel": .staffing,
            "gradeBadge": .hazardBadge,
            "extinguish": .fireCompare
        ]
        for (alias, expected) in aliasMap {
            XCTAssertEqual(HintTemplateKind(deckValue: alias), expected, alias)
        }
    }

    /// 実際のデッキ（K001）と同じ構造をデコードできることを確認する。
    func testDecodesActualCardShape() throws {
        let json = """
        {
          "id": "K001",
          "subject": "器具・材料",
          "topic": "電線・ケーブル",
          "question": "600Vビニル絶縁電線の略称は？",
          "answer": "IV線",
          "choices": ["VVF", "CV", "CVT"],
          "hintImage": { "template": "signboard", "params": { "text": "IV線" } },
          "goro": "「アイブイ」は色々な場所に単線で",
          "goroNote": "IV=Indoor Vinyl相当の略称。電線管内配線などに使われる基本的な絶縁電線。",
          "source": "JIS C 3307（600Vビニル絶縁電線）",
          "tags": ["電線", "IV線"]
        }
        """.data(using: .utf8)!

        let card = try JSONDecoder().decode(CardDefinition.self, from: json)
        XCTAssertEqual(card.subject, .kizai)
        XCTAssertEqual(HintTemplateKind(deckValue: card.hintImage.template), .signBoard)
        XCTAssertFalse(card.choices.contains(card.answer), "正解がchoicesに含まれてはならない")
    }
}
