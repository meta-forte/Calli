import SwiftUI
import CoreGraphics

struct StrokePathParser {
    static func parse(svgPath: String, canvasSize: CGSize) -> Path {
        let cgPath = CGMutablePath()
        let side = min(canvasSize.width, canvasSize.height)
        guard side.isFinite, side > 0 else {
            return Path(cgPath)
        }
        let scale = side / 1024.0
        let offsetX = (canvasSize.width - side) / 2.0
        let offsetY = (canvasSize.height - side) / 2.0

        let transformPoint: (Double, Double) -> CGPoint? = { x, y in
            guard x.isFinite, y.isFinite else { return nil }
            let screenX = offsetX + x * scale
            let screenY = offsetY + (900.0 - y) * scale
            guard screenX.isFinite, screenY.isFinite else { return nil }
            return CGPoint(x: screenX, y: screenY)
        }

        let scanner = Scanner(string: svgPath)
        scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ","))

        var currentCommand: Character = " "
        var hasSubpath = false

        while !scanner.isAtEnd {
            if let commandStr = scanner.scanCharacters(from: CharacterSet.letters) {
                if let firstChar = commandStr.first {
                    currentCommand = firstChar
                }
            }

            switch currentCommand {
            case "M":
                if let x = scanner.scanDouble(), let y = scanner.scanDouble(),
                   let pt = transformPoint(x, y) {
                    cgPath.move(to: pt)
                    hasSubpath = true
                }
            case "L":
                while let x = scanner.scanDouble(), let y = scanner.scanDouble() {
                    if let pt = transformPoint(x, y) {
                        if hasSubpath {
                            cgPath.addLine(to: pt)
                        } else {
                            cgPath.move(to: pt)
                            hasSubpath = true
                        }
                    }
                }
            case "Q":
                while let cx = scanner.scanDouble(), let cy = scanner.scanDouble(),
                      let x = scanner.scanDouble(), let y = scanner.scanDouble() {
                    if let control = transformPoint(cx, cy), let end = transformPoint(x, y), hasSubpath {
                        cgPath.addQuadCurve(to: end, control: control)
                    }
                }
            case "C":
                while let c1x = scanner.scanDouble(), let c1y = scanner.scanDouble(),
                      let c2x = scanner.scanDouble(), let c2y = scanner.scanDouble(),
                      let x = scanner.scanDouble(), let y = scanner.scanDouble() {
                    if let cp1 = transformPoint(c1x, c1y),
                       let cp2 = transformPoint(c2x, c2y),
                       let end = transformPoint(x, y),
                       hasSubpath {
                        cgPath.addCurve(to: end, control1: cp1, control2: cp2)
                    }
                }
            case "Z", "z":
                if hasSubpath {
                    cgPath.closeSubpath()
                }
                currentCommand = " "
            default:
                if scanner.scanDouble() == nil {
                    _ = scanner.scanCharacter()
                }
            }
        }

        return Path(cgPath)
    }
}
