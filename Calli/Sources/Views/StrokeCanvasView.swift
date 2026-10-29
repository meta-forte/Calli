import SwiftUI

struct StrokeCanvasView: View {
    let character: String
    let strokeInfo: CharacterStrokeInfo
    let canvasSize: CGFloat
    @Binding var currentStrokeIndex: Int
    @Binding var completedUserStrokes: [[CGPoint]]
    @Binding var isCompleted: Bool
    var mode: GuideStrokeMode = .single
    let onStrokeCompleted: (Int) -> Void
    let onAllStrokesCompleted: () -> Void

    @State private var currentUserPoints: [CGPoint] = []
    @State private var matchedProgress: Int = 0
    @State private var hasReachedTarget: Bool = false
    @State private var strokeProgresses: [Int: CGFloat] = [:]
    @State private var demonstrationOpacity: Double = 1.0
    @State private var isDemonstrating: Bool = false
    @State private var idleTimer: Timer? = nil
    @State private var currentDemonstrationId: UUID = UUID()
    @State private var scheduledWorkItems: [DispatchWorkItem] = []

    private let userTraceColor = Color.black
    private let backgroundFontColor = Color(red: 0.70, green: 0.70, blue: 0.72)

    private var strokeWidth: CGFloat {
        max(6, canvasSize * 0.032)
    }

    private func guideColor(forStep step: Int, totalSteps: Int) -> Color {
        guard totalSteps > 1 else {
            return Color(hue: 0.598, saturation: 0.83, brightness: 0.90)
        }
        let fraction = Double(step) / Double(totalSteps - 1)
        let brightness = 0.90 - fraction * (0.90 - 0.48)
        return Color(hue: 0.598, saturation: 0.83, brightness: brightness)
    }

    var body: some View {
        let size = CGSize(width: canvasSize, height: canvasSize)

        ZStack {
            CalligraphyGridView(size: canvasSize)

            if !strokeInfo.strokes.isEmpty {
                backgroundCharacterPath(for: size)
                    .fill(backgroundFontColor)
            } else if let glyphPath = NotoGlyphProvider.path(for: character, canvasSize: size) {
                glyphPath
                    .fill(backgroundFontColor)
            } else {
                Text(character)
                    .font(.custom("Noto Sans SC", size: canvasSize * 0.72))
                    .foregroundColor(backgroundFontColor)
            }

            ForEach(0..<completedUserStrokes.count, id: \.self) { idx in
                smoothPath(for: completedUserStrokes[idx])
                    .stroke(
                        userTraceColor,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
                    )
            }

            if !isCompleted {
                let group = strokeInfo.activeGroup(for: currentStrokeIndex, mode: mode)
                if mode == .single {
                    if isDemonstrating, currentStrokeIndex < strokeInfo.strokes.count {
                        let median = strokeInfo.medianPoints(strokeIndex: currentStrokeIndex, canvasSize: size)
                        let progress = strokeProgresses[currentStrokeIndex] ?? 0.0
                        GuideStrokeView(
                            path: smoothPath(for: median),
                            progress: progress,
                            color: guideColor(forStep: 0, totalSteps: 1),
                            strokeWidth: strokeWidth
                        )
                        .opacity(demonstrationOpacity)
                    }
                } else {
                    ForEach(group.filter { $0 >= currentStrokeIndex }, id: \.self) { strokeIdx in
                        let median = strokeInfo.medianPoints(strokeIndex: strokeIdx, canvasSize: size)
                        let progress = isDemonstrating ? (strokeProgresses[strokeIdx] ?? 0.0) : 1.0
                        let step = group.firstIndex(of: strokeIdx) ?? 0
                        let color = guideColor(forStep: step, totalSteps: group.count)
                        GuideStrokeView(
                            path: smoothPath(for: median),
                            progress: progress,
                            color: color,
                            strokeWidth: strokeWidth
                        )
                    }
                }
            }

            if !currentUserPoints.isEmpty {
                smoothPath(for: currentUserPoints)
                    .stroke(
                        userTraceColor,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
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
                    handleDragEnded(size: size)
                }
        )
        .onAppear {
            startDemonstration()
        }
        .onDisappear {
            cancelDemonstration()
        }
        .onChange(of: currentStrokeIndex) {
            currentUserPoints.removeAll()
            matchedProgress = 0
            hasReachedTarget = false
            if !isCompleted {
                let group = strokeInfo.activeGroup(for: currentStrokeIndex, mode: mode)
                let isGroupStart = (group.first == currentStrokeIndex)
                if mode == .single || isGroupStart {
                    startDemonstration()
                } else {
                    cancelDemonstration()
                    startIdleTimer()
                }
            }
        }
        .onChange(of: mode) {
            currentUserPoints.removeAll()
            matchedProgress = 0
            hasReachedTarget = false
            if !isCompleted {
                startDemonstration()
            }
        }
        .onChange(of: isCompleted) {
            if isCompleted {
                cancelDemonstration()
            }
        }
    }

    private func backgroundCharacterPath(for size: CGSize) -> Path {
        var combined = Path()
        for svg in strokeInfo.strokes {
            combined.addPath(StrokePathParser.parse(svgPath: svg, canvasSize: size))
        }
        return combined
    }

    private func cancelDemonstration() {
        currentDemonstrationId = UUID()
        scheduledWorkItems.forEach { $0.cancel() }
        scheduledWorkItems.removeAll()
        idleTimer?.invalidate()
        idleTimer = nil
        isDemonstrating = false
        if mode == .single {
            strokeProgresses.removeAll()
        } else {
            let group = strokeInfo.activeGroup(for: currentStrokeIndex, mode: mode)
            for s in group {
                strokeProgresses[s] = 1.0
            }
        }
        demonstrationOpacity = 1.0
    }

    private func handleDrag(point: CGPoint, size: CGSize) {
        guard !isCompleted && currentStrokeIndex < strokeInfo.strokes.count else {
            return
        }

        if isDemonstrating {
            cancelDemonstration()
        } else {
            idleTimer?.invalidate()
            idleTimer = nil
        }

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
            hasReachedTarget = true
        }
    }

