import XCTest
import CoreGraphics
@testable import Calli

final class StrokeSmootherTests: XCTestCase {
    func testVibrationSmoothing() {
        let userPoints = [
            CGPoint(x: 10, y: 50),
            CGPoint(x: 20, y: 55),
            CGPoint(x: 30, y: 45),
            CGPoint(x: 40, y: 55),
            CGPoint(x: 50, y: 45),
            CGPoint(x: 60, y: 50)
        ]
        let median = [
            CGPoint(x: 10, y: 50),
            CGPoint(x: 60, y: 50)
        ]

        let smoothed = StrokeSmoother.smoothAndCorrect(points: userPoints, median: median)
        XCTAssertEqual(smoothed.count, userPoints.count)
        XCTAssertEqual(smoothed.first?.x, userPoints.first?.x)
        XCTAssertEqual(smoothed.first?.y, userPoints.first?.y)
        XCTAssertEqual(smoothed.last?.x, userPoints.last?.x)
        XCTAssertEqual(smoothed.last?.y, userPoints.last?.y)

        for i in 1..<(smoothed.count - 1) {
            let deviation = abs(smoothed[i].y - 50.0)
            XCTAssertLessThan(deviation, 3.5)
        }
    }

    func testLengthPreservationWhenLonger() {
        let userPoints = [
            CGPoint(x: 0, y: 50),
            CGPoint(x: 25, y: 50),
            CGPoint(x: 50, y: 50),
            CGPoint(x: 75, y: 50),
            CGPoint(x: 100, y: 50)
        ]
        let median = [
            CGPoint(x: 20, y: 50),
            CGPoint(x: 80, y: 50)
        ]

        let smoothed = StrokeSmoother.smoothAndCorrect(points: userPoints, median: median)
        XCTAssertEqual(smoothed.first?.x, 0)
        XCTAssertEqual(smoothed.last?.x, 100)
    }

    func testLengthPreservationWhenShorter() {
        let userPoints = [
            CGPoint(x: 30, y: 50),
            CGPoint(x: 50, y: 50),
            CGPoint(x: 70, y: 50)
        ]
        let median = [
            CGPoint(x: 10, y: 50),
            CGPoint(x: 90, y: 50)
        ]

        let smoothed = StrokeSmoother.smoothAndCorrect(points: userPoints, median: median)
        XCTAssertEqual(smoothed.first?.x, 30)
        XCTAssertEqual(smoothed.last?.x, 70)
    }

    func testMinorCorrectionTowardMedian() {
        let userPoints = [
            CGPoint(x: 10, y: 50),
            CGPoint(x: 50, y: 60),
            CGPoint(x: 90, y: 50)
        ]
        let median = [
            CGPoint(x: 10, y: 50),
            CGPoint(x: 90, y: 50)
        ]

        let smoothed = StrokeSmoother.smoothAndCorrect(points: userPoints, median: median, blendFactor: 0.35, maxCorrection: 7.0)
        XCTAssertEqual(smoothed[0].y, 50)
        XCTAssertEqual(smoothed[2].y, 50)
        XCTAssertLessThan(smoothed[1].y, 60)
        XCTAssertGreaterThan(smoothed[1].y, 50)
    }

    func testStrokeAcceptance() {
        let median = [
            CGPoint(x: 10, y: 50),
            CGPoint(x: 50, y: 50),
            CGPoint(x: 90, y: 50)
        ]
        let userPoints = [
            CGPoint(x: 10, y: 50),
            CGPoint(x: 50, y: 50),
            CGPoint(x: 90, y: 50)
        ]

        XCTAssertTrue(StrokeSmoother.isStrokeAcceptable(userPoints: userPoints, median: median, matchedProgress: 3))
        XCTAssertTrue(StrokeSmoother.isStrokeAcceptable(userPoints: userPoints, median: median, matchedProgress: 2))
        XCTAssertFalse(StrokeSmoother.isStrokeAcceptable(userPoints: userPoints, median: median, matchedProgress: 0))
    }
}
