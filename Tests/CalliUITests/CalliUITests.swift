import XCTest

final class CalliUITests: XCTestCase {
    func testOpenCharacterDetailAndEraseRepeat() throws {
        let app = XCUIApplication()
        app.launch()

        let firstCell = app.buttons.matching(NSPredicate(format: "label BEGINSWITH '爱'")).element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        firstCell.tap()

        let hskDetailTitle = app.staticTexts["HSK 1"]
        XCTAssertTrue(hskDetailTitle.waitForExistence(timeout: 5))

        let eraseButton = app.buttons["Erase and Repeat"]
        XCTAssertTrue(eraseButton.waitForExistence(timeout: 5))

        let screenshot = app.screenshot()
        let path = "/tmp/calli_detail.png"
        try screenshot.pngRepresentation.write(to: URL(fileURLWithPath: path))

        eraseButton.tap()

        let strokeText = app.staticTexts["Stroke 1 of 10"]
        XCTAssertTrue(strokeText.waitForExistence(timeout: 5))
    }

    func testCompleteCharacterRepetition() throws {
        let app = XCUIApplication()
        app.launch()

        let firstCell = app.buttons.matching(NSPredicate(format: "label BEGINSWITH '爱'")).element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        firstCell.tap()

        let traceNextButton = app.buttons["Trace Next"]
        XCTAssertTrue(traceNextButton.waitForExistence(timeout: 5))

        for _ in 0..<10 {
            traceNextButton.tap()
            usleep(100000)
        }

        let repetitionsPill = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Repetitions today:'")).element(boundBy: 0)
        XCTAssertTrue(repetitionsPill.waitForExistence(timeout: 5))

        sleep(2)

        let completedScreenshot = app.screenshot()
        try completedScreenshot.pngRepresentation.write(to: URL(fileURLWithPath: "/tmp/calli_completed.png"))
    }
}
