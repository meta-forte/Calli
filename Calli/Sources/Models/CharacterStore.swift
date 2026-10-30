import Foundation
import Combine

class CharacterStore: ObservableObject {
    static let selectedLevelStorageKey = "kSelectedHSKLevel"
    static let defaultLevel = 1

    @Published private(set) var allCharacters: [CharacterItem] = []
    @Published private(set) var otherCharacters: [CharacterItem] = []
    @Published private(set) var sections: [CharacterSection] = []
    @Published private(set) var matchedMeanings: [Int: String] = [:]
    @Published private(set) var isLoading: Bool = false
    @Published var selectedLevel: Int {
        didSet {
            let clamped = Self.clampedLevel(selectedLevel)
            if clamped != selectedLevel {
                selectedLevel = clamped
                return
            }
            defaults.set(selectedLevel, forKey: Self.selectedLevelStorageKey)
            refreshSections()
        }
    }
    @Published var searchQuery: String = "" {
        didSet {
            refreshSections()
        }
    }

    private let defaults: UserDefaults
    private let bundle: Bundle
    private var searchIndex = CharacterSearchIndex(characters: [])
    private var strokeDatabase: [String: CharacterStrokeInfo] = [:]
    private var otherStrokeDatabase: [String: CharacterStrokeInfo]?
    private let otherStrokeQueue = DispatchQueue(label: "com.ibhatech.hanzislate.other-strokes", qos: .utility)

    init(defaults: UserDefaults = .standard, bundle: Bundle = .main, loadBundledData: Bool = true) {
        self.defaults = defaults
        self.bundle = bundle
        self.selectedLevel = Self.clampedLevel(defaults.object(forKey: Self.selectedLevelStorageKey) as? Int ?? Self.defaultLevel)
        if loadBundledData {
            loadData()
        }
    }

    var availableLevels: [Int] {
        Array(CharacterItem.hskLevels)
    }

    var isSearching: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var displayedCharacters: [CharacterItem] {
        sections.flatMap(\.characters)
    }

    var displayedCount: Int {
        sections.reduce(0) { $0 + $1.characters.count }
    }

    func matchedMeaning(for item: CharacterItem) -> String? {
        guard isSearching else { return nil }
        return matchedMeanings[item.id]
    }

    func strokeInfo(for hanzi: String) -> CharacterStrokeInfo? {
        if let info = strokeDatabase[hanzi] {
            return info
        }
        return otherStrokeQueue.sync {
            loadOtherStrokesIfNeeded()
            return otherStrokeDatabase?[hanzi]
        }
    }

    func loadFromDirectData(
        characters: [CharacterItem],
        strokes: [String: CharacterStrokeInfo],
        others: [CharacterItem] = [],
        otherStrokes: [String: CharacterStrokeInfo] = [:]
    ) {
        allCharacters = characters
        otherCharacters = others
        strokeDatabase = strokes
        otherStrokeQueue.sync {
            otherStrokeDatabase = otherStrokes
        }
        rebuildIndex()
    }

    private static func clampedLevel(_ level: Int) -> Int {
        min(max(level, CharacterItem.hskLevels.lowerBound), CharacterItem.hskLevels.upperBound)
    }

    private func refreshSections() {
        if isSearching {
            let result = searchIndex.searchWithContext(searchQuery)
            sections = result.sections
            matchedMeanings = result.matchedMeanings
        } else {
            let levelCharacters = allCharacters.filter { $0.level == selectedLevel }
            sections = [CharacterSection(level: selectedLevel, characters: levelCharacters)]
            matchedMeanings = [:]
        }
    }

    private func rebuildIndex() {
        searchIndex = CharacterSearchIndex(characters: allCharacters + otherCharacters)
        refreshSections()
    }

    private func loadData() {
        isLoading = true
        defer { isLoading = false }

        allCharacters = decode([CharacterItem].self, resource: "characters") ?? []
        otherCharacters = decode([CharacterItem].self, resource: "others") ?? []
        strokeDatabase = decode([String: CharacterStrokeInfo].self, resource: "strokes") ?? [:]
        rebuildIndex()

        otherStrokeQueue.async { [weak self] in
            self?.loadOtherStrokesIfNeeded()
        }
    }

    private func loadOtherStrokesIfNeeded() {
        dispatchPrecondition(condition: .onQueue(otherStrokeQueue))
        guard otherStrokeDatabase == nil else { return }
        otherStrokeDatabase = decode([String: CharacterStrokeInfo].self, resource: "others_strokes") ?? [:]
    }

    private func decode<T: Decodable>(_ type: T.Type, resource: String) -> T? {
        guard let url = bundle.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
