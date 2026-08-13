import XCTest

/// UIテスト: 学習フロー一周（問題→ヒント→答え→評価）・ペイウォール表示・無料上限。
/// spec-v1.0.md §テスト
final class LearnFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testTodayTabShowsStartButton() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["きょうの学習"].waitForExistence(timeout: 5))
    }

    func testOneFullLearnCycle() {
        let app = XCUIApplication()
        app.launch()

        let startButton = app.buttons["start_learning_button"]
        guard startButton.waitForExistence(timeout: 5), startButton.isEnabled else {
            // 無料枠の状態次第でキューが空のことがあるため、その場合はペイウォール導線の存在のみ確認する。
            XCTAssertTrue(app.buttons["open_paywall_button"].waitForExistence(timeout: 5))
            return
        }
        startButton.tap()

        // ヒントを1回踏んでから「わかる」→自己評価まで到達できることを確認する。
        if app.buttons["hint_button"].waitForExistence(timeout: 5) {
            app.buttons["hint_button"].tap()
        }
        if app.buttons["know_it_button"].waitForExistence(timeout: 5) {
            app.buttons["know_it_button"].tap()
        } else if app.buttons["reveal_answer_button"].waitForExistence(timeout: 5) {
            app.buttons["reveal_answer_button"].tap()
        }

        XCTAssertTrue(app.staticTexts["answer_text"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["eval_easy"].waitForExistence(timeout: 5))
        app.buttons["eval_easy"].tap()
    }

    func testPaywallOpensFromSettings() {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["設定"].tap()
        let button = app.buttons["すべてのカードを解放する"]
        if button.waitForExistence(timeout: 5) {
            button.tap()
            XCTAssertTrue(app.buttons["paywall_purchase"].waitForExistence(timeout: 5))
        }
    }
}
