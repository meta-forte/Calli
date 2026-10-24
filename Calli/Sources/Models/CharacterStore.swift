import Foundation
import Combine

class CharacterStore: ObservableObject {
    @Published var allCharacters: [CharacterItem] = []
    @Published var selectedLevel: Int = 1
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false

    private var strokeDatabase: [String: CharacterStrokeInfo] = [:]

    init() {
        loadData()
    }

    var availableLevels: [Int] {
        let levels = Set(allCharacters.map { $0.level })
        return Array(levels).sorted()
    }

    var filteredCharacters: [CharacterItem] {
        let levelFiltered = allCharacters.filter { $0.level == selectedLevel }
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return levelFiltered
        }
        return levelFiltered.filter { item in
            item.hanzi.contains(trimmed) ||
            item.pinyin.localizedCaseInsensitiveContains(trimmed) ||
            item.meaning.localizedCaseInsensitiveContains(trimmed)
        }
    }

    func strokeInfo(for hanzi: String) -> CharacterStrokeInfo? {
        return strokeDatabase[hanzi]
    }

    private func loadData() {
        isLoading = true
        defer { isLoading = false }

        if let charactersURL = Bundle.main.url(forResource: "characters", withExtension: "json") {
            do {
                let data = try Data(contentsOf: charactersURL)
                let items = try JSONDecoder().decode([CharacterItem].self, from: data)
                self.allCharacters = items
            } catch {
                self.allCharacters = []
            }
        }

        if let strokesURL = Bundle.main.url(forResource: "strokes", withExtension: "json") {
            do {
                let data = try Data(contentsOf: strokesURL)
                let strokes = try JSONDecoder().decode([String: CharacterStrokeInfo].self, from: data)
                self.strokeDatabase = strokes
            } catch {
                self.strokeDatabase = [:]
            }
        }
    }

    func loadFromDirectData(characters: [CharacterItem], strokes: [String: CharacterStrokeInfo]) {
        self.allCharacters = characters
        self.strokeDatabase = strokes
    }
}
