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

    private let trailNodeName = "spacecraftTrail"
    private let trailDotRadius: CGFloat = 5
    private let trailFadeDuration: TimeInterval = 0.5

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
        clearTrail()
    }

    func advance(bodies: [GravityBody], dt: CGFloat) {
        guard isLaunched else { return }
        simState = PhysicsSimulator.step(simState, bodies: bodies, dt: dt)
        position = simState.position
        emitTrailDot()
        let vel = simState.velocity
        if vel.dx != 0 || vel.dy != 0 {
            // Triangle drawn pointing +y; offset by -π/2 to align with velocity angle
            zRotation = atan2(vel.dy, vel.dx) - .pi / 2
        }
    }

    private func emitTrailDot() {
        guard let parent = parent else { return }
        let dot = SKShapeNode(circleOfRadius: trailDotRadius)
        dot.position = position
        dot.fillColor = SKColor(white: 1, alpha: 0.275)
        dot.strokeColor = .clear
        dot.zPosition = zPosition - 1
        dot.name = trailNodeName
        parent.addChild(dot)

        dot.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: trailFadeDuration),
                SKAction.scale(to: 0.2, duration: trailFadeDuration)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func clearTrail() {
        parent?.enumerateChildNodes(withName: trailNodeName) { node, _ in
            node.removeFromParent()
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }
}
