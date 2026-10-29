import XCTest
@testable import Calli

final class PairwiseStrokeTests: XCTestCase {
    func testPairwiseForOddNumberOfStrokes() {
        let dummyStrokes = Array(repeating: "M 0 0 L 10 10", count: 11)
        let dummyMedians = Array(repeating: [[0.0, 0.0], [10.0, 10.0]], count: 11)
        let strokeInfo = CharacterStrokeInfo(strokes: dummyStrokes, medians: dummyMedians)

        XCTAssertEqual(strokeInfo.activePair(for: 0)?.first, 0)
        XCTAssertEqual(strokeInfo.activePair(for: 0)?.second, 1)

        XCTAssertEqual(strokeInfo.activePair(for: 1)?.first, 0)
        XCTAssertEqual(strokeInfo.activePair(for: 1)?.second, 1)

        XCTAssertEqual(strokeInfo.activePair(for: 2)?.first, 2)
        XCTAssertEqual(strokeInfo.activePair(for: 2)?.second, 3)

        XCTAssertEqual(strokeInfo.activePair(for: 3)?.first, 2)
        XCTAssertEqual(strokeInfo.activePair(for: 3)?.second, 3)

        XCTAssertEqual(strokeInfo.activePair(for: 8)?.first, 8)
        XCTAssertEqual(strokeInfo.activePair(for: 8)?.second, 9)

        XCTAssertEqual(strokeInfo.activePair(for: 9)?.first, 8)
        XCTAssertEqual(strokeInfo.activePair(for: 9)?.second, 9)

        XCTAssertEqual(strokeInfo.activePair(for: 10)?.first, 10)
        XCTAssertNil(strokeInfo.activePair(for: 10)?.second)

        XCTAssertNil(strokeInfo.activePair(for: 11))
    }

    func testPairwiseForEvenNumberOfStrokes() {
        let dummyStrokes = ["M 0 0 L 10 10", "M 10 10 L 20 20"]
        let dummyMedians = [[[0.0, 0.0], [10.0, 10.0]], [[10.0, 10.0], [20.0, 20.0]]]
        let strokeInfo = CharacterStrokeInfo(strokes: dummyStrokes, medians: dummyMedians)

        XCTAssertEqual(strokeInfo.activePair(for: 0)?.first, 0)
        XCTAssertEqual(strokeInfo.activePair(for: 0)?.second, 1)

        XCTAssertEqual(strokeInfo.activePair(for: 1)?.first, 0)
        XCTAssertEqual(strokeInfo.activePair(for: 1)?.second, 1)

        XCTAssertNil(strokeInfo.activePair(for: 2))
    }

    func testPairwiseForSingleStrokeCharacter() {
        let dummyStrokes = ["M 0 0 L 10 10"]
        let dummyMedians = [[[0.0, 0.0], [10.0, 10.0]]]
        let strokeInfo = CharacterStrokeInfo(strokes: dummyStrokes, medians: dummyMedians)

        XCTAssertEqual(strokeInfo.activePair(for: 0)?.first, 0)
        XCTAssertNil(strokeInfo.activePair(for: 0)?.second)

        XCTAssertNil(strokeInfo.activePair(for: 1))
    }

    func testPairwiseStrokeColorHueAndValue() {
        var h1: CGFloat = 0
        var s1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        UIColor(red: 0.15, green: 0.45, blue: 0.88, alpha: 1.0).getHue(&h1, saturation: &s1, brightness: &b1, alpha: &a1)

        var h2: CGFloat = 0
        var s2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        UIColor(hue: 0.598, saturation: 0.83, brightness: 0.52, alpha: 1.0).getHue(&h2, saturation: &s2, brightness: &b2, alpha: &a2)

        XCTAssertEqual(h1, h2, accuracy: 0.01)
        XCTAssertNotEqual(b1, b2, accuracy: 0.1)
    }

