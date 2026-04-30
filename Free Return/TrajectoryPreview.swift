//
//  TrajectoryPreview.swift
//  Free Return
//
//  Created by Chris Slowik on 4/29/26.
//

import SpriteKit

class TrajectoryPreview: SKNode {

    private var dots: [SKShapeNode] = []

    private let simulationSteps = 420
    private let simulationDt: CGFloat = 1.0 / 60.0
    private let dotInterval = 7       // sample every Nth simulation step
    private let dotRadius: CGFloat = 2

    func update(from state: SimState, bodies: [GravityBody]) {
        let allPoints = PhysicsSimulator.simulate(
            from: state, bodies: bodies,
            steps: simulationSteps, dt: simulationDt
        )

        // Downsample to one dot per dotInterval steps
        let samples = stride(from: 0, to: allPoints.count, by: dotInterval).map { allPoints[$0] }

        // Grow dot pool on demand
        while dots.count < samples.count {
            let dot = SKShapeNode(circleOfRadius: dotRadius)
            dot.strokeColor = .clear
            addChild(dot)
            dots.append(dot)
        }

        let total = samples.count
        for (i, dot) in dots.enumerated() {
            if i < total {
                dot.position = samples[i]
                // Fade from bright near launch to transparent at the end
                let t = CGFloat(i) / CGFloat(total)
                let alpha = (1.0 - t) * 0.75
                dot.fillColor = SKColor(white: 1, alpha: alpha)
                dot.isHidden = false
            } else {
                dot.isHidden = true
            }
        }
    }

    func hide() {
        dots.forEach { $0.isHidden = true }
    }
}
