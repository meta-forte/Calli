import Foundation
import CoreGraphics

struct CharacterStrokeInfo: Codable {
    let strokes: [String]
    let medians: [[[Double]]]

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
}
