import XCTest
import CoreGraphics
@testable import Calli

final class StrokeMatcherTests: XCTestCase {
    func testStraightStrokeProgress() {
        let median = [
            CGPoint(x: 10, y: 50),
            CGPoint(x: 50, y: 50),
            CGPoint(x: 90, y: 50)
        ]

        var progress = 0
        var completed = false

        let res1 = StrokeMatcher.evaluateTouch(touchPoint: CGPoint(x: 12, y: 52), median: median, currentProgress: progress)
        progress = res1.newProgress
        completed = res1.isCompleted
        XCTAssertEqual(progress, 1)
        XCTAssertFalse(completed)

        let res2 = StrokeMatcher.evaluateTouch(touchPoint: CGPoint(x: 50, y: 50), median: median, currentProgress: progress)
        progress = res2.newProgress
        completed = res2.isCompleted
        XCTAssertEqual(progress, 2)
        XCTAssertFalse(completed)

        let res3 = StrokeMatcher.evaluateTouch(touchPoint: CGPoint(x: 88, y: 51), median: median, currentProgress: progress)
        progress = res3.newProgress
        completed = res3.isCompleted
        XCTAssertEqual(progress, 3)
        XCTAssertTrue(completed)
    }

    func testDistantTouchIgnored() {
        let median = [
            CGPoint(x: 10, y: 50),
            CGPoint(x: 50, y: 50),
            CGPoint(x: 90, y: 50)
        ]

        let res = StrokeMatcher.evaluateTouch(touchPoint: CGPoint(x: 200, y: 200), median: median, currentProgress: 0)
        XCTAssertEqual(res.newProgress, 0)
        XCTAssertFalse(res.isCompleted)
    }
}
