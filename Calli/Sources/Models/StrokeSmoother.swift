import CoreGraphics

struct StrokeSmoother {
    static func smoothAndCorrect(
        points: [CGPoint],
        median: [CGPoint],
        blendFactor: CGFloat = 0.35,
        maxCorrection: CGFloat = 7.0
    ) -> [CGPoint] {
        guard points.count >= 2 else { return points }

        var filtered: [CGPoint] = [points[0]]
        for pt in points.dropFirst() {
            let last = filtered.last!
            let dx = pt.x - last.x
            let dy = pt.y - last.y
            if (dx * dx + dy * dy) >= 4.0 {
                filtered.append(pt)
            }
        }
        guard filtered.count >= 2 else { return points }

        var smoothed = filtered
        if smoothed.count >= 3 {
            let passes = 2
            for _ in 0..<passes {
                var temp = smoothed
                for i in 1..<(smoothed.count - 1) {
                    let prev = smoothed[i - 1]
                    let curr = smoothed[i]
                    let next = smoothed[i + 1]
                    temp[i] = CGPoint(
                        x: prev.x * 0.25 + curr.x * 0.5 + next.x * 0.25,
                        y: prev.y * 0.25 + curr.y * 0.5 + next.y * 0.25
                    )
                }
                smoothed = temp
            }
        }

        guard !median.isEmpty && smoothed.count >= 3 else { return smoothed }

        var corrected = smoothed
        for i in 1..<(smoothed.count - 1) {
            let pt = smoothed[i]
            let closest = closestPointOnPolyline(pt, polyline: median)
            let dx = closest.x - pt.x
            let dy = closest.y - pt.y
            let dist = (dx * dx + dy * dy).squareRoot()

            if dist > 0 && dist < 50.0 {
                let correctionDist = min(dist * blendFactor, maxCorrection)
                let ratio = correctionDist / dist
                corrected[i] = CGPoint(
                    x: pt.x + dx * ratio,
                    y: pt.y + dy * ratio
                )
            }
        }

        return corrected
    }

    static func isStrokeAcceptable(
        userPoints: [CGPoint],
        median: [CGPoint],
        matchedProgress: Int
    ) -> Bool {
        guard !userPoints.isEmpty && !median.isEmpty else { return false }

        if matchedProgress >= median.count {
            return true
        }

        if median.count <= 2 {
            return matchedProgress >= 1
        }

        let required = max(1, Int(Double(median.count) * 0.6))
        if matchedProgress >= required {
            let userLength = pathLength(points: userPoints)
            let medianLength = pathLength(points: median)
            if userLength >= medianLength * 0.35 {
                return true
            }
        }

        return false
    }

    static func pathLength(points: [CGPoint]) -> CGFloat {
        guard points.count > 1 else { return 0 }
        var total: CGFloat = 0
        for i in 1..<points.count {
            let p1 = points[i - 1]
            let p2 = points[i]
            let dx = p2.x - p1.x
            let dy = p2.y - p1.y
            total += (dx * dx + dy * dy).squareRoot()
        }
        return total
    }

    static func closestPointOnPolyline(_ pt: CGPoint, polyline: [CGPoint]) -> CGPoint {
        guard polyline.count >= 2 else { return polyline.first ?? pt }
        var bestPoint = polyline[0]
        var minDistanceSq: CGFloat = .greatestFiniteMagnitude

        for i in 0..<(polyline.count - 1) {
            let p1 = polyline[i]
            let p2 = polyline[i + 1]
            let proj = projectPointOnSegment(pt, a: p1, b: p2)
            let dx = pt.x - proj.x
            let dy = pt.y - proj.y
            let distSq = dx * dx + dy * dy
            if distSq < minDistanceSq {
                minDistanceSq = distSq
                bestPoint = proj
            }
        }
        return bestPoint
    }

    static func projectPointOnSegment(_ p: CGPoint, a: CGPoint, b: CGPoint) -> CGPoint {
        let abx = b.x - a.x
        let aby = b.y - a.y
        let apx = p.x - a.x
        let apy = p.y - a.y
        let abLenSq = abx * abx + aby * aby
        if abLenSq == 0 { return a }
        let t = max(0, min(1, (apx * abx + apy * aby) / abLenSq))
        return CGPoint(x: a.x + t * abx, y: a.y + t * aby)
    }
}
