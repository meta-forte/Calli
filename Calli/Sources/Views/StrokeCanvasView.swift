import SwiftUI

struct StrokeCanvasView: View {
    let character: String
    let strokeInfo: CharacterStrokeInfo
    let canvasSize: CGFloat
    @Binding var currentStrokeIndex: Int
    @Binding var completedUserStrokes: [[CGPoint]]
    @Binding var isCompleted: Bool
    let onStrokeCompleted: (Int) -> Void
    let onAllStrokesCompleted: () -> Void

    @State private var currentUserPoints: [CGPoint] = []
    @State private var matchedProgress: Int = 0
    @State private var systemTraceProgress: CGFloat = 0.0
    @State private var isDemonstrating: Bool = false
    @State private var idleTimer: Timer? = nil

    private let guideStrokeColor = Color.black
    private let userTraceColor = Color.black
    private let backgroundFontColor = Color(red: 0.35, green: 0.36, blue: 0.38).opacity(0.32)
    private let skeletonColor = Color(red: 0.45, green: 0.46, blue: 0.48).opacity(0.28)

    var body: some View {
        let size = CGSize(width: canvasSize, height: canvasSize)

        ZStack {
            CalligraphyGridView(size: canvasSize)

            Text(character)
                .font(.custom("Noto Sans SC", size: canvasSize * 0.72))
                .foregroundColor(backgroundFontColor)

            ForEach(0..<strokeInfo.medians.count, id: \.self) { idx in
                let median = strokeInfo.medianPoints(strokeIndex: idx, canvasSize: size)
                guidePath(for: median)
                    .stroke(
                        skeletonColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                    )
            }

            ForEach(0..<completedUserStrokes.count, id: \.self) { idx in
                Path { path in
                    path.addLines(completedUserStrokes[idx])
                }
                .stroke(
                    userTraceColor,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                )
            }

            if isDemonstrating && currentStrokeIndex < strokeInfo.strokes.count && !isCompleted {
                let medianPoints = strokeInfo.medianPoints(strokeIndex: currentStrokeIndex, canvasSize: size)
                if !medianPoints.isEmpty {
                    guidePath(for: medianPoints)
                        .trim(from: 0, to: systemTraceProgress)
                        .stroke(
                            guideStrokeColor,
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                        )
                }
            }

            if !currentUserPoints.isEmpty {
                Path { path in
                    path.addLines(currentUserPoints)
                }
                .stroke(
                    userTraceColor,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .frame(width: canvasSize, height: canvasSize)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleDrag(point: value.location, size: size)
                }
                .onEnded { _ in
                    handleDragEnded()
                }
        )
        .onAppear {
            startDemonstration()
        }
        .onDisappear {
            idleTimer?.invalidate()
            idleTimer = nil
        }
        .onChange(of: currentStrokeIndex) {
            currentUserPoints.removeAll()
            matchedProgress = 0
            if !isCompleted {
                startDemonstration()
            }
        }
        .onChange(of: isCompleted) {
            if isCompleted {
                idleTimer?.invalidate()
                idleTimer = nil
                isDemonstrating = false
                systemTraceProgress = 0.0
            }
        }
    }

    private func handleDrag(point: CGPoint, size: CGSize) {
        guard !isCompleted && currentStrokeIndex < strokeInfo.strokes.count else {
            return
        }

        idleTimer?.invalidate()
        idleTimer = nil

        currentUserPoints.append(point)

        let median = strokeInfo.medianPoints(strokeIndex: currentStrokeIndex, canvasSize: size)
        guard !median.isEmpty else { return }

        let evaluation = StrokeMatcher.evaluateTouch(
            touchPoint: point,
            median: median,
            currentProgress: matchedProgress
        )

        matchedProgress = evaluation.newProgress

        if evaluation.isCompleted {
            completeCurrentStroke()
        }
    }

    private func handleDragEnded() {
        guard !isCompleted && currentStrokeIndex < strokeInfo.strokes.count else { return }
        currentUserPoints.removeAll()
        matchedProgress = 0
        startIdleTimer()
    }

    private func completeCurrentStroke() {
        let finishedIndex = currentStrokeIndex
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        completedUserStrokes.append(currentUserPoints)
        currentUserPoints.removeAll()
        matchedProgress = 0
        isDemonstrating = false
        systemTraceProgress = 0.0

        idleTimer?.invalidate()
        idleTimer = nil

        onStrokeCompleted(finishedIndex)

        if completedUserStrokes.count >= strokeInfo.strokes.count {
            onAllStrokesCompleted()
        } else {
            currentStrokeIndex += 1
        }
    }

    private func startDemonstration() {
        guard !isCompleted && currentStrokeIndex < strokeInfo.strokes.count else {
            isDemonstrating = false
            systemTraceProgress = 0.0
            return
        }

        idleTimer?.invalidate()
        idleTimer = nil

        isDemonstrating = true
        systemTraceProgress = 0.0

        withAnimation(Animation.easeInOut(duration: 0.8)) {
            systemTraceProgress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            withAnimation(Animation.easeOut(duration: 0.15)) {
                self.isDemonstrating = false
                self.systemTraceProgress = 0.0
            }
            self.startIdleTimer()
        }
    }

    private func startIdleTimer() {
        idleTimer?.invalidate()
        guard !isCompleted && currentStrokeIndex < strokeInfo.strokes.count else { return }

        idleTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            DispatchQueue.main.async {
                guard !self.isCompleted && self.currentStrokeIndex < self.strokeInfo.strokes.count else { return }
                self.currentUserPoints.removeAll()
                self.matchedProgress = 0
                self.startDemonstration()
            }
        }
    }

    private func guidePath(for points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for pt in points.dropFirst() {
            path.addLine(to: pt)
        }
        return path
    }
}
