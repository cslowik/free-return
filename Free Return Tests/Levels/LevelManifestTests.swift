//
//  LevelManifestTests.swift
//  Free Return Tests
//

import XCTest
@testable import Free_Return

final class LevelManifestTests: XCTestCase {

    func test_decodesOrderedLevelIDs() throws {
        let json = #"""
        { "levels": ["level-001", "level-002", "level-003"] }
        """#.data(using: .utf8)!

        let manifest = try JSONDecoder().decode(LevelManifest.self, from: json)

        XCTAssertEqual(manifest.levels, ["level-001", "level-002", "level-003"])
    }

    func test_decodesEmptyList() throws {
        let json = #"{ "levels": [] }"#.data(using: .utf8)!
        let manifest = try JSONDecoder().decode(LevelManifest.self, from: json)
        XCTAssertEqual(manifest.levels, [])
    }
}
