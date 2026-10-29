import SwiftUI
import CoreText
import CoreGraphics

struct NotoGlyphProvider {
    private static let ctFont: CTFont? = {
        let url = Bundle.main.url(forResource: "NotoSansSC", withExtension: "ttf") ??
                  Bundle(for: CharacterStore.self).url(forResource: "NotoSansSC", withExtension: "ttf") ??
                  URL(fileURLWithPath: "Calli/Resources/NotoSansSC.ttf")
        guard let provider = CGDataProvider(url: url as CFURL),
              let cgFont = CGFont(provider) else { return nil }
        return CTFontCreateWithGraphicsFont(cgFont, 1024, nil, nil)
    }()

    static func path(for character: String, canvasSize: CGSize) -> Path? {
        guard let font = ctFont, let firstScalar = character.utf16.first else { return nil }
        var unichars = [firstScalar]
        var glyphs = [CGGlyph](repeating: 0, count: 1)
        CTFontGetGlyphsForCharacters(font, &unichars, &glyphs, 1)
        guard glyphs[0] != 0, let glyphPath = CTFontCreatePathForGlyph(font, glyphs[0], nil) else { return nil }

        let side = min(canvasSize.width, canvasSize.height)
        let scale = side / 1024.0
        let offsetX = (canvasSize.width - side) / 2.0
        let offsetY = (canvasSize.height - side) / 2.0

        var transform = CGAffineTransform(scaleX: scale, y: -scale)
            .concatenating(CGAffineTransform(translationX: offsetX, y: offsetY + 900.0 * scale))

        guard let transformed = glyphPath.copy(using: &transform) else { return nil }
        return Path(transformed)
    }
}
