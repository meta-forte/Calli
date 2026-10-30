import SwiftUI

struct DisplaySettingsView: View {
    @AppStorage(GridCellSize.storageKey) private var cellSize: GridCellSize = .defaultSize
    @Environment(\.dismiss) private var dismiss

    private let previewCharacters: [CharacterItem] = [
        CharacterItem(id: -1, level: 1, hanzi: "爱", pinyin: "ài", tones: "4", meaning: "", exampleChinese: "", examplePinyin: "", exampleEnglish: ""),
        CharacterItem(id: -2, level: 1, hanzi: "床", pinyin: "chuáng", tones: "2", meaning: "", exampleChinese: "", examplePinyin: "", exampleEnglish: ""),
        CharacterItem(id: -3, level: 1, hanzi: "都", pinyin: "dōu, dū", tones: "1", meaning: "", exampleChinese: "", examplePinyin: "", exampleEnglish: "")
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Character Size")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(white: 0.42))

                Picker("Character Size", selection: $cellSize) {
                    ForEach(GridCellSize.allCases) { size in
                        Text(size.title).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("Character Size")

                HStack(spacing: GridCellSize.gridSpacing) {
                    ForEach(previewCharacters) { item in
                        CharacterCellView(character: item, size: cellSize) {}
                            .frame(width: cellSize.minimumCellWidth + 8)
                            .allowsHitTesting(false)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: GridCellSize.large.cellHeight)
                .animation(.easeInOut(duration: 0.2), value: cellSize)
                .accessibilityHidden(true)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Display")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.light)
    }
}
