import SwiftUI

struct CharacterGridView: View {
    @EnvironmentObject private var updateService: AppUpdateService
    @StateObject private var store = CharacterStore()
    @State private var selectedCharacter: CharacterItem?
    @State private var isShowingDetail: Bool = false
    @State private var isShowingAbout: Bool = false
    @State private var isShowingLegal: Bool = false

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
                            .foregroundColor(Color(white: 0.50))
                        Text("No characters found")
                            .font(.headline)
                            .foregroundColor(Color(white: 0.42))
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("HanziSlate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button(action: {
                            updateService.showUpdateSheet = true
                            Task {
                                await updateService.checkForUpdates()
                            }
                        }) {
                            Label(
                                updateService.hasUnreadUpdate ? "Update Available" : "Check for Updates",
                                systemImage: updateService.hasUnreadUpdate ? "bell.badge.fill" : "bell"
                            )
                        }

                        Button(action: {
                            isShowingAbout = true
                        }) {
                            Label("About", systemImage: "info.circle")
                        }

                        Button(action: {
                            isShowingLegal = true
                        }) {
                            Label("Legal", systemImage: "doc.text")
                        }
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color(white: 0.25))

                            if updateService.hasUnreadUpdate {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Main Menu")
                }

                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 26, height: 26)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        Text("HanziSlate")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(white: 0.12))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("HanziSlate")
                }
            }
            .sheet(item: $selectedCharacter) { character in
                let stroke = store.strokeInfo(for: character.hanzi)
                let currentIndex = store.filteredCharacters.firstIndex(of: character)

                CharacterDetailView(
                    character: character,
                    strokeInfo: stroke,
                    onPrevious: previousCharacter(for: currentIndex),
                    onNext: nextCharacter(for: currentIndex)
                )
                .preferredColorScheme(.light)
                .interactiveDismissDisabled()
            }
        }
        .sheet(isPresented: $isShowingAbout) {
            AboutView()
                .environmentObject(updateService)
        }
        .sheet(isPresented: $isShowingLegal) {
            LegalView()
        }
        .sheet(isPresented: $updateService.showUpdateSheet) {
            UpdateSheetView(updateService: updateService)
        }
        .overlay {
            if updateService.isForcedUpdate {
                ForcedUpdateView(updateService: updateService)
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .preferredColorScheme(.light)
    }

    private var topControlBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("HSK Level")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(white: 0.42))

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
                            .foregroundColor(Color(white: 0.12))

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(white: 0.85), lineWidth: 1)
                    )
                }

                Spacer()

                Text("\(store.filteredCharacters.count) characters")
                    .font(.footnote)
                    .foregroundColor(Color(white: 0.42))
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(white: 0.45))

                TextField("Search Hanzi, Pinyin, or Meaning", text: $store.searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.12))

                if !store.searchQuery.isEmpty {
                    Button(action: {
                        store.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(white: 0.45))
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(white: 0.85), lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Color.appBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.black.opacity(0.06)),
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
