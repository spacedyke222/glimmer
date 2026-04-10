import SwiftUI

struct JaggedStarburst: Shape {
    var points: Int = 30
    var innerRadiusFraction: CGFloat = 0.5 // relative to outer radius

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * innerRadiusFraction

        for i in 0..<points {
            let angle = Double(i) / Double(points) * Double.pi * 2
            let radius = i % 2 == 0 ? outerRadius : innerRadius

            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

