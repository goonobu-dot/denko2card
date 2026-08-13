import XCTest
@testable import Denko2Card

final class SchedulerTests: XCTestCase {

    func testRetrievabilityAtZeroElapsedIsOne() {
        let r = Scheduler.retrievability(elapsedDays: 0, stability: 5)
        XCTAssertEqual(r, 1.0, accuracy: 0.0001)
    }

    func testRetrievabilityDecreasesOverTime() {
        let r1 = Scheduler.retrievability(elapsedDays: 1, stability: 5)
        let r10 = Scheduler.retrievability(elapsedDays: 10, stability: 5)
        XCTAssertLessThan(r10, r1)
    }

    func testIntervalDaysMatchesStabilityRoughly() {
        // sim.py: interval_for(S) = max(1, round(S))
        XCTAssertEqual(Scheduler.intervalDays(forStability: 5.4), 5)
        XCTAssertEqual(Scheduler.intervalDays(forStability: 5.6), 6)
        XCTAssertEqual(Scheduler.intervalDays(forStability: 0.1), 1, "1日未満でも最低1日")
    }

    func testEasyGrowsStabilityStrongly() {
        let state = SchedulerState(stability: 2.0, difficulty: 1.0)
        let result = Scheduler.update(state: state, evaluation: .easy, hintLevelUsed: 0)
        // sim.py: growth = 2.2 * difficultyFactor(=1.1 at difficulty=1.0) clamped >=1.15
        XCTAssertEqual(result.newState.stability, 2.0 * max(1.15, 2.2 * 1.1), accuracy: 0.001)
        XCTAssertGreaterThan(result.newState.stability, state.stability)
    }

    func testHelpedGrowsLessThanEasy() {
        let state = SchedulerState(stability: 2.0, difficulty: 1.0)
        let easy = Scheduler.update(state: state, evaluation: .easy, hintLevelUsed: 0)
        let helped = Scheduler.update(state: state, evaluation: .helped, hintLevelUsed: 2)
        XCTAssertLessThan(helped.newState.stability, easy.newState.stability)
    }

    func testHelpedGrowthDecreasesAsHintLevelIncreases() {
        let state = SchedulerState(stability: 2.0, difficulty: 1.0)
        let lv1 = Scheduler.update(state: state, evaluation: .helped, hintLevelUsed: 1)
        let lv3 = Scheduler.update(state: state, evaluation: .helped, hintLevelUsed: 3)
        XCTAssertLessThanOrEqual(lv3.newState.stability, lv1.newState.stability)
    }

    func testCouldNotRecallShrinksStability() {
        let state = SchedulerState(stability: 10.0, difficulty: 1.0)
        let result = Scheduler.update(state: state, evaluation: .couldNotRecall, hintLevelUsed: 3)
        XCTAssertEqual(result.newState.stability, 10.0 * 0.45, accuracy: 0.001)
        XCTAssertLessThan(result.newState.stability, state.stability)
    }

    func testStabilityFloorAndCeiling() {
        let tiny = SchedulerState(stability: 0.35, difficulty: 1.0)
        let failed = Scheduler.update(state: tiny, evaluation: .couldNotRecall, hintLevelUsed: 0)
        XCTAssertGreaterThanOrEqual(failed.newState.stability, 0.3)

        let huge = SchedulerState(stability: 300, difficulty: 1.0)
        let grown = Scheduler.update(state: huge, evaluation: .easy, hintLevelUsed: 0)
        XCTAssertLessThanOrEqual(grown.newState.stability, 365)
    }

    /// 発振なし回帰: 「ラク」を連続で選び続けた場合、間隔が単調増加すること（境界チェック）
    func testNoOscillationUnderRepeatedEasy() {
        var state = SchedulerState(stability: 0.5, difficulty: 1.0)
        var lastInterval = 0
        for _ in 0..<10 {
            let result = Scheduler.update(state: state, evaluation: .easy, hintLevelUsed: 0)
            XCTAssertGreaterThanOrEqual(result.intervalDays, lastInterval)
            lastInterval = result.intervalDays
            state = result.newState
        }
    }

    func testGraduationRequiresH0AndTargetRetrievability() {
        XCTAssertTrue(Scheduler.isGraduated(hintLevel: 0, elapsedDays: 1, stability: 20))
        XCTAssertFalse(Scheduler.isGraduated(hintLevel: 1, elapsedDays: 1, stability: 20), "H0以外は卒業しない")
        XCTAssertFalse(Scheduler.isGraduated(hintLevel: 0, elapsedDays: 100, stability: 5), "到達率が低いと卒業しない")
    }
}
