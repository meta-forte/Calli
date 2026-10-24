import SwiftUI

struct CharacterDetailView: View {
    let character: CharacterItem
    let strokeInfo: CharacterStrokeInfo?
    let onPrevious: (() -> Void)?
    let onNext: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var currentStrokeIndex: Int = 0
    @State private var completedStrokes: Set<Int> = []
    @State private var isCompleted: Bool = false
    @StateObject private var audioService = AudioPlayerService.shared

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let margin: CGFloat = 32
                let topBottomSpacing: CGFloat = 220
                let availableWidth = geometry.size.width - margin
                let availableHeight = geometry.size.height - topBottomSpacing
                let canvasDimension = max(240, min(availableWidth, availableHeight))

                VStack(spacing: 12) {
                    characterHeader

                    if let strokeInfo = strokeInfo, !strokeInfo.strokes.isEmpty {
                        StrokeCanvasView(
                            strokeInfo: strokeInfo,
                            canvasSize: canvasDimension,
                            currentStrokeIndex: $currentStrokeIndex,
                            completedStrokes: $completedStrokes,
                            onStrokeCompleted: { _ in },
                            onAllStrokesCompleted: {
                                handleCompletion()
                            }
                        )

                        progressInfo(totalStrokes: strokeInfo.strokes.count)
                    } else {
                        VStack(spacing: 16) {
                            Text(character.hanzi)
                                .font(.system(size: 140))
                                .foregroundColor(Color(red: 0.35, green: 0.36, blue: 0.38))
                            Text("Stroke data unavailable")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: canvasDimension, height: canvasDimension)
                    }

                    controlBar(totalStrokes: strokeInfo?.strokes.count ?? 0)

                    Spacer(minLength: 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("HSK \(character.level)")
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        audioService.playPronunciation(for: character)
                    }) {
                        Image(systemName: audioService.isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .onChange(of: character) {
            resetState()
        }
    }

    private var characterHeader: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(character.pinyin)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)

                if !character.meaning.isEmpty {
                    Text("•  \(character.meaning)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            if !character.exampleChinese.isEmpty {
                Text("\(character.exampleChinese)  \(character.examplePinyin)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.top, 4)
    }

    private func progressInfo(totalStrokes: Int) -> some View {
        HStack {
            if isCompleted {
                Label("Completed!", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.green)
            } else {
                Text("Stroke \(min(currentStrokeIndex + 1, totalStrokes)) of \(totalStrokes)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                autoFillNextStroke(totalStrokes: totalStrokes)
            }) {
                Text(isCompleted ? "Practice Again" : "Trace Next")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 12)
    }

    private func controlBar(totalStrokes: Int) -> some View {
        HStack(spacing: 20) {
            Button(action: {
                onPrevious?()
            }) {
                Image(systemName: "chevron.left.circle")
                    .font(.system(size: 28))
            }
            .disabled(onPrevious == nil)

            Button(action: {
                resetState()
            }) {
                Image(systemName: "arrow.counterclockwise.circle")
                    .font(.system(size: 28))
            }

            Button(action: {
                audioService.playPronunciation(for: character)
            }) {
                Image(systemName: "speaker.wave.2.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.blue)
            }

            Button(action: {
                onNext?()
            }) {
                Image(systemName: "chevron.right.circle")
                    .font(.system(size: 28))
            }
            .disabled(onNext == nil)
        }
        .foregroundColor(.primary)
        .padding(.vertical, 4)
    }

    private func handleCompletion() {
        isCompleted = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        audioService.playPronunciation(for: character)
    }

    private func autoFillNextStroke(totalStrokes: Int) {
        if isCompleted {
            resetState()
            return
        }

        if currentStrokeIndex < totalStrokes {
            completedStrokes.insert(currentStrokeIndex)
            if completedStrokes.count >= totalStrokes {
                handleCompletion()
            } else {
                currentStrokeIndex += 1
            }
        }
    }

    private func resetState() {
        currentStrokeIndex = 0
        completedStrokes.removeAll()
        isCompleted = false
    }
}
