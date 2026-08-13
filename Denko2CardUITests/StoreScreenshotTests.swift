import XCTest

/// App Store掲載用スクリーンショット採取（＋Fable人の目QA用）。
/// CAPTURE_STORE=1（TEST_RUNNER_プレフィックス経由）のときだけ実行し、XCTAttachmentで保存する。
final class StoreScreenshotTests: XCTestCase {

    @MainActor
    func testCaptureStoreScreenshots() throws {
        guard ProcessInfo.processInfo.environment["CAPTURE_STORE"] == "1" else {
            throw XCTSkip("CAPTURE_STORE=1 のときだけ実行")
        }
        let app = XCUIApplication()
        app.launch()

        snap(app, "01_home")

        let start = app.buttons["start_learning_button"]
        XCTAssertTrue(start.waitForExistence(timeout: 8))
        start.forceTap()

        // 問題（素の状態）
        let hint = app.buttons["hint_button"]
        XCTAssertTrue(hint.waitForExistence(timeout: 8))
        snap(app, "02_question")

        // ヒント1（図解）
        hint.forceTap()
        snap(app, "03_hint1_zukai")

        // ヒント2（語呂）
        if hint.waitForExistence(timeout: 3) { hint.forceTap() }
        snap(app, "04_hint2_goro")

        // 答え（H3まで進めてから開示。ヒントボタンが残っていれば追加タップ）
        let reveal = app.buttons["reveal_answer_button"]
        var guardCount = 0
        while !reveal.exists && hint.exists && guardCount < 3 {
            hint.forceTap(); guardCount += 1
        }
        XCTAssertTrue(reveal.waitForExistence(timeout: 5), "答えを見るボタンが出ること")
        reveal.forceTap()
        XCTAssertTrue(app.staticTexts["answer_text"].waitForExistence(timeout: 5))
        snap(app, "05_answer_eval")

        // 学習を終了してホームへ戻る
        let exitButton = app.buttons["終了"].firstMatch
        if exitButton.waitForExistence(timeout: 3) { exitButton.forceTap() }

        // 進捗タブ
        let progressTab = app.buttons["進捗"].firstMatch
        XCTAssertTrue(progressTab.waitForExistence(timeout: 5))
        progressTab.forceTap()
        snap(app, "06_progress")

        // ペイウォール（ホーム→解放リンク）
        app.buttons["きょうの学習"].firstMatch.forceTap()
        let unlock = app.buttons["open_paywall_button"]
        XCTAssertTrue(unlock.waitForExistence(timeout: 5), "解放リンクが出ること")
        unlock.forceTap()
        XCTAssertTrue(app.buttons["paywall_purchase"].waitForExistence(timeout: 5), "ペイウォールが開くこと")
        snap(app, "07_paywall")
    }

    @MainActor
    private func snap(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}

extension XCUIElement {
    /// iOS 26でヒット判定不能になるケースの座標タップ回避（確立パターン）
    func forceTap() {
        if isHittable { tap() } else { coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap() }
    }
}
