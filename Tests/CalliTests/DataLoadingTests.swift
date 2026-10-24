import XCTest
@testable import Calli

final class DataLoadingTests: XCTestCase {
    func testCharactersLoading() throws {
        let bundle = Bundle(for: type(of: self))
        var url = bundle.url(forResource: "characters", withExtension: "json")
        if url == nil {
            url = Bundle.main.url(forResource: "characters", withExtension: "json")
        }
        if url == nil {
            let directPath = "Calli/Resources/characters.json"
            if FileManager.default.fileExists(atPath: directPath) {
                url = URL(fileURLWithPath: directPath)
            }
        }

        let targetURL = try XCTUnwrap(url)
        let data = try Data(contentsOf: targetURL)
        let characters = try JSONDecoder().decode([CharacterItem].self, from: data)

        XCTAssertEqual(characters.count, 3088)

        let first = characters.first
        XCTAssertEqual(first?.hanzi, "爱")
        XCTAssertEqual(first?.level, 1)
        XCTAssertEqual(first?.pinyin, "ài")

        let levels = Set(characters.map { $0.level })
        XCTAssertEqual(levels, Set(1...9))
    }

    func testStrokesLoading() throws {
        let bundle = Bundle(for: type(of: self))
        var url = bundle.url(forResource: "strokes", withExtension: "json")
        if url == nil {
            url = Bundle.main.url(forResource: "strokes", withExtension: "json")
        }
        if url == nil {
            let directPath = "Calli/Resources/strokes.json"
            if FileManager.default.fileExists(atPath: directPath) {
                url = URL(fileURLWithPath: directPath)
            }
        }

        let targetURL = try XCTUnwrap(url)
        let data = try Data(contentsOf: targetURL)
        let strokes = try JSONDecoder().decode([String: CharacterStrokeInfo].self, from: data)

        XCTAssertGreaterThan(strokes.count, 3000)
        let ai = try XCTUnwrap(strokes["爱"])
        XCTAssertEqual(ai.strokes.count, 10)
        XCTAssertEqual(ai.medians.count, 10)
    }
}
