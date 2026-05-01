//
//  LevelBuilder.swift
//  Free Return
//

import SpriteKit

struct BuiltLevel {
    let spacecraft: SpacecraftNode
    let trajectoryPreview: TrajectoryPreview
    let targetZone: TargetZoneNode
    let planetNodes: [SKNode]
    let gravityBodies: [GravityBody]
    let shipStart: CGPoint
}

enum LevelBuilder {

    static func build(_ level: Level, into scene: SKScene) -> BuiltLevel {
        var planetNodes: [SKNode] = []
        var gravityBodies: [GravityBody] = []

        for planet in level.planets {
            let body = GravityBody(
                position: CGPoint(x: planet.position.x, y: planet.position.y),
                mass: planet.mass,
                radius: planet.radius
            )
            gravityBodies.append(body)

            let node = makePlanetNode(for: body, color: .systemBlue)
            scene.addChild(node)
            planetNodes.append(node)
        }

        let shipStart = CGPoint(x: level.shipStart.x, y: level.shipStart.y)
        let spacecraft = SpacecraftNode(at: shipStart)
        scene.addChild(spacecraft)

        let trajectoryPreview = TrajectoryPreview()
        scene.addChild(trajectoryPreview)

        let targetPosition = CGPoint(x: level.target.position.x, y: level.target.position.y)
        let targetZone = TargetZoneNode(at: targetPosition, radius: level.target.radius)
        scene.addChild(targetZone)

        return BuiltLevel(
            spacecraft: spacecraft,
            trajectoryPreview: trajectoryPreview,
            targetZone: targetZone,
            planetNodes: planetNodes,
            gravityBodies: gravityBodies,
            shipStart: shipStart
        )
    }

    private static func makePlanetNode(for body: GravityBody, color: SKColor) -> SKNode {
        let node = SKShapeNode(circleOfRadius: body.radius)
        node.position = body.position
        node.fillColor = color
        node.strokeColor = color.withAlphaComponent(0.4)
        node.lineWidth = body.radius * 0.25

        let halo = SKShapeNode(circleOfRadius: body.radius * 1.7)
        halo.fillColor = color.withAlphaComponent(0.08)
        halo.strokeColor = .clear
        node.addChild(halo)

        return node
    }
}
