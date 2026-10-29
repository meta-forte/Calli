import XCTest
import SwiftUI
@testable import Calli

final class FontSizeSliderTests: XCTestCase {
    private let storageKey = CharacterDetailView.tracingFontSizeStorageKey

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        super.tearDown()
    }

    func testDefaultTracingFontSizeConstant() {
        XCTAssertEqual(CharacterDetailView.defaultTracingFontSize, 300.0)
        XCTAssertEqual(CharacterDetailView.minTracingFontSize, 160.0)
        XCTAssertEqual(CharacterDetailView.maxTracingFontSize, 520.0)
        XCTAssertEqual(CharacterDetailView.tracingFontSizeStorageKey, "kTracingCharacterFontSize")
    }

    func testTracingUserDefaultsPersistence() {
        UserDefaults.standard.set(380.0, forKey: storageKey)
        let retrieved = UserDefaults.standard.double(forKey: storageKey)
        XCTAssertEqual(retrieved, 380.0)
    }

    func testTracingDetailViewPersistenceAcrossInstances() {
        let character = CharacterItem(
            id: 1,
            level: 1,
            hanzi: "爱",
            pinyin: "ài",
            tones: "4",
            meaning: "love",
            exampleChinese: "",
            examplePinyin: "",
            exampleEnglish: ""
        )

        var view1 = CharacterDetailView(
            character: character,
            strokeInfo: nil,
            onPrevious: nil,
            onNext: nil
        )
        view1.tracingFontSize = 420.0
        XCTAssertEqual(UserDefaults.standard.double(forKey: storageKey), 420.0)

        let view2 = CharacterDetailView(
            character: character,
            strokeInfo: nil,
            onPrevious: nil,
            onNext: nil
        )
        XCTAssertEqual(view2.tracingFontSize, 420.0)
    }
}
