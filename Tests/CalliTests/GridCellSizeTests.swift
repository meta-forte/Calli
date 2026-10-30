import XCTest
import UIKit
@testable import Calli

final class GridCellSizeTests: XCTestCase {
    func testDefaultsAndStorageKey() {
        XCTAssertEqual(GridCellSize.defaultSize, .medium)
        XCTAssertEqual(GridCellSize.storageKey, "kGridCellSize")
        XCTAssertEqual(GridCellSize.allCases.map(\.title), ["Small", "Medium", "Large"])
    }

    func testSizesGrowMonotonically() {
        let sizes = GridCellSize.allCases
        for (smaller, larger) in zip(sizes, sizes.dropFirst()) {
            XCTAssertLessThan(smaller.hanziFontSize, larger.hanziFontSize)
            XCTAssertLessThan(smaller.pinyinFontSize, larger.pinyinFontSize)
            XCTAssertLessThan(smaller.minimumCellWidth, larger.minimumCellWidth)
            XCTAssertLessThan(smaller.cellHeight, larger.cellHeight)
        }
    }

    func testLongHSKPinyinFitsWithoutScaling() {
        let horizontalPadding: CGFloat = 12
        for size in GridCellSize.allCases {
            let font = UIFont.systemFont(ofSize: size.pinyinFontSize, weight: .regular)
            for pinyin in ["chuáng", "zhuāng", "dōu, dū"] {
                let width = (pinyin as NSString).size(withAttributes: [.font: font]).width
                XCTAssertLessThanOrEqual(width, size.minimumCellWidth - horizontalPadding, "\(pinyin) at \(size.title)")
            }
        }
    }

    func testContentFitsVertically() {
        for size in GridCellSize.allCases {
            let hanzi = UIFont.systemFont(ofSize: size.hanziFontSize, weight: .semibold).lineHeight
            let pinyin = UIFont.systemFont(ofSize: size.pinyinFontSize).lineHeight
            let meaning = UIFont.systemFont(ofSize: size.meaningFontSize, weight: .medium).lineHeight
            XCTAssertLessThanOrEqual(hanzi + pinyin + 2 + 12, size.cellHeight, size.title)
            XCTAssertLessThanOrEqual(hanzi + pinyin + meaning + 4 + 12, size.searchCellHeight, size.title)
        }
    }
}
