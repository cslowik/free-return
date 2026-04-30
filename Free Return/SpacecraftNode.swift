//
//  SpacecraftNode.swift
//  Free Return
//
//  Created by Chris Slowik on 4/29/26.
//

import SpriteKit

class SpacecraftNode: SKNode {

    private let sprite: SKShapeNode
    private(set) var simState: SimState
    private(set) var isLaunched = false

    init(at position: CGPoint) {
        simState = SimState(position: position, velocity: .zero)

        // Small triangle pointing up; rotates to face velocity direction
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 10))
        path.addLine(to: CGPoint(x: -6, y: -6))
        path.addLine(to: CGPoint(x: 6, y: -6))
        path.closeSubpath()

        sprite = SKShapeNode(path: path)
        sprite.fillColor = .white
        sprite.strokeColor = SKColor(white: 1, alpha: 0.5)
        sprite.lineWidth = 1

        super.init()
        self.position = position
        addChild(sprite)
    }

    func launch(velocity: CGVector) {
        simState.velocity = velocity
        isLaunched = true
    }

    func reset(at position: CGPoint) {
        simState = SimState(position: position, velocity: .zero)
        self.position = position
        zRotation = 0
        isLaunched = false
        isHidden = false
    }

    func advance(bodies: [GravityBody], dt: CGFloat) {
        guard isLaunched else { return }
        simState = PhysicsSimulator.step(simState, bodies: bodies, dt: dt)
        position = simState.position
        let vel = simState.velocity
        if vel.dx != 0 || vel.dy != 0 {
            // Triangle drawn pointing +y; offset by -π/2 to align with velocity angle
            zRotation = atan2(vel.dy, vel.dx) - .pi / 2
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }
}
