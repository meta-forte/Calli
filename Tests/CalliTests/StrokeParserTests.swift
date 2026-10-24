import XCTest
import SwiftUI
@testable import Calli

final class StrokeParserTests: XCTestCase {
    func testParseBasicPath() {
        let svg = "M 100 800 L 900 800 Z"
        let canvasSize = CGSize(width: 300, height: 300)
        let path = StrokePathParser.parse(svgPath: svg, canvasSize: canvasSize)

        XCTAssertFalse(path.isEmpty)
    }

    func testParseCurves() {
        let svg = "M 100 800 Q 500 500 900 800 C 800 600 700 400 600 200 Z"
        let canvasSize = CGSize(width: 400, height: 400)
        let path = StrokePathParser.parse(svgPath: svg, canvasSize: canvasSize)

        XCTAssertFalse(path.isEmpty)
    }

    func testMedianPointsTransform() {
        let strokeInfo = CharacterStrokeInfo(
            strokes: ["M 100 800 L 900 800 Z"],
            medians: [[[100, 800], [500, 800], [900, 800]]]
        )
        let canvasSize = CGSize(width: 1024, height: 1024)
        let points = strokeInfo.medianPoints(strokeIndex: 0, canvasSize: canvasSize)

        XCTAssertEqual(points.count, 3)
        XCTAssertEqual(points[0].x, 100, accuracy: 0.1)
        XCTAssertEqual(points[0].y, 100, accuracy: 0.1)
        XCTAssertEqual(points[1].x, 500, accuracy: 0.1)
        XCTAssertEqual(points[1].y, 100, accuracy: 0.1)
        XCTAssertEqual(points[2].x, 900, accuracy: 0.1)
        XCTAssertEqual(points[2].y, 100, accuracy: 0.1)
    }
}
