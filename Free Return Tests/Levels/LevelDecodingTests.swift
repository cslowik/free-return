//
//  LevelDecodingTests.swift
//  Free Return Tests
//

import XCTest
@testable import Free_Return

final class LevelDecodingTests: XCTestCase {

    func test_decodesCompleteLevel() throws {
        let json = #"""
        {
          "id": "level-001",
          "name": "First Steps",
          "shipStart": { "x": 540, "y": 346 },
          "planets": [
            { "position": { "x": 540, "y": 960 }, "mass": 8000, "radius": 40 }
          ],
          "target": { "position": { "x": 540, "y": 1690 }, "radius": 30 }
        }
        """#.data(using: .utf8)!

        let level = try JSONDecoder().decode(Level.self, from: json)

        XCTAssertEqual(level.id, "level-001")
        XCTAssertEqual(level.name, "First Steps")
        XCTAssertEqual(level.shipStart, Vec2(x: 540, y: 346))
        XCTAssertEqual(level.planets.count, 1)
        XCTAssertEqual(level.planets[0].position, Vec2(x: 540, y: 960))
        XCTAssertEqual(level.planets[0].mass, 8000)
        XCTAssertEqual(level.planets[0].radius, 40)
        XCTAssertEqual(level.target.position, Vec2(x: 540, y: 1690))
        XCTAssertEqual(level.target.radius, 30)
    }

    func test_decodesMultiplePlanetsInOrder() throws {
        let json = #"""
        {
          "id": "level-002",
          "name": "Triple",
          "shipStart": { "x": 0, "y": 0 },
          "planets": [
            { "position": { "x": 1, "y": 1 }, "mass": 100, "radius": 10 },
            { "position": { "x": 2, "y": 2 }, "mass": 200, "radius": 20 },
            { "position": { "x": 3, "y": 3 }, "mass": 300, "radius": 30 }
          ],
          "target": { "position": { "x": 9, "y": 9 }, "radius": 5 }
        }
        """#.data(using: .utf8)!

        let level = try JSONDecoder().decode(Level.self, from: json)

        XCTAssertEqual(level.planets.map(\.mass), [100, 200, 300])
    }

    func test_failsWhenRequiredFieldMissing() {
        let json = #"""
        {
          "id": "level-003",
          "name": "Broken",
          "shipStart": { "x": 0, "y": 0 },
          "planets": []
        }
        """#.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(Level.self, from: json))
    }
}