    func testActiveGroupForSingleMode() {
        let dummyStrokes = Array(repeating: "M 0 0 L 10 10", count: 9)
        let dummyMedians = Array(repeating: [[0.0, 0.0], [10.0, 10.0]], count: 9)
        let strokeInfo = CharacterStrokeInfo(strokes: dummyStrokes, medians: dummyMedians)

        XCTAssertEqual(strokeInfo.activeGroup(for: 0, mode: .single), [0])
        XCTAssertEqual(strokeInfo.activeGroup(for: 1, mode: .single), [1])
        XCTAssertEqual(strokeInfo.activeGroup(for: 8, mode: .single), [8])
        XCTAssertEqual(strokeInfo.activeGroup(for: 9, mode: .single), [])
    }

    func testActiveGroupForPairwiseMode() {
        let dummyStrokes = Array(repeating: "M 0 0 L 10 10", count: 9)
        let dummyMedians = Array(repeating: [[0.0, 0.0], [10.0, 10.0]], count: 9)
        let strokeInfo = CharacterStrokeInfo(strokes: dummyStrokes, medians: dummyMedians)

        XCTAssertEqual(strokeInfo.activeGroup(for: 0, mode: .pairwise), [0, 1])
        XCTAssertEqual(strokeInfo.activeGroup(for: 1, mode: .pairwise), [0, 1])
        XCTAssertEqual(strokeInfo.activeGroup(for: 2, mode: .pairwise), [2, 3])
        XCTAssertEqual(strokeInfo.activeGroup(for: 8, mode: .pairwise), [8])
        XCTAssertEqual(strokeInfo.activeGroup(for: 9, mode: .pairwise), [])
    }

    func testActiveGroupForComponentMode() {
        let dummyStrokes = Array(repeating: "M 0 0 L 10 10", count: 9)
        let dummyMedians = Array(repeating: [[0.0, 0.0], [10.0, 10.0]], count: 9)
        let components = [[0, 1, 2], [3, 4], [5, 6, 7, 8]]
        let strokeInfo = CharacterStrokeInfo(strokes: dummyStrokes, medians: dummyMedians, components: components)

        XCTAssertEqual(strokeInfo.activeGroup(for: 0, mode: .component), [0, 1, 2])
        XCTAssertEqual(strokeInfo.activeGroup(for: 1, mode: .component), [0, 1, 2])
        XCTAssertEqual(strokeInfo.activeGroup(for: 2, mode: .component), [0, 1, 2])

        XCTAssertEqual(strokeInfo.activeGroup(for: 3, mode: .component), [3, 4])
        XCTAssertEqual(strokeInfo.activeGroup(for: 4, mode: .component), [3, 4])

        XCTAssertEqual(strokeInfo.activeGroup(for: 5, mode: .component), [5, 6, 7, 8])
        XCTAssertEqual(strokeInfo.activeGroup(for: 8, mode: .component), [5, 6, 7, 8])
        XCTAssertEqual(strokeInfo.activeGroup(for: 9, mode: .component), [])
    }

    func testActiveGroupForComponentModeFallbackWhenNil() {
        let dummyStrokes = Array(repeating: "M 0 0 L 10 10", count: 5)
        let dummyMedians = Array(repeating: [[0.0, 0.0], [10.0, 10.0]], count: 5)
        let strokeInfo = CharacterStrokeInfo(strokes: dummyStrokes, medians: dummyMedians, components: nil)

        XCTAssertEqual(strokeInfo.activeGroup(for: 0, mode: .component), [0])
        XCTAssertEqual(strokeInfo.activeGroup(for: 4, mode: .component), [4])
    }

    func testComponentSteppedValueCalculation() {
        let totalSteps = 4
        var previousBrightness: Double = 1.0

        for step in 0..<totalSteps {
            let fraction = Double(step) / Double(totalSteps - 1)
            let brightness = 0.90 - fraction * (0.90 - 0.48)
            let color = UIColor(hue: 0.598, saturation: 0.83, brightness: brightness, alpha: 1.0)
            var h: CGFloat = 0
            var s: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

            XCTAssertEqual(Double(h), 0.598, accuracy: 0.01)
            XCTAssertEqual(Double(s), 0.83, accuracy: 0.01)
            XCTAssertLessThan(Double(b), previousBrightness)
            previousBrightness = Double(b)
        }
    }
}
