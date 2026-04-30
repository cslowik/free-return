//
//  Vec2Tests.swift
//  Free Return Tests
//

import XCTest
@testable import Free_Return

final class Vec2Tests: XCTestCase {

    func test_decodesObjectFormFromJSON() throws {
        let json = #"{"x": 12.5, "y": -3.25}"#.data(using: .utf8)!
        let v = try JSONDecoder().decode(Vec2.self, from: json)
        XCTAssertEqual(v.x, 12.5)
        XCTAssertEqual(v.y, -3.25)
    }

    func test_roundTrips() throws {
        let original = Vec2(x: 7, y: 11)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Vec2.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
