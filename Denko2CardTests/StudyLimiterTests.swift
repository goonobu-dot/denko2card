import XCTest
@testable import Denko2Card

final class StudyLimiterTests: XCTestCase {

    func testFreeTopicIsKizaiFirstTwoTopicsOnly() {
        XCTAssertTrue(StudyLimiter.isCardFree(subject: .kizai, topic: "電線・ケーブル"))
        XCTAssertTrue(StudyLimiter.isCardFree(subject: .kizai, topic: "工具"))
        XCTAssertFalse(StudyLimiter.isCardFree(subject: .kizai, topic: "測定器"))
        XCTAssertFalse(StudyLimiter.isCardFree(subject: .zumen, topic: "電線・ケーブル"))
    }

    func testDailyLimitBoundary() {
        XCTAssertEqual(StudyLimiter.remainingFreeCardsToday(alreadyStudiedToday: 0), 20)
        XCTAssertEqual(StudyLimiter.remainingFreeCardsToday(alreadyStudiedToday: 19), 1)
        XCTAssertEqual(StudyLimiter.remainingFreeCardsToday(alreadyStudiedToday: 20), 0)
        XCTAssertEqual(StudyLimiter.remainingFreeCardsToday(alreadyStudiedToday: 999), 0, "上限を超えても負数にならない")
    }

    func testCanStudyProAlwaysAllowed() {
        XCTAssertTrue(StudyLimiter.canStudy(subject: .zumen, topic: "何でも", alreadyStudiedToday: 999, isPro: true))
    }

    func testCanStudyFreeUserWithinLimit() {
        XCTAssertTrue(StudyLimiter.canStudy(subject: .kizai, topic: "電線・ケーブル", alreadyStudiedToday: 5, isPro: false))
    }

    func testCanStudyFreeUserAtLimitBlocked() {
        XCTAssertFalse(StudyLimiter.canStudy(subject: .kizai, topic: "電線・ケーブル", alreadyStudiedToday: 20, isPro: false))
    }

    func testCanStudyFreeUserOutsideFreeTopicBlocked() {
        XCTAssertFalse(StudyLimiter.canStudy(subject: .houki, topic: "オームの法則・電力", alreadyStudiedToday: 0, isPro: false))
    }
}
