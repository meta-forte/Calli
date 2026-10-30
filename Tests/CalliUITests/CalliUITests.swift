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
        let path = URL(fileURLWithPath: "/Users/manas/dev/Calli/tmp/calli_detail.png")
        try? screenshot.pngRepresentation.write(to: path)

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
        let path = URL(fileURLWithPath: "/Users/manas/dev/Calli/tmp/calli_completed.png")
        try? completedScreenshot.pngRepresentation.write(to: path)
    }

    func testAdjustFontSizeSlider() throws {
        let app = XCUIApplication()
        app.launch()

        let firstCell = app.buttons.matching(NSPredicate(format: "label BEGINSWITH '爱'")).element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        firstCell.tap()

        let fontSizeButton = app.buttons["Tracing font size options"]
        XCTAssertTrue(fontSizeButton.waitForExistence(timeout: 5))
        fontSizeButton.tap()

        let slider = app.sliders["Tracing character font size slider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 5))

        slider.adjust(toNormalizedSliderPosition: 0.8)

        let screenshot = app.screenshot()
        let path = URL(fileURLWithPath: "/Users/manas/dev/Calli/tmp/calli_tracing_font_slider.png")
        try? screenshot.pngRepresentation.write(to: path)

        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'chevron.right'")).element(boundBy: 0)
        if nextButton.waitForExistence(timeout: 2) && nextButton.isHittable {
            nextButton.tap()
            let retainedFontSizeButton = app.buttons["Tracing font size options"]
            XCTAssertTrue(retainedFontSizeButton.waitForExistence(timeout: 5))
        }
    }

    func testUpdateBellAndSheet() throws {
        let app = XCUIApplication()
        app.launch()

        let menuButton = app.buttons["Main Menu"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5))
        menuButton.tap()

        let updateMenuItem = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Update' OR label CONTAINS 'Updates'")).element(boundBy: 0)
        XCTAssertTrue(updateMenuItem.waitForExistence(timeout: 5))
        updateMenuItem.tap()

        let updateOrStatusTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Update'")).element(boundBy: 0)
        XCTAssertTrue(updateOrStatusTitle.waitForExistence(timeout: 5))

        let actionButton = app.buttons.matching(NSPredicate(format: "label == 'Done' OR label == 'Later' OR label == 'Try Again'")).element(boundBy: 0)
        XCTAssertTrue(actionButton.waitForExistence(timeout: 5))

        let screenshot = app.screenshot()
        let path = URL(fileURLWithPath: "/Users/manas/dev/Calli/tmp/calli_update_sheet.png")
        try? screenshot.pngRepresentation.write(to: path)

        let dismissButton = app.buttons.matching(NSPredicate(format: "label == 'Done' OR label == 'Later'")).element(boundBy: 0)
        if dismissButton.waitForExistence(timeout: 3) {
            dismissButton.tap()
        }
    }

    func testHamburgerMenuAboutSheet() throws {
        let app = XCUIApplication()
        app.launch()

        let menuButton = app.buttons["Main Menu"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5))
        menuButton.tap()

        let aboutButton = app.buttons["About"]
        XCTAssertTrue(aboutButton.waitForExistence(timeout: 5))
        aboutButton.tap()

        let developerText = app.staticTexts["Developed by Ibhatech"]
        XCTAssertTrue(developerText.waitForExistence(timeout: 5))

        let screenshot = app.screenshot()
        let path = URL(fileURLWithPath: "/Users/manas/dev/Calli/tmp/calli_about_sheet.png")
        try? screenshot.pngRepresentation.write(to: path)

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        closeButton.tap()
    }

    func testHamburgerMenuLegalSheet() throws {
        let app = XCUIApplication()
        app.launch()

        let menuButton = app.buttons["Main Menu"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5))
        menuButton.tap()

        let legalButton = app.buttons["Legal"]
        XCTAssertTrue(legalButton.waitForExistence(timeout: 5))
        legalButton.tap()

        let disclaimerSection = app.staticTexts["Legal & Disclaimers"]
        XCTAssertTrue(disclaimerSection.waitForExistence(timeout: 5))

        let attributionsSection = app.staticTexts["Open-Source Attributions"]
        XCTAssertTrue(attributionsSection.waitForExistence(timeout: 5))

        let makeMeAHanziText = app.staticTexts["MakeMeAHanzi & Arphic PL Fonts"]
        XCTAssertTrue(makeMeAHanziText.waitForExistence(timeout: 5))

        let screenshot = app.screenshot()
        let path = URL(fileURLWithPath: "/Users/manas/dev/Calli/tmp/calli_legal_sheet.png")
        try? screenshot.pngRepresentation.write(to: path)

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        closeButton.tap()
    }
}
