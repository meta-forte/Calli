import Foundation
import CoreGraphics

enum GuideStrokeMode: String, CaseIterable, Identifiable, Codable {
    case single = "Single"
    case pairwise = "Pair"
    case component = "Component"

    var id: String { rawValue }
}

struct CharacterStrokeInfo: Codable {
    let strokes: [String]
    let medians: [[[Double]]]
    let components: [[Int]]?

    init(strokes: [String], medians: [[[Double]]], components: [[Int]]? = nil) {
        self.strokes = strokes
        self.medians = medians
        self.components = components
    }

    func medianPoints(strokeIndex: Int, canvasSize: CGSize) -> [CGPoint] {
        guard strokeIndex >= 0 && strokeIndex < medians.count else { return [] }
        let strokeMedian = medians[strokeIndex]
        let side = min(canvasSize.width, canvasSize.height)
        let scale = side / 1024.0
        let offsetX = (canvasSize.width - side) / 2.0
        let offsetY = (canvasSize.height - side) / 2.0

        return strokeMedian.compactMap { point in
            guard point.count >= 2 else { return nil }
            let x = point[0]
            let y = point[1]
            let screenX = offsetX + x * scale
            let screenY = offsetY + (900.0 - y) * scale
            return CGPoint(x: screenX, y: screenY)
        }
    }

    func activeGroup(for strokeIndex: Int, mode: GuideStrokeMode) -> [Int] {
        guard strokeIndex >= 0 && strokeIndex < strokes.count else { return [] }
        switch mode {
        case .single:
            return [strokeIndex]
        case .pairwise:
            let first = (strokeIndex / 2) * 2
            let second = first + 1
            if second < strokes.count {
                return [first, second]
            }
            return [first]
        case .component:
            if let components = components, !components.isEmpty {
                for group in components {
                    if group.contains(strokeIndex) {
                        return group
                    }
                }
            }
            return [strokeIndex]
        }
    }

    func activePair(for strokeIndex: Int) -> (first: Int, second: Int?)? {
        guard strokeIndex >= 0 && strokeIndex < strokes.count else { return nil }
        let first = (strokeIndex / 2) * 2
        let secondCandidate = first + 1
        let second = secondCandidate < strokes.count ? secondCandidate : nil
        return (first: first, second: second)
    }
}
