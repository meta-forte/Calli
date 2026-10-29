import SwiftUI

struct CharacterDetailView: View {
    static let tracingFontSizeStorageKey = "kTracingCharacterFontSize"
    static let defaultTracingFontSize: Double = 300.0
    static let minTracingFontSize: Double = 160.0
    static let maxTracingFontSize: Double = 520.0

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
    @AppStorage("selectedGuideMode") private var selectedGuideMode: GuideStrokeMode = .single
    @AppStorage(CharacterDetailView.tracingFontSizeStorageKey) var tracingFontSize: Double = CharacterDetailView.defaultTracingFontSize
    @State var isShowingFontSizeSlider: Bool = false
    @StateObject private var audioService = AudioPlayerService.shared

    private var fontSizeBinding: Binding<Double> {
        Binding(
            get: {
                min(max(tracingFontSize, Self.minTracingFontSize), Self.maxTracingFontSize)
            },
            set: { newValue in
                tracingFontSize = min(max(newValue, Self.minTracingFontSize), Self.maxTracingFontSize)
            }
        )
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let margin: CGFloat = 32
                let topBottomSpacing: CGFloat = isShowingFontSizeSlider ? 300 : 240
                let availableWidth = geometry.size.width - margin
                let availableHeight = geometry.size.height - topBottomSpacing
                let maxAllowedDimension = max(Self.minTracingFontSize, min(availableWidth, availableHeight))
                let canvasDimension = min(max(CGFloat(tracingFontSize), Self.minTracingFontSize), maxAllowedDimension)

                VStack(spacing: 10) {
                    characterHeader

                    if isShowingFontSizeSlider {
                        HStack(spacing: 12) {
                            Text("文")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(white: 0.42))
                                .accessibilityHidden(true)

                            Slider(
                                value: fontSizeBinding,
                                in: Self.minTracingFontSize...max(Self.minTracingFontSize + 40, maxAllowedDimension),
                                step: 5.0
                            )
                            .tint(.blue)
                            .accessibilityLabel("Tracing character font size slider")
                            .accessibilityValue("\(Int(canvasDimension)) pt")

                            Text("文")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(white: 0.42))
                                .accessibilityHidden(true)

                            Text("\(Int(canvasDimension)) pt")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(white: 0.25))
                                .frame(minWidth: 50, alignment: .trailing)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(white: 0.85), lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if let strokeInfo = strokeInfo, !strokeInfo.strokes.isEmpty {
                        StrokeCanvasView(
                            character: character.hanzi,
                            strokeInfo: strokeInfo,
                            canvasSize: canvasDimension,
                            currentStrokeIndex: $currentStrokeIndex,
                            completedUserStrokes: $completedUserStrokes,
                            isCompleted: $isCompleted,
                            mode: selectedGuideMode,
                            onStrokeCompleted: { _ in },
                            onAllStrokesCompleted: {
                                handleCompletion()
                            }
                        )
                        .opacity(canvasOpacity)

                        progressInfo(totalStrokes: strokeInfo.strokes.count, canvasSize: canvasDimension)
                    } else {
                        VStack(spacing: 16) {
                            Text(character.hanzi)
                                .font(.system(size: canvasDimension * 0.58))
                                .foregroundColor(Color(white: 0.35))
                            Text("Stroke data unavailable")
                                .font(.subheadline)
                                .foregroundColor(Color(white: 0.45))
                        }
                        .frame(width: canvasDimension, height: canvasDimension)
                    }

                    actionControls

                    controlBar(totalStrokes: strokeInfo?.strokes.count ?? 0)

                    Spacer(minLength: 6)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
                .onChange(of: canvasDimension) {
                    resetState()
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(white: 0.45))
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("HSK \(character.level)")
                        .font(.headline)
                        .foregroundColor(Color(white: 0.12))
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack(spacing: 10) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowingFontSizeSlider.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "textformat.size")
                                    .font(.system(size: 14, weight: .semibold))

                                Text("\(Int(tracingFontSize)) pt")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(isShowingFontSizeSlider ? .blue : Color(white: 0.30))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isShowingFontSizeSlider ? Color.blue : Color(white: 0.85), lineWidth: 1)
                            )
                        }
                        .accessibilityLabel("Tracing font size options")

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
        }
        .preferredColorScheme(.light)
    }

    private var characterHeader: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(character.pinyin)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(white: 0.12))

                if !character.meaning.isEmpty {
                    Text("•  \(character.meaning)")
                        .font(.subheadline)
                        .foregroundColor(Color(white: 0.42))
                        .lineLimit(1)
                }
            }

            if !character.exampleChinese.isEmpty {
                Text("\(character.exampleChinese)  \(character.examplePinyin)")
                    .font(.footnote)
                    .foregroundColor(Color(white: 0.42))
                    .lineLimit(1)
            }

            HStack(spacing: 6) {
                Image(systemName: "repeat")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Repetitions today: \(todayPracticeCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(white: 0.42))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(white: 0.85), lineWidth: 1)
            )
        }
        .padding(.top, 4)
        .onAppear {
            refreshPracticeCount()
        }
        .onChange(of: character) {
            resetState()
            refreshPracticeCount()
        }
    }

    private func progressInfo(totalStrokes: Int, canvasSize: CGFloat) -> some View {
        HStack {
            if isCompleted {
                Label("Completed! Resetting...", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.green)
            } else {
                Text("Stroke \(min(currentStrokeIndex + 1, totalStrokes)) of \(totalStrokes)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(white: 0.42))
            }

            Spacer()

            Button(action: {
                autoFillNextStroke(totalStrokes: totalStrokes, canvasSize: canvasSize)
            }) {
                Text(isCompleted ? "Repeating..." : "Trace Next")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 12)
    }

    private var actionControls: some View {
        VStack(spacing: 8) {
            modePicker
            eraseAndRepeatButton
        }
    }

    private var modePicker: some View {
        Picker("Guide Mode", selection: $selectedGuideMode) {
            ForEach(GuideStrokeMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 280)
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
            .background(Color.white)
            .foregroundColor(Color(white: 0.15))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(white: 0.85), lineWidth: 1)
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
        .foregroundColor(Color(white: 0.20))
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

    private func autoFillNextStroke(totalStrokes: Int, canvasSize: CGFloat) {
        if isCompleted {
            return
        }

        if currentStrokeIndex < totalStrokes {
            if let strokeInfo = strokeInfo {
                let size = CGSize(width: canvasSize, height: canvasSize)
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
