import XCTest
@testable import Denko2Card

final class ExamPaceTests: XCTestCase {

    func testCrammingThreshold() {
        XCTAssertTrue(ExamPace.isCramming(daysUntilExam: 7))
        XCTAssertTrue(ExamPace.isCramming(daysUntilExam: 0))
        XCTAssertFalse(ExamPace.isCramming(daysUntilExam: 8))
        XCTAssertFalse(ExamPace.isCramming(daysUntilExam: -1), "試験日超過はクランプ対象外")
    }

    func testSuggestedNewCardsZeroWhenCramming() {
        XCTAssertEqual(ExamPace.suggestedNewCardsPerDay(remainingNewCards: 100, daysUntilExam: 3), 0)
    }

    func testSuggestedNewCardsDividesEvenly() {
        XCTAssertEqual(ExamPace.suggestedNewCardsPerDay(remainingNewCards: 100, daysUntilExam: 50), 2)
        XCTAssertEqual(ExamPace.suggestedNewCardsPerDay(remainingNewCards: 101, daysUntilExam: 50), 3, "端数切り上げ")
    }

    func testSuggestedNewCardsCappedAtMax() {
        XCTAssertEqual(ExamPace.suggestedNewCardsPerDay(remainingNewCards: 1000, daysUntilExam: 10, maxPerDay: 30), 30)
    }

    func testSuggestedNewCardsZeroWhenNoneRemaining() {
        XCTAssertEqual(ExamPace.suggestedNewCardsPerDay(remainingNewCards: 0, daysUntilExam: 30), 0)
    }

    func testIsOnTrack() {
        XCTAssertTrue(ExamPace.isOnTrack(remainingNewCards: 100, daysUntilExam: 50, currentNewCardsPerDay: 2))
        XCTAssertFalse(ExamPace.isOnTrack(remainingNewCards: 100, daysUntilExam: 10, currentNewCardsPerDay: 2))
    }
}
