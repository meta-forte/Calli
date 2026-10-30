import SwiftUI

struct CharacterCellView: View {
    let character: CharacterItem
    var size: GridCellSize = .defaultSize
    var meaningSubtitle: String? = nil
    let action: () -> Void

    private var hasMeaningSubtitle: Bool {
        if let meaningSubtitle, !meaningSubtitle.isEmpty {
            return true
        }
        return false
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(character.hanzi)
                    .font(.system(size: size.hanziFontSize, weight: .semibold))
                    .foregroundColor(Color(white: 0.12))

                Text(character.pinyin)
                    .font(.system(size: size.pinyinFontSize, weight: .regular))
                    .foregroundColor(Color(white: 0.42))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if let meaningSubtitle, !meaningSubtitle.isEmpty {
                    Text(meaningSubtitle)
                        .font(.system(size: size.meaningFontSize, weight: .medium))
                        .foregroundColor(Color.accessibleBlue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .frame(height: hasMeaningSubtitle ? size.searchCellHeight : size.cellHeight)
            .background(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .strokeBorder(Color(white: 0.85), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: size.cornerRadius))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Self.accessibilityDescription(for: character, meaningSubtitle: meaningSubtitle))
        .accessibilityAddTraits(.isButton)
    }

    static func accessibilityDescription(for character: CharacterItem, meaningSubtitle: String? = nil) -> String {
        let resolvedMeaning: String = {
            if let subtitle = meaningSubtitle?.trimmingCharacters(in: .whitespacesAndNewlines), !subtitle.isEmpty {
                return subtitle
            }
            return character.meaning
        }()
        let levelLabel = character.isHSK ? "HSK Level \(character.level)" : "Other Character"
        if resolvedMeaning.isEmpty {
            return "\(character.hanzi), pinyin \(character.pinyin), \(levelLabel). Double tap to trace."
        }
        return "\(character.hanzi), pinyin \(character.pinyin), meaning \(resolvedMeaning), \(levelLabel). Double tap to trace."
    }
}
