import XCTest

final class CalliUITests: XCTestCase {
    private let defaultPreferences = ["-resetDisplayPreferences"]

    private func launchApp(resetPreferences: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        if resetPreferences {
            app.launchArguments = defaultPreferences
        }
        app.launch()
        return app
    }

    private func saveScreenshot(_ app: XCUIApplication, name: String) {
        let path = URL(fileURLWithPath: "/Users/manas/dev/Calli/tmp/\(name).png")
        try? app.screenshot().pngRepresentation.write(to: path)
    }

    private func search(_ app: XCUIApplication, for text: String) {
        let field = app.textFields["Search Characters"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(text)
    }

    private func cell(_ app: XCUIApplication, hanzi: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "\(hanzi),")).element(boundBy: 0)
    }

    private func selectLevel(_ app: XCUIApplication, _ level: Int) {
        let levelMenu = app.buttons["HSK Level"]
        XCTAssertTrue(levelMenu.waitForExistence(timeout: 5))
        levelMenu.tap()
        let option = app.buttons["Level \(level)"]
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        option.tap()
    }

    func testSearchSpansAllLevelsAndGroupsResults() throws {
        let app = launchApp()
        selectLevel(app, 3)

        search(app, for: "fu")

        XCTAssertTrue(app.staticTexts["HSK 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(cell(app, hanzi: "服").exists)
        XCTAssertFalse(cell(app, hanzi: "乐").exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ENDSWITH 'results'")).element.exists)
        saveScreenshot(app, name: "calli_search_fu")

        app.buttons["Clear Search"].tap()
        XCTAssertTrue(app.staticTexts["283 characters"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["HSK 1"].exists)
    }

    func testSearchFindsCharacterOutsideHSKInOthers() throws {
        let app = launchApp()

        search(app, for: "long2")

        let othersHeader = app.staticTexts["Others"]
        let othersCell = cell(app, hanzi: "龍")
        var swipes = 0
        while !(othersHeader.exists && othersCell.isHittable) && swipes < 10 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(othersHeader.exists)
        XCTAssertTrue(othersCell.isHittable)
        saveScreenshot(app, name: "calli_search_others")

        othersCell.tap()
        XCTAssertTrue(app.staticTexts["Other Character"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Stroke 1 of'")).element.waitForExistence(timeout: 5))
        saveScreenshot(app, name: "calli_others_detail")
    }

    func testSelectedLevelPersistsAcrossLaunches() throws {
        var app = launchApp()
        selectLevel(app, 3)
        XCTAssertTrue(app.staticTexts["283 characters"].waitForExistence(timeout: 5))
        app.terminate()

        app = launchApp(resetPreferences: false)
        XCTAssertTrue(app.staticTexts["283 characters"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["HSK Level"].value as? String, "Level 3")

        selectLevel(app, 1)
        XCTAssertTrue(app.staticTexts["248 characters"].waitForExistence(timeout: 5))
    }

    func testDisplaySettingsChangeAndPersistCellSize() throws {
        var app = launchApp()
        let firstCell = cell(app, hanzi: "爱")
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        let mediumWidth = firstCell.frame.width

        app.buttons["Display Settings"].tap()
        let large = app.segmentedControls["Character Size"].buttons["Large"]
        XCTAssertTrue(large.waitForExistence(timeout: 5))
        large.tap()
        saveScreenshot(app, name: "calli_display_settings")
        app.buttons["Done"].tap()

        XCTAssertGreaterThan(firstCell.frame.width, mediumWidth)
        app.terminate()

        app = launchApp(resetPreferences: false)
        let relaunchedCell = cell(app, hanzi: "爱")
        XCTAssertTrue(relaunchedCell.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(relaunchedCell.frame.width, mediumWidth)
        saveScreenshot(app, name: "calli_grid_large")

        app.buttons["Display Settings"].tap()
        let relaunchedLarge = app.segmentedControls["Character Size"].buttons["Large"]
        XCTAssertTrue(relaunchedLarge.waitForExistence(timeout: 5))
        XCTAssertTrue(relaunchedLarge.isSelected)
        app.segmentedControls["Character Size"].buttons["Small"].tap()
        app.buttons["Done"].tap()
        saveScreenshot(app, name: "calli_grid_small")
        XCTAssertLessThan(cell(app, hanzi: "爱").frame.width, mediumWidth)

        app.buttons["Display Settings"].tap()
        app.segmentedControls["Character Size"].buttons["Medium"].tap()
        app.buttons["Done"].tap()
    }

    func testOpenCharacterDetailAndEraseRepeat() throws {
        let app = launchApp()

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
        let app = launchApp()

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
        let app = launchApp()

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

        let nextButton = app.buttons.matching(NSPredicate(format: "label == 'Next character' OR label CONTAINS 'chevron.right'")).element(boundBy: 0)
        if nextButton.waitForExistence(timeout: 2) && nextButton.isHittable {
            nextButton.tap()
            let retainedFontSizeButton = app.buttons["Tracing font size options"]
            XCTAssertTrue(retainedFontSizeButton.waitForExistence(timeout: 5))
        }
    }

    func testUpdateBellAndSheet() throws {
        let app = launchApp()

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
        let app = launchApp()

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
        let app = launchApp()

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

    func testAccessibilityLabelsAndMinimumTouchTargets() throws {
        let app = launchApp()

        let menuButton = app.buttons["Main Menu"]
        let settingsButton = app.buttons["Display Settings"]
        let levelMenu = app.buttons["HSK Level"]
        let firstCell = cell(app, hanzi: "爱")

        XCTAssertTrue(menuButton.waitForExistence(timeout: 5))
        XCTAssertTrue(settingsButton.exists)
        XCTAssertTrue(levelMenu.exists)
        XCTAssertTrue(firstCell.exists)

        XCTAssertEqual(
            firstCell.label,
            "爱, pinyin ài, meaning to love, HSK Level 1. Double tap to trace."
        )

        for control in [levelMenu, firstCell] {
            XCTAssertGreaterThanOrEqual(control.frame.width, 44.0)
            XCTAssertGreaterThanOrEqual(control.frame.height, 44.0)
        }
        for toolbarControl in [menuButton, settingsButton] {
            XCTAssertTrue(toolbarControl.isHittable)
            XCTAssertGreaterThanOrEqual(toolbarControl.frame.width, 36.0)
            XCTAssertGreaterThanOrEqual(toolbarControl.frame.height, 36.0)
        }

        firstCell.tap()

        let closeButton = app.buttons["Close"]
        let fontSizeButton = app.buttons["Tracing font size options"]
        let audioButtons = app.buttons.matching(NSPredicate(format: "label == 'Play pronunciation audio'"))
        let traceNextButton = app.buttons["Trace Next"]
        let eraseButton = app.buttons["Erase and Repeat"]
        let resetButton = app.buttons["Reset strokes"]
        let nextButton = app.buttons["Next character"]
        let canvas = app.otherElements["Tracing Canvas"]

        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        XCTAssertTrue(fontSizeButton.exists)
        XCTAssertGreaterThanOrEqual(audioButtons.count, 2)
        XCTAssertTrue(traceNextButton.exists)
        XCTAssertTrue(eraseButton.exists)
        XCTAssertTrue(resetButton.exists)
        XCTAssertTrue(nextButton.exists)
        XCTAssertTrue(canvas.exists)

        XCTAssertEqual(canvas.label, "Tracing canvas for 爱")
        XCTAssertEqual(canvas.value as? String, "Stroke 1 of 10")

        for detailControl in [traceNextButton, eraseButton, resetButton, nextButton] {
            XCTAssertGreaterThanOrEqual(detailControl.frame.width, 44.0)
            XCTAssertGreaterThanOrEqual(detailControl.frame.height, 44.0)
        }
        for detailToolbarControl in [closeButton, fontSizeButton] {
            XCTAssertTrue(detailToolbarControl.isHittable)
            XCTAssertGreaterThanOrEqual(detailToolbarControl.frame.width, 36.0)
            XCTAssertGreaterThanOrEqual(detailToolbarControl.frame.height, 36.0)
        }

        traceNextButton.tap()
        XCTAssertEqual(canvas.value as? String, "Stroke 2 of 10")

        closeButton.tap()
    }

    func testDynamicTypeAndOrientationResilience() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-resetDisplayPreferences",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityMedium"
        ]
        app.launch()

        let firstCell = cell(app, hanzi: "爱")
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        XCTAssertTrue(firstCell.isHittable)

        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }

        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        firstCell.tap()

        let eraseButton = app.buttons["Erase and Repeat"]
        let traceNextButton = app.buttons["Trace Next"]
        XCTAssertTrue(eraseButton.waitForExistence(timeout: 5))
        XCTAssertTrue(eraseButton.isHittable)
        XCTAssertTrue(traceNextButton.isHittable)
        saveScreenshot(app, name: "calli_landscape_a11y")

        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(eraseButton.waitForExistence(timeout: 5))
        XCTAssertTrue(eraseButton.isHittable)
    }
}
