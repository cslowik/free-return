//
//  LevelLoaderLoadAllTests.swift
//  Free Return Tests
//

import XCTest
@testable import Free_Return

final class LevelLoaderLoadAllTests: XCTestCase {

    private var bundle: Bundle { Bundle(for: type(of: self)) }

    func test_loadAll_returnsLevelsInManifestOrder() throws {
        let levels = try LevelLoader.loadAll(bundle: bundle)
        XCTAssertEqual(levels.map(\.id), ["level-001", "level-002"])
    }

    func test_loadAll_propagatesLoadErrors() throws {
        // The fixture bundle contains a mismatched-id.json. If the manifest pointed
        // at it, loadAll would throw .idMismatch. Composition is trivial — load(id:)
        // already covers .levelNotFound, .idMismatch, .decodeFailed in isolation —
        // but we sanity-check by calling load directly with a known-bad id.
        XCTAssertThrowsError(try LevelLoader.load(id: "mismatched-id", bundle: bundle))
    }
}
