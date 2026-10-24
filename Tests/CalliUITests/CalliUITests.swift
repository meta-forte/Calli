import XCTest

final class CalliUITests: XCTestCase {
    func testOpenCharacterDetail() throws {
        let app = XCUIApplication()
        app.launch()

        let firstCell = app.buttons.matching(NSPredicate(format: "label BEGINSWITH '爱'")).element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        firstCell.tap()

        let hskDetailTitle = app.staticTexts["HSK 1"]
        XCTAssertTrue(hskDetailTitle.waitForExistence(timeout: 5))

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.lifetime = .keepAlways
        add(attachment)

        let path = "/tmp/calli_detail.png"
        try screenshot.pngRepresentation.write(to: URL(fileURLWithPath: path))
    }
}
