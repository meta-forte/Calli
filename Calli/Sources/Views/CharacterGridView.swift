import SwiftUI

struct CharacterGridView: View {
    @EnvironmentObject private var updateService: AppUpdateService
    @StateObject private var store = CharacterStore()
    @State private var selectedCharacter: CharacterItem?
    @State private var isShowingDetail: Bool = false
    @State private var isShowingAbout: Bool = false
    @State private var isShowingLegal: Bool = false
    @State private var isShowingDisplaySettings: Bool = false
    @AppStorage(GridCellSize.storageKey) private var cellSize: GridCellSize = .defaultSize

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topControlBar

                if store.isLoading {
                    Spacer()
                    ProgressView("Loading characters...")
                    Spacer()
                } else if store.displayedCount == 0 {
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
                    characterGrid
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

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isShowingDisplaySettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(white: 0.25))
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Display Settings")
                }
            }
            .sheet(item: $selectedCharacter) { character in
                let stroke = store.strokeInfo(for: character.hanzi)
                let displayed = store.displayedCharacters
                let currentIndex = displayed.firstIndex(of: character)

                CharacterDetailView(
                    character: character,
                    strokeInfo: stroke,
                    onPrevious: previousCharacter(in: displayed, for: currentIndex),
                    onNext: nextCharacter(in: displayed, for: currentIndex)
                )
                .preferredColorScheme(.light)
                .interactiveDismissDisabled()
            }
        }
        .sheet(isPresented: $isShowingDisplaySettings) {
            DisplaySettingsView()
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

    private var characterGrid: some View {
        ScrollView {
            LazyVGrid(columns: cellSize.columns, spacing: GridCellSize.gridSpacing, pinnedViews: [.sectionHeaders]) {
                ForEach(store.sections) { section in
                    Section {
                        ForEach(section.characters) { item in
                            CharacterCellView(
                                character: item,
                                size: cellSize,
                                meaningSubtitle: store.matchedMeaning(for: item)
                            ) {
                                selectedCharacter = item
                                isShowingDetail = true
                            }
                        }
                    } header: {
                        if store.isSearching {
                            sectionHeader(for: section)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, store.isSearching ? 0 : 12)
            .padding(.bottom, 12)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private func sectionHeader(for section: CharacterSection) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(section.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(white: 0.12))
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Text(Self.countLabel(section.characters.count, noun: "character"))
                .font(.footnote)
                .foregroundColor(Color(white: 0.42))
        }
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background(Color.appBackground)
    }

    private var topControlBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(white: 0.45))

                TextField("Search Hanzi, Pinyin, or English word", text: $store.searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 15))
                    .foregroundColor(Color(white: 0.12))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .accessibilityIdentifier("Search Characters")

                if !store.searchQuery.isEmpty {
                    Button(action: {
                        store.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(white: 0.45))
                    }
                    .accessibilityLabel("Clear Search")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(white: 0.85), lineWidth: 1)
            )

            HStack(spacing: 8) {
                Text("HSK Level")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(white: 0.42))

                Menu {
                    ForEach(store.availableLevels, id: \.self) { level in
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
                .accessibilityLabel("HSK Level")
                .accessibilityValue("Level \(store.selectedLevel)")

                Spacer()

                Text(store.isSearching
                     ? Self.countLabel(store.displayedCount, noun: "result")
                     : Self.countLabel(store.displayedCount, noun: "character"))
                    .font(.footnote)
                    .foregroundColor(Color(white: 0.42))
                    .accessibilityIdentifier("Character Count")
            }
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

    private static func countLabel(_ count: Int, noun: String) -> String {
        "\(count) \(noun)\(count == 1 ? "" : "s")"
    }

    private func previousCharacter(in characters: [CharacterItem], for index: Int?) -> (() -> Void)? {
        guard let idx = index, idx > 0 else { return nil }
        return {
            selectedCharacter = characters[idx - 1]
        }
    }

    private func nextCharacter(in characters: [CharacterItem], for index: Int?) -> (() -> Void)? {
        guard let idx = index, idx < characters.count - 1 else { return nil }
        return {
            selectedCharacter = characters[idx + 1]
        }
    }
}
