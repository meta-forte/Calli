import XCTest
@testable import Calli

final class PracticeStorageTests: XCTestCase {
    var tempDbPath: String!
    var storage: PracticeStorageService!

    override func setUp() {
        super.setUp()
        let tempDir = NSTemporaryDirectory()
        let filename = "test_practice_\(UUID().uuidString).sqlite"
        tempDbPath = (tempDir as NSString).appendingPathComponent(filename)
        storage = PracticeStorageService(databasePath: tempDbPath)
    }

    override func tearDown() {
        storage = nil
        if let path = tempDbPath {
            try? FileManager.default.removeItem(atPath: path)
        }
        super.tearDown()
    }

    func testInitialCountIsZero() {
        let count = storage.getPracticeCount(character: "爱", date: "2026-10-24")
        XCTAssertEqual(count, 0)
    }

    func testRecordPracticeAndMergeSameDay() {
        let date = "2026-10-24"

        let count1 = storage.recordPractice(character: "爱", date: date)
        XCTAssertEqual(count1, 1)

        let count2 = storage.recordPractice(character: "爱", date: date)
        XCTAssertEqual(count2, 2)

        let storedCount = storage.getPracticeCount(character: "爱", date: date)
        XCTAssertEqual(storedCount, 2)
    }

    func testPracticeAcrossMultipleDays() {
        storage.recordPractice(character: "学", date: "2026-10-23")
        storage.recordPractice(character: "学", date: "2026-10-24")
        storage.recordPractice(character: "学", date: "2026-10-24")

        let countDay1 = storage.getPracticeCount(character: "学", date: "2026-10-23")
        let countDay2 = storage.getPracticeCount(character: "学", date: "2026-10-24")
        let totalCount = storage.getTotalPracticeCount(character: "学")

        XCTAssertEqual(countDay1, 1)
        XCTAssertEqual(countDay2, 2)
        XCTAssertEqual(totalCount, 3)
    }
}
