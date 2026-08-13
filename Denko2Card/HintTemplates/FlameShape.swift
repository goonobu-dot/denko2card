import SwiftUI

/// cards5.swift の drawFlame(...) をSwiftUI Shapeへ移植したもの。
struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.maxY
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: cx, y: cy))
        p.addCurve(
            to: CGPoint(x: cx, y: cy - h),
            control1: CGPoint(x: cx - h * 0.6, y: cy - h * 0.27),
            control2: CGPoint(x: cx - h * 0.27, y: cy - h * 0.73)
        )
        p.addCurve(
            to: CGPoint(x: cx, y: cy),
            control1: CGPoint(x: cx + h * 0.27, y: cy - h * 0.73),
            control2: CGPoint(x: cx + h * 0.6, y: cy - h * 0.27)
        )
        return p
    }
}

struct FlameView: View {
    var scale: CGFloat = 1
    var color: Color = CardTheme.accent
    var body: some View {
        ZStack {
            FlameShape()
                .fill(color)
                .frame(width: 90 * scale, height: 150 * scale)
            FlameShape()
                .fill(Color(red: 0.98, green: 0.75, blue: 0.35))
                .frame(width: 40 * scale, height: 95 * scale)
                .offset(y: 20 * scale)
        }
    }
}
