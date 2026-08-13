import XCTest
@testable import Denko2Card

final class HintStateMachineTests: XCTestCase {

    func testFirstTapJumpsToStartLevel() {
        XCTAssertEqual(HintStateMachine.advance(current: .h0, startLevel: .h2), .h2)
    }

    func testFirstTapNeverGoesBelowH1() {
        XCTAssertEqual(HintStateMachine.advance(current: .h0, startLevel: .h0), .h1, "H0開始でも1回目のヒントはH1に進む")
    }

    func testSubsequentTapsIncrementByOne() {
        XCTAssertEqual(HintStateMachine.advance(current: .h1, startLevel: .h1), .h2)
        XCTAssertEqual(HintStateMachine.advance(current: .h2, startLevel: .h1), .h3)
    }

    func testCannotExceedH3() {
        XCTAssertEqual(HintStateMachine.advance(current: .h3, startLevel: .h1), .h3)
    }

    func testNextStartLevelDecrementsOnEasy() {
        XCTAssertEqual(HintStateMachine.nextStartLevel(current: .h2, evaluation: .easy), .h1)
        XCTAssertEqual(HintStateMachine.nextStartLevel(current: .h0, evaluation: .easy), .h0, "H0未満にはならない")
    }

    func testNextStartLevelUnchangedOnHelped() {
        XCTAssertEqual(HintStateMachine.nextStartLevel(current: .h2, evaluation: .helped), .h2)
    }

    func testNextStartLevelIncrementsOnCouldNotRecall() {
        XCTAssertEqual(HintStateMachine.nextStartLevel(current: .h2, evaluation: .couldNotRecall), .h3)
        XCTAssertEqual(HintStateMachine.nextStartLevel(current: .h3, evaluation: .couldNotRecall), .h3, "H3を超えない")
    }

    /// 発振なし回帰: easy/helpedを交互に繰り返しても段階が往復し続けない（helpedは維持のため単調ではないが、
    /// easyの連続では単調減少、couldNotRecallの連続では単調増加することを確認する。
    func testMonotonicUnderRepeatedEvaluations() {
        var level = HintLevel.h3
        for _ in 0..<5 {
            let next = HintStateMachine.nextStartLevel(current: level, evaluation: .easy)
            XCTAssertLessThanOrEqual(next.rawValue, level.rawValue)
            level = next
        }
        XCTAssertEqual(level, .h0)

        level = .h0
        for _ in 0..<5 {
            let next = HintStateMachine.nextStartLevel(current: level, evaluation: .couldNotRecall)
            XCTAssertGreaterThanOrEqual(next.rawValue, level.rawValue)
            level = next
        }
        XCTAssertEqual(level, .h3)
    }
}
