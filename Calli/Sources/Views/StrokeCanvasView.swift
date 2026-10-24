import SwiftUI

struct StrokeCanvasView: View {
    let strokeInfo: CharacterStrokeInfo
    let canvasSize: CGFloat
    @Binding var currentStrokeIndex: Int
    @Binding var completedStrokes: Set<Int>
    let onStrokeCompleted: (Int) -> Void
    let onAllStrokesCompleted: () -> Void

    @State private var userTouchPoints: [CGPoint] = []
    @State private var matchedProgress: Int = 0
    @State private var guideAnimationPhase: CGFloat = 0.0

    private let darkGrayColor = Color(red: 0.35, green: 0.36, blue: 0.38)
    private let completedColor = Color(red: 0.15, green: 0.48, blue: 0.92)
    private let activeGuideColor = Color(red: 0.98, green: 0.45, blue: 0.12)
    private let userTraceColor = Color(red: 0.98, green: 0.35, blue: 0.15)

    var body: some View {
        let size = CGSize(width: canvasSize, height: canvasSize)

        ZStack {
            CalligraphyGridView(size: canvasSize)

            ForEach(0..<strokeInfo.strokes.count, id: \.self) { index in
                let path = StrokePathParser.parse(svgPath: strokeInfo.strokes[index], canvasSize: size)

                if completedStrokes.contains(index) {
                    path.fill(completedColor)
                } else if index == currentStrokeIndex {
                    path.fill(darkGrayColor)
                    path.stroke(activeGuideColor.opacity(0.6), lineWidth: 2)
                } else {
                    path.fill(darkGrayColor)
                }
            }

            if currentStrokeIndex < strokeInfo.strokes.count {
                let medianPoints = strokeInfo.medianPoints(strokeIndex: currentStrokeIndex, canvasSize: size)
                if !medianPoints.isEmpty {
                    guidePath(for: medianPoints)
                        .trim(from: 0, to: guideAnimationPhase)
                        .stroke(
                            activeGuideColor,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                        )

                    if let guidePoint = pointAlong(points: medianPoints, progress: guideAnimationPhase) {
                        Circle()
                            .fill(activeGuideColor)
                            .frame(width: 14, height: 14)
                            .shadow(color: activeGuideColor.opacity(0.8), radius: 6)
                            .position(guidePoint)
                    }
                }
            }

            if !userTouchPoints.isEmpty {
                Path { path in
                    path.addLines(userTouchPoints)
                }
                .stroke(
                    userTraceColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
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
                    userTouchPoints.removeAll()
                    matchedProgress = 0
                }
        )
        .onAppear {
            startGuideAnimation()
        }
        .onChange(of: currentStrokeIndex) {
            userTouchPoints.removeAll()
            matchedProgress = 0
            startGuideAnimation()
        }
    }

    private func handleDrag(point: CGPoint, size: CGSize) {
        guard currentStrokeIndex < strokeInfo.strokes.count else { return }

        userTouchPoints.append(point)

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

    private func completeCurrentStroke() {
        let finishedIndex = currentStrokeIndex
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        completedStrokes.insert(finishedIndex)
        userTouchPoints.removeAll()
        matchedProgress = 0

        onStrokeCompleted(finishedIndex)

        if completedStrokes.count >= strokeInfo.strokes.count {
            onAllStrokesCompleted()
        } else {
            currentStrokeIndex += 1
        }
    }

    private func startGuideAnimation() {
        guideAnimationPhase = 0.0
        withAnimation(
            Animation.easeInOut(duration: 1.4)
                .repeatForever(autoreverses: false)
        ) {
            guideAnimationPhase = 1.0
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

    private func pointAlong(points: [CGPoint], progress: CGFloat) -> CGPoint? {
        guard !points.isEmpty else { return nil }
        if points.count == 1 || progress <= 0 { return points.first }
        if progress >= 1.0 { return points.last }

        var totalLength: CGFloat = 0
        var lengths: [CGFloat] = [0]

        for i in 1..<points.count {
            let dist = StrokeMatcher.distance(points[i - 1], points[i])
            totalLength += dist
            lengths.append(totalLength)
        }

        if totalLength == 0 { return points.first }

        let targetDist = progress * totalLength

        for i in 1..<lengths.count {
            if lengths[i] >= targetDist {
                let segmentStart = lengths[i - 1]
                let segmentEnd = lengths[i]
                let segmentLength = segmentEnd - segmentStart
                let segmentProgress = segmentLength > 0 ? (targetDist - segmentStart) / segmentLength : 0
                let p1 = points[i - 1]
                let p2 = points[i]
                return CGPoint(
                    x: p1.x + (p2.x - p1.x) * segmentProgress,
                    y: p1.y + (p2.y - p1.y) * segmentProgress
                )
            }
        }

        return points.last
    }
}
