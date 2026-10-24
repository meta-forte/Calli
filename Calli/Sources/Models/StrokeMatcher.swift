import CoreGraphics

struct StrokeMatcher {
    static let defaultTolerance: CGFloat = 55.0

    static func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return (dx * dx + dy * dy).squareRoot()
    }

    static func evaluateTouch(
        touchPoint: CGPoint,
        median: [CGPoint],
        currentProgress: Int,
        tolerance: CGFloat = defaultTolerance
    ) -> (newProgress: Int, isCompleted: Bool) {
        guard !median.isEmpty else {
            return (0, true)
        }

        if median.count == 1 {
            let dist = distance(touchPoint, median[0])
            let completed = dist <= tolerance
            return (completed ? 1 : 0, completed)
        }

        var progress = currentProgress
        let targetIndex = min(progress, median.count - 1)
        let targetPoint = median[targetIndex]
        let distToTarget = distance(touchPoint, targetPoint)

        if distToTarget <= tolerance {
            progress = min(progress + 1, median.count)
        } else if progress > 0 && progress < median.count {
            let nextIndex = progress
            let distToNext = distance(touchPoint, median[nextIndex])
            if distToNext <= tolerance {
                progress = min(progress + 1, median.count)
            }
        }

        let isCompleted = progress >= median.count

        return (progress, isCompleted)
    }
}
