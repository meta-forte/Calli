import SwiftUI

struct CalligraphyGridView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.35), lineWidth: 2)

            Path { path in
                path.move(to: CGPoint(x: 0, y: size / 2))
                path.addLine(to: CGPoint(x: size, y: size / 2))
                path.move(to: CGPoint(x: size / 2, y: 0))
                path.addLine(to: CGPoint(x: size / 2, y: size))
            }
            .stroke(Color.red.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: size, y: size))
                path.move(to: CGPoint(x: size, y: 0))
                path.addLine(to: CGPoint(x: 0, y: size))
            }
            .stroke(Color.red.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        .frame(width: size, height: size)
    }
}
