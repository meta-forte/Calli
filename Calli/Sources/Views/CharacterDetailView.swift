import SwiftUI

struct CharacterDetailView: View {
    let character: CharacterItem
    let strokeInfo: CharacterStrokeInfo?
    let onPrevious: (() -> Void)?
    let onNext: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var currentStrokeIndex: Int = 0
    @State private var completedUserStrokes: [[CGPoint]] = []
    @State private var isCompleted: Bool = false
    @State private var todayPracticeCount: Int = 0
    @State private var canvasOpacity: Double = 1.0
    @StateObject private var audioService = AudioPlayerService.shared

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let margin: CGFloat = 32
                let topBottomSpacing: CGFloat = 240
                let availableWidth = geometry.size.width - margin
                let availableHeight = geometry.size.height - topBottomSpacing
                let canvasDimension = max(240, min(availableWidth, availableHeight))

                VStack(spacing: 10) {
                    characterHeader

                    if let strokeInfo = strokeInfo, !strokeInfo.strokes.isEmpty {
                        StrokeCanvasView(
                            character: character.hanzi,
                            strokeInfo: strokeInfo,
                            canvasSize: canvasDimension,
                            currentStrokeIndex: $currentStrokeIndex,
                            completedUserStrokes: $completedUserStrokes,
                            isCompleted: $isCompleted,
                            onStrokeCompleted: { _ in },
                            onAllStrokesCompleted: {
                                handleCompletion()
                            }
                        )
                        .opacity(canvasOpacity)

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

                    eraseAndRepeatButton

                    controlBar(totalStrokes: strokeInfo?.strokes.count ?? 0)

                    Spacer(minLength: 6)
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
        .onAppear {
            refreshPracticeCount()
        }
        .onChange(of: character) {
            resetState()
            refreshPracticeCount()
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

            HStack(spacing: 6) {
                Image(systemName: "repeat")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Repetitions today: \(todayPracticeCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding(.top, 4)
    }

    private func progressInfo(totalStrokes: Int) -> some View {
        HStack {
            if isCompleted {
                Label("Completed! Resetting...", systemImage: "checkmark.seal.fill")
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
                Text(isCompleted ? "Repeating..." : "Trace Next")
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

    private var eraseAndRepeatButton: some View {
        Button(action: {
            performAnimatedErase()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "eraser.fill")
                    .font(.system(size: 13))
                Text("Erase and Repeat")
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color(UIColor.secondarySystemBackground))
            .foregroundColor(.primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private func controlBar(totalStrokes: Int) -> some View {
        HStack(spacing: 24) {
            Button(action: {
                onPrevious?()
            }) {
                Image(systemName: "chevron.left.circle")
                    .font(.system(size: 28))
            }
            .disabled(onPrevious == nil)

            Button(action: {
                performAnimatedErase()
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
        .padding(.vertical, 2)
    }

    private func handleCompletion() {
        isCompleted = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        todayPracticeCount = PracticeStorageService.shared.recordPractice(character: character.hanzi)
        audioService.playPronunciation(for: character)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(Animation.easeInOut(duration: 0.45)) {
                self.canvasOpacity = 0.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.resetState()
                withAnimation(Animation.easeInOut(duration: 0.45)) {
                    self.canvasOpacity = 1.0
                }
            }
        }
    }

    private func autoFillNextStroke(totalStrokes: Int) {
        if isCompleted {
            return
        }

        if currentStrokeIndex < totalStrokes {
            if let strokeInfo = strokeInfo {
                let size = CGSize(width: 300, height: 300)
                let median = strokeInfo.medianPoints(strokeIndex: currentStrokeIndex, canvasSize: size)
                completedUserStrokes.append(median)
            }

            if completedUserStrokes.count >= totalStrokes {
                handleCompletion()
            } else {
                currentStrokeIndex += 1
            }
        }
    }

    private func performAnimatedErase() {
        withAnimation(Animation.easeOut(duration: 0.2)) {
            canvasOpacity = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            resetState()
            withAnimation(Animation.easeIn(duration: 0.2)) {
                canvasOpacity = 1.0
            }
        }
    }

    private func resetState() {
        currentStrokeIndex = 0
        completedUserStrokes.removeAll()
        isCompleted = false
    }

    private func refreshPracticeCount() {
        todayPracticeCount = PracticeStorageService.shared.getPracticeCount(character: character.hanzi)
    }
}
