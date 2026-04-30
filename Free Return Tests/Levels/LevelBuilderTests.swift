//
//  LevelBuilderTests.swift
//  Free Return Tests
//

import XCTest
import SpriteKit
@testable import Free_Return

final class LevelBuilderTests: XCTestCase {

    private func makeLevel() -> Level {
        Level(
            id: "test",
            name: "Test",
            shipStart: Vec2(x: 100, y: 200),
            planets: [
                PlanetData(position: Vec2(x: 300, y: 400), mass: 1000, radius: 25),
                PlanetData(position: Vec2(x: 500, y: 600), mass: 2000, radius: 35)
            ],
            target: TargetZoneData(position: Vec2(x: 700, y: 800), radius: 40)
        )
    }

    func test_build_addsExpectedNodesToScene() {
        let scene = SKScene(size: CGSize(width: 1080, height: 1920))
        let level = makeLevel()

        let built = LevelBuilder.build(level, into: scene)

        XCTAssertTrue(scene.children.contains(built.spacecraft))
        XCTAssertTrue(scene.children.contains(built.targetZone))
        XCTAssertTrue(scene.children.contains(built.trajectoryPreview))
        XCTAssertEqual(built.planetNodes.count, 2)
        for node in built.planetNodes {
            XCTAssertTrue(scene.children.contains(node))
        }
    }

    func test_build_positionsSpacecraftAtShipStart() {
        let scene = SKScene(size: CGSize(width: 1080, height: 1920))
        let level = makeLevel()

        let built = LevelBuilder.build(level, into: scene)

        XCTAssertEqual(built.spacecraft.position, CGPoint(x: 100, y: 200))
        XCTAssertEqual(built.shipStart, CGPoint(x: 100, y: 200))
    }

    func test_build_returnsGravityBodiesMatchingPlanetData() {
        let scene = SKScene(size: CGSize(width: 1080, height: 1920))
        let level = makeLevel()

        let built = LevelBuilder.build(level, into: scene)

        XCTAssertEqual(built.gravityBodies.count, 2)
        XCTAssertEqual(built.gravityBodies[0].position, CGPoint(x: 300, y: 400))
        XCTAssertEqual(built.gravityBodies[0].mass, 1000)
        XCTAssertEqual(built.gravityBodies[0].radius, 25)
        XCTAssertEqual(built.gravityBodies[1].position, CGPoint(x: 500, y: 600))
        XCTAssertEqual(built.gravityBodies[1].mass, 2000)
        XCTAssertEqual(built.gravityBodies[1].radius, 35)
    }

    func test_build_positionsTargetZoneCorrectly() {
        let scene = SKScene(size: CGSize(width: 1080, height: 1920))
        let level = makeLevel()

        let built = LevelBuilder.build(level, into: scene)

        XCTAssertEqual(built.targetZone.position, CGPoint(x: 700, y: 800))
        XCTAssertEqual(built.targetZone.radius, 40)
    }
}
