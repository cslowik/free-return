//
//  LevelLoaderLoadTests.swift
//  Free Return Tests
//

import XCTest
@testable import Free_Return

final class LevelLoaderLoadTests: XCTestCase {

    private var bundle: Bundle { Bundle(for: type(of: self)) }

    func test_load_returnsExpectedLevel_forValidJSON() throws {
        let level = try LevelLoader.load(id: "level-001", bundle: bundle)
        XCTAssertEqual(level.id, "level-001")
        XCTAssertEqual(level.name, "First Steps")
        XCTAssertEqual(level.shipStart, Vec2(x: 540, y: 346))
        XCTAssertEqual(level.planets.count, 1)
        XCTAssertEqual(level.target.radius, 30)
    }

    func test_load_decodesMultiplePlanetsInOrder() throws {
        let level = try LevelLoader.load(id: "level-002", bundle: bundle)
        XCTAssertEqual(level.planets.map(\.mass), [5000, 5000, 7000])
    }

    func test_load_throwsLevelNotFound_whenFileMissing() {
        XCTAssertThrowsError(
            try LevelLoader.load(id: "level-999", bundle: bundle)
        ) { error in
            XCTAssertEqual(error as? LevelLoaderError, .levelNotFound(id: "level-999"))
        }
    }

    func test_load_throwsIdMismatch_whenJSONIDDiffersFromFilename() {
        XCTAssertThrowsError(
            try LevelLoader.load(id: "mismatched-id", bundle: bundle)
        ) { error in
            XCTAssertEqual(
                error as? LevelLoaderError,
                .idMismatch(expected: "mismatched-id", actual: "actually-something-else")
            )
        }
    }

    func test_decodeLevel_throwsDecodeFailed_whenMalformed() {
        let bad = "{ this is { not [ valid".data(using: .utf8)!
        XCTAssertThrowsError(
            try LevelLoader.decodeLevel(from: bad, expectingId: "test-id")
        ) { error in
            guard case .decodeFailed(let id, _) = error as? LevelLoaderError else {
                return XCTFail("Expected .decodeFailed, got \(error)")
            }
            XCTAssertEqual(id, "test-id")
        }
    }

    func test_decodeLevel_throwsDecodeFailed_whenRequiredFieldMissing() {
        let bad = #"""
        {
          "id": "test-id",
          "name": "No Target",
          "shipStart": { "x": 0, "y": 0 },
          "planets": []
        }
        """#.data(using: .utf8)!
        XCTAssertThrowsError(
            try LevelLoader.decodeLevel(from: bad, expectingId: "test-id")
        ) { error in
            guard case .decodeFailed(let id, _) = error as? LevelLoaderError else {
                return XCTFail("Expected .decodeFailed, got \(error)")
            }
            XCTAssertEqual(id, "test-id")
        }
    }
}
