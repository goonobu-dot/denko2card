import XCTest
@testable import Denko2Card

final class StudyQueueBuilderTests: XCTestCase {

    func testDueCardsAlwaysIncluded() {
        let queue = StudyQueueBuilder.buildQueue(
            dueCardIDs: ["a", "b"],
            notIntroducedCardIDsInOrder: [],
            daysUntilExam: nil,
            isPro: true,
            freeAllowedCardIDs: [],
            alreadyStudiedTodayCount: 0
        )
        XCTAssertEqual(queue.map(\.cardID), ["a", "b"])
        XCTAssertTrue(queue.allSatisfy { !$0.isNew })
    }

    func testNewCardsAddedUpToBudget() {
        let queue = StudyQueueBuilder.buildQueue(
            dueCardIDs: [],
            notIntroducedCardIDsInOrder: ["n1", "n2", "n3"],
            daysUntilExam: nil,
            isPro: true,
            freeAllowedCardIDs: [],
            alreadyStudiedTodayCount: 0
        )
        XCTAssertEqual(queue.count, 3)
        XCTAssertTrue(queue.allSatisfy(\.isNew))
    }

    func testCrammingModeExcludesNewCards() {
        let queue = StudyQueueBuilder.buildQueue(
            dueCardIDs: ["due1"],
            notIntroducedCardIDsInOrder: ["n1", "n2"],
            daysUntilExam: 3,
            isPro: true,
            freeAllowedCardIDs: [],
            alreadyStudiedTodayCount: 0
        )
        XCTAssertEqual(queue.map(\.cardID), ["due1"], "詰め込みモードは新規導入なし")
    }

    func testFreeUserFilteredToAllowedCardsAndDailyLimit() {
        let queue = StudyQueueBuilder.buildQueue(
            dueCardIDs: ["free1", "paid1", "free2"],
            notIntroducedCardIDsInOrder: [],
            daysUntilExam: nil,
            isPro: false,
            freeAllowedCardIDs: ["free1", "free2"],
            alreadyStudiedTodayCount: 0
        )
        XCTAssertEqual(queue.map(\.cardID), ["free1", "free2"])
    }

    func testFreeUserDailyLimitCutsOffQueue() {
        let queue = StudyQueueBuilder.buildQueue(
            dueCardIDs: ["free1", "free2"],
            notIntroducedCardIDsInOrder: [],
            daysUntilExam: nil,
            isPro: false,
            freeAllowedCardIDs: ["free1", "free2"],
            alreadyStudiedTodayCount: StudyLimiter.freeDailyCardLimit - 1
        )
        XCTAssertEqual(queue.map(\.cardID), ["free1"], "残り1枠のみ通す")
    }
}
