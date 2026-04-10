//
//  Starburst.swift
//  TRunD
//
//  Created by Bitch Bag 1 on 11/26/25.
//


import SwiftUI

struct Starburst: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let spikes = 12
        let innerRadius = rect.width * 0.3 / 2
        let outerRadius = rect.width / 2

        for i in 0..<spikes {
            let angle = (Double(i) * (360.0 / Double(spikes))) * .pi / 180
            let pt1 = CGPoint(
                x: center.x + CGFloat(cos(angle)) * outerRadius,
                y: center.y + CGFloat(sin(angle)) * outerRadius
            )
            let pt2 = CGPoint(
                x: center.x + CGFloat(cos(angle + .pi / Double(spikes))) * innerRadius,
                y: center.y + CGFloat(sin(angle + .pi / Double(spikes))) * innerRadius
            )

            if i == 0 {
                path.move(to: pt1)
            }

            path.addLine(to: pt1)
            path.addLine(to: pt2)
        }

        path.closeSubpath()
        return path
    }
}

