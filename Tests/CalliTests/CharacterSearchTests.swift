import XCTest
@testable import Calli

final class CharacterSearchTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var store: CharacterStore!

    override func setUp() {
        super.setUp()
        suiteName = "CharacterSearchTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        store = CharacterStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        store = nil
        defaults = nil
        super.tearDown()
    }

    private func results(for query: String) -> [CharacterSection] {
        store.searchQuery = query
        return store.sections
    }

    private func hanzi(in sections: [CharacterSection]) -> Set<String> {
        Set(sections.flatMap(\.characters).map(\.hanzi))
    }

    private func readings(of item: CharacterItem) -> [PinyinSyllable] {
        item.pinyin.split(separator: ",").compactMap { PinyinSyllable.parse($0.trimmingCharacters(in: .whitespaces)) }
    }

    func testBundledDataIncludesOtherCharacters() {
        XCTAssertEqual(store.allCharacters.count, 3088)
        XCTAssertGreaterThan(store.otherCharacters.count, 6000)
        XCTAssertTrue(store.otherCharacters.allSatisfy { $0.level == CharacterItem.othersLevel })
        let hskHanzi = Set(store.allCharacters.map(\.hanzi))
        XCTAssertTrue(store.otherCharacters.allSatisfy { !hskHanzi.contains($0.hanzi) })
    }

    func testFuMatchesPinyinInsteadOfEnglishSubstrings() {
        let sections = results(for: "Fu")
        let found = hanzi(in: sections)

        XCTAssertTrue(found.contains("服"))
        XCTAssertTrue(found.contains("父"))
        XCTAssertFalse(found.contains("乐"))
        XCTAssertFalse(found.contains("安"))
        XCTAssertFalse(found.contains("饱"))
        XCTAssertFalse(found.contains("满"))
        XCTAssertFalse(found.contains("毛"))
        XCTAssertFalse(found.contains("将"))
        XCTAssertFalse(found.contains("况"))

        for section in sections {
            guard let first = section.characters.first else {
                XCTFail("Empty section \(section.title)")
                continue
            }
            XCTAssertTrue(readings(of: first).contains { $0.base == "fu" }, section.title)
        }
    }

    func testSonMatchesExactWordAndNotSong() {
        let sections = results(for: "Son")
        let found = hanzi(in: sections)

        XCTAssertTrue(found.contains("子"))
        XCTAssertTrue(found.contains("儿"))
        XCTAssertFalse(found.contains("唱"))
        XCTAssertFalse(found.contains("松"))

        if let zi = sections.flatMap(\.characters).first(where: { $0.hanzi == "子" }) {
            XCTAssertEqual(store.matchedMeaning(for: zi), "son")
        } else {
            XCTFail("Expected 子 in results for Son")
        }
    }

    func testIrregularAndRegularPluralLemmasMatchBothWays() {
        let leafFound = hanzi(in: results(for: "leaf"))
        let leavesFound = hanzi(in: results(for: "leaves"))

        XCTAssertEqual(leafFound, leavesFound)
        XCTAssertTrue(leafFound.contains("叶"))
        XCTAssertTrue(leafFound.contains("页"))
        XCTAssertTrue(leafFound.contains("茗"))
        XCTAssertTrue(leafFound.contains("菸"))

        if let ming = store.displayedCharacters.first(where: { $0.hanzi == "茗" }) {
            XCTAssertEqual(store.matchedMeaning(for: ming), "tea leaves")
        } else {
            XCTFail("Expected 茗 in results for leaf/leaves")
        }

        let featherFound = hanzi(in: results(for: "feather"))
        let feathersFound = hanzi(in: results(for: "feathers"))
        XCTAssertTrue(featherFound.contains("毛"))
        XCTAssertTrue(feathersFound.contains("毛"))
        XCTAssertEqual(featherFound, feathersFound)
    }

    func testSearchSpansAllLevelsAndGroupsInOrderWithOthersLast() {
        store.selectedLevel = 3
        let sections = results(for: "fu")
        let levels = sections.map(\.level)

        XCTAssertEqual(levels.last, CharacterItem.othersLevel)
        XCTAssertEqual(Array(levels.dropLast()), Array(levels.dropLast()).sorted())
        XCTAssertTrue(levels.contains(1))
        XCTAssertTrue(levels.contains(4))
        XCTAssertEqual(sections.last?.title, "Others")
        XCTAssertEqual(sections.first?.title, "HSK \(levels[0])")
    }

    func testToneNumberNarrowsResults() {
        let sections = results(for: "fu4")
        let found = hanzi(in: sections)

        XCTAssertTrue(found.contains("父"))
        XCTAssertFalse(found.contains("服"))
        for item in sections.flatMap(\.characters) {
            XCTAssertTrue(readings(of: item).contains { $0.base == "fu" && $0.tone == 4 }, item.hanzi)
        }
    }

    func testToneMarkInQueryNarrowsResults() {
        let found = hanzi(in: results(for: "fú"))

        XCTAssertTrue(found.contains("服"))
        XCTAssertFalse(found.contains("父"))
    }

    func testUmlautSpellings() {
        XCTAssertTrue(hanzi(in: results(for: "lü")).contains("绿"))
        XCTAssertTrue(hanzi(in: results(for: "lv4")).contains("绿"))
        XCTAssertFalse(hanzi(in: results(for: "lv4")).contains("路"))
        XCTAssertTrue(hanzi(in: results(for: "lu4")).isSuperset(of: ["绿", "路"]))
    }

    func testPartialSyllableMatchesWhileTyping() {
        XCTAssertTrue(hanzi(in: results(for: "zh")).contains("中"))
        XCTAssertTrue(hanzi(in: results(for: "zhon")).contains("中"))
    }

    func testPrepositionForEliminatesMeasureWordsAndPhrases() {
        let sections = results(for: "for")
        let found = hanzi(in: sections)

        XCTAssertFalse(found.contains("杯"))
        XCTAssertFalse(found.contains("本"))
        XCTAssertFalse(found.contains("备"))
        XCTAssertFalse(found.contains("被"))
        XCTAssertFalse(found.contains("件"))
        XCTAssertFalse(found.contains("间"))
        XCTAssertFalse(found.contains("满"))

        for item in sections.flatMap(\.characters) {
            XCTAssertEqual(store.matchedMeaning(for: item)?.lowercased(), "for", "\(item.hanzi) (\(item.pinyin)): \(item.meaning)")
        }
    }

    func testMeaningMatchesWholeWordsAndWordStartsOnly() {
        XCTAssertTrue(hanzi(in: results(for: "love")).contains("爱"))
        XCTAssertTrue(hanzi(in: results(for: "cheer")).contains("乐"))
        XCTAssertTrue(hanzi(in: results(for: "to love")).contains("爱"))
        XCTAssertFalse(hanzi(in: results(for: "erful")).contains("乐"))
    }

    func testHanziQueryMatchesEachCharacter() {
        let sections = results(for: "你好")
        XCTAssertEqual(hanzi(in: sections), ["你", "好"])
        XCTAssertEqual(sections.map(\.level), [1])
    }

    func testCharacterOutsideHSKAppearsInOthers() throws {
        let sections = results(for: "愛")
        XCTAssertEqual(sections.count, 1)
        let section = try XCTUnwrap(sections.first)
        XCTAssertEqual(section.title, "Others")
        XCTAssertEqual(section.characters.map(\.hanzi), ["愛"])

        let strokes = try XCTUnwrap(store.strokeInfo(for: "愛"))
        XCTAssertEqual(strokes.strokes.count, 13)
    }

    func testClearingSearchShowsSelectedLevel() {
        store.selectedLevel = 3
        _ = results(for: "fu")
        store.searchQuery = "   "

        XCTAssertFalse(store.isSearching)
        XCTAssertEqual(store.sections.map(\.level), [3])
        XCTAssertEqual(store.displayedCount, 283)
    }

    func testNoResults() {
        XCTAssertTrue(results(for: "qqqqzz").isEmpty)
        XCTAssertEqual(store.displayedCount, 0)
    }

    func testSelectedLevelPersistsAcrossLaunches() {
        XCTAssertEqual(store.selectedLevel, CharacterStore.defaultLevel)
        store.selectedLevel = 3
        XCTAssertEqual(defaults.integer(forKey: CharacterStore.selectedLevelStorageKey), 3)

        let relaunched = CharacterStore(defaults: defaults, loadBundledData: false)
        XCTAssertEqual(relaunched.selectedLevel, 3)
    }

    func testSelectedLevelIsClamped() {
        defaults.set(42, forKey: CharacterStore.selectedLevelStorageKey)
        XCTAssertEqual(CharacterStore(defaults: defaults, loadBundledData: false).selectedLevel, 9)

        store.selectedLevel = 0
        XCTAssertEqual(store.selectedLevel, 1)
    }

    func testPinyinSyllableParsing() {
        XCTAssertEqual(PinyinSyllable.parse("fù"), PinyinSyllable(base: "fu", tone: 4))
        XCTAssertEqual(PinyinSyllable.parse("FU2"), PinyinSyllable(base: "fu", tone: 2))
        XCTAssertEqual(PinyinSyllable.parse("lǜ"), PinyinSyllable(base: "lv", tone: 4))
        XCTAssertEqual(PinyinSyllable.parse("lu:3"), PinyinSyllable(base: "lv", tone: 3))
        XCTAssertEqual(PinyinSyllable.parse("ma"), PinyinSyllable(base: "ma", tone: nil))
        XCTAssertNil(PinyinSyllable.parse("4"))
        XCTAssertNil(PinyinSyllable.parse("爱"))
    }
}
