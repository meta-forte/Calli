import SwiftUI

struct CharacterGridView: View {
    @StateObject private var store = CharacterStore()
    @State private var selectedCharacter: CharacterItem?
    @State private var isShowingDetail: Bool = false

    private let columns = [
        GridItem(.adaptive(minimum: 64, maximum: 76), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topControlBar

                if store.isLoading {
                    Spacer()
                    ProgressView("Loading characters...")
                    Spacer()
                } else if store.filteredCharacters.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "character.book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No characters found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(store.filteredCharacters) { item in
                                CharacterCellView(character: item) {
                                    selectedCharacter = item
                                    isShowingDetail = true
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Calli")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedCharacter) { character in
                let stroke = store.strokeInfo(for: character.hanzi)
                let currentIndex = store.filteredCharacters.firstIndex(of: character)

                CharacterDetailView(
                    character: character,
                    strokeInfo: stroke,
                    onPrevious: previousCharacter(for: currentIndex),
                    onNext: nextCharacter(for: currentIndex)
                )
            }
        }
    }

    private var topControlBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("HSK Level")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Menu {
                    ForEach(1...9, id: \.self) { level in
                        Button(action: {
                            store.selectedLevel = level
                        }) {
                            HStack {
                                Text("Level \(level)")
                                if store.selectedLevel == level {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Level \(store.selectedLevel)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                }

                Spacer()

                Text("\(store.filteredCharacters.count) characters")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search Hanzi, Pinyin, or Meaning", text: $store.searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 14))

                if !store.searchQuery.isEmpty {
                    Button(action: {
                        store.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.primary.opacity(0.06)),
            alignment: .bottom
        )
    }

    private func previousCharacter(for index: Int?) -> (() -> Void)? {
        guard let idx = index, idx > 0 else { return nil }
        return {
            selectedCharacter = store.filteredCharacters[idx - 1]
        }
    }

    private func nextCharacter(for index: Int?) -> (() -> Void)? {
        guard let idx = index, idx < store.filteredCharacters.count - 1 else { return nil }
        return {
            selectedCharacter = store.filteredCharacters[idx + 1]
        }
    }
}
