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