    private func handleDragEnded(size: CGSize) {
        guard !isCompleted && currentStrokeIndex < strokeInfo.strokes.count else { return }

        let median = strokeInfo.medianPoints(strokeIndex: currentStrokeIndex, canvasSize: size)
        let acceptable = hasReachedTarget || StrokeSmoother.isStrokeAcceptable(
            userPoints: currentUserPoints,
            median: median,
            matchedProgress: matchedProgress
        )

        if acceptable && !currentUserPoints.isEmpty {
            let corrected = StrokeSmoother.smoothAndCorrect(points: currentUserPoints, median: median)
            completeCurrentStroke(with: corrected)
        } else {
            currentUserPoints.removeAll()
            matchedProgress = 0
            hasReachedTarget = false
            startIdleTimer()
        }
    }

    private func completeCurrentStroke(with points: [CGPoint]) {
        let finishedIndex = currentStrokeIndex
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        cancelDemonstration()

        completedUserStrokes.append(points)
        currentUserPoints.removeAll()
        matchedProgress = 0
        hasReachedTarget = false

        onStrokeCompleted(finishedIndex)

        if completedUserStrokes.count >= strokeInfo.strokes.count {
            onAllStrokesCompleted()
        } else {
            currentStrokeIndex += 1
        }
    }

    private func startDemonstration() {
        guard !isCompleted && currentStrokeIndex < strokeInfo.strokes.count else {
            cancelDemonstration()
            return
        }

        cancelDemonstration()

        let token = UUID()
        currentDemonstrationId = token
        isDemonstrating = true
        demonstrationOpacity = 1.0

        let group = strokeInfo.activeGroup(for: currentStrokeIndex, mode: mode)
        let strokesToAnimate = group.filter { $0 >= currentStrokeIndex }

        guard !strokesToAnimate.isEmpty else {
            isDemonstrating = false
            return
        }

        for s in strokesToAnimate {
            strokeProgresses[s] = 0.0
        }

        if mode == .single {
            withAnimation(Animation.easeInOut(duration: 0.75)) {
                self.strokeProgresses[self.currentStrokeIndex] = 1.0
            }

            let fadeItem = DispatchWorkItem {
                guard self.currentDemonstrationId == token else { return }
                withAnimation(Animation.easeOut(duration: 0.25)) {
                    self.demonstrationOpacity = 0.0
                }
            }
            scheduledWorkItems.append(fadeItem)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.95, execute: fadeItem)

            let finishItem = DispatchWorkItem {
                guard self.currentDemonstrationId == token else { return }
                self.isDemonstrating = false
                self.strokeProgresses[self.currentStrokeIndex] = 0.0
                self.demonstrationOpacity = 1.0
                self.startIdleTimer()
            }
            scheduledWorkItems.append(finishItem)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.23, execute: finishItem)
        } else {
            let singleStrokeDuration: Double = 0.38
            let gap: Double = 0.04
            let stride = singleStrokeDuration + gap

            for (order, strokeIdx) in strokesToAnimate.enumerated() {
                if order == 0 {
                    withAnimation(Animation.easeInOut(duration: singleStrokeDuration)) {
                        self.strokeProgresses[strokeIdx] = 1.0
                    }
                } else {
                    let delay = Double(order) * stride
                    let item = DispatchWorkItem {
                        guard self.currentDemonstrationId == token else { return }
                        withAnimation(Animation.easeInOut(duration: singleStrokeDuration)) {
                            self.strokeProgresses[strokeIdx] = 1.0
                        }
                    }
                    scheduledWorkItems.append(item)
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
                }
            }

            let totalDuration = Double(strokesToAnimate.count) * stride + 0.05
            let finishItem = DispatchWorkItem {
                guard self.currentDemonstrationId == token else { return }
                self.isDemonstrating = false
                for s in strokesToAnimate {
                    self.strokeProgresses[s] = 1.0
                }
                self.startIdleTimer()
            }
            scheduledWorkItems.append(finishItem)
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration, execute: finishItem)
        }
    }

    private func startIdleTimer() {
        idleTimer?.invalidate()
        guard !isCompleted && currentStrokeIndex < strokeInfo.strokes.count else { return }

        let token = currentDemonstrationId
        idleTimer = Timer.scheduledTimer(withTimeInterval: 4.5, repeats: false) { _ in
            DispatchQueue.main.async {
                guard !self.isCompleted,
                      self.currentStrokeIndex < self.strokeInfo.strokes.count,
                      self.currentUserPoints.isEmpty,
                      self.currentDemonstrationId == token else { return }
                self.matchedProgress = 0
                self.hasReachedTarget = false
                self.startDemonstration()
            }
        }
    }

    private func smoothPath(for points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        if points.count == 1 {
            path.addLine(to: first)
        } else if points.count == 2 {
            path.addLine(to: points[1])
        } else {
            for i in 1..<points.count - 1 {
                let mid = CGPoint(
                    x: (points[i].x + points[i + 1].x) / 2.0,
                    y: (points[i].y + points[i + 1].y) / 2.0
                )
                path.addQuadCurve(to: mid, control: points[i])
            }
            if let last = points.last {
                path.addLine(to: last)
            }
        }
        return path
    }
}

private struct GuideStrokeView: View, Animatable {
    let path: Path
    var progress: CGFloat
    let color: Color
    let strokeWidth: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        path
            .trim(from: 0, to: progress)
            .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
    }
}