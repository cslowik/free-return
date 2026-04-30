//
//  TargetZoneNode.swift
//  Free Return
//
//  Created by Chris Slowik on 4/29/26.
//

import SpriteKit

class TargetZoneNode: SKNode {

    let radius: CGFloat

    init(at position: CGPoint, radius: CGFloat) {
        self.radius = radius
        super.init()
        self.position = position

        let ring = SKShapeNode(circleOfRadius: radius)
        ring.fillColor = SKColor.systemGreen.withAlphaComponent(0.12)
        ring.strokeColor = .systemGreen
        ring.lineWidth = 2
        addChild(ring)

        ring.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.9),
            SKAction.scale(to: 1.0, duration: 0.9)
        ])))

        let dot = SKShapeNode(circleOfRadius: 3)
        dot.fillColor = .systemGreen
        dot.strokeColor = .clear
        addChild(dot)
    }

    override func contains(_ point: CGPoint) -> Bool {
        let dx = point.x - position.x
        let dy = point.y - position.y
        return (dx * dx + dy * dy) <= radius * radius
    }

    required init?(coder: NSCoder) { fatalError() }
}
