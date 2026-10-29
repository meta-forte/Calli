import SwiftUI

struct CharacterCellView: View {
    let character: CharacterItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(character.hanzi)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(white: 0.12))

                Text(character.pinyin)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(white: 0.42))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1.0, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(white: 0.85), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(character.hanzi), \(character.pinyin)")
    }
}
