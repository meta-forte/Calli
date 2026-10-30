import Foundation

struct CharacterItem: Identifiable, Codable, Hashable {
    let id: Int
    let level: Int
    let hanzi: String
    let pinyin: String
    let tones: String
    let meaning: String
    let exampleChinese: String
    let examplePinyin: String
    let exampleEnglish: String
}

extension CharacterItem {
    static let othersLevel = 0
    static let hskLevels = 1...9

    var isHSK: Bool { Self.hskLevels.contains(level) }
    var levelTitle: String { Self.title(forLevel: level) }

    static func title(forLevel level: Int) -> String {
        hskLevels.contains(level) ? "HSK \(level)" : "Others"
    }

    static func levelPrecedes(_ lhs: Int, _ rhs: Int) -> Bool {
        let lhsIsHSK = hskLevels.contains(lhs)
        let rhsIsHSK = hskLevels.contains(rhs)
        if lhsIsHSK != rhsIsHSK {
            return lhsIsHSK
        }
        return lhs < rhs
    }
}
