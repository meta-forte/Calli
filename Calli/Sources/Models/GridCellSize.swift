import SwiftUI

enum GridCellSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large

    static let storageKey = "kGridCellSize"
    static let defaultSize: GridCellSize = .medium

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    var hanziFontSize: CGFloat {
        switch self {
        case .small: return 20
        case .medium: return 26
        case .large: return 34
        }
    }

    var pinyinFontSize: CGFloat {
        switch self {
        case .small: return 11
        case .medium: return 13
        case .large: return 15
        }
    }

    var meaningFontSize: CGFloat {
        switch self {
        case .small: return 9.5
        case .medium: return 11
        case .large: return 12.5
        }
    }

    var minimumCellWidth: CGFloat {
        switch self {
        case .small: return 60
        case .medium: return 76
        case .large: return 100
        }
    }

    var cellHeight: CGFloat {
        switch self {
        case .small: return 62
        case .medium: return 78
        case .large: return 100
        }
    }

    var searchCellHeight: CGFloat {
        switch self {
        case .small: return 76
        case .medium: return 92
        case .large: return 116
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 12
        case .large: return 14
        }
    }

    static let gridSpacing: CGFloat = 10

    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: minimumCellWidth), spacing: Self.gridSpacing)]
    }
}
