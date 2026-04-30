//
//  ProductionBundleSmokeTests.swift
//  Free Return Tests
//
//  Critical regression test: every shipped level must decode cleanly.
//

import XCTest
@testable import Free_Return

final class ProductionBundleSmokeTests: XCTestCase {

    func test_allBundledLevelsLoadSuccessfully() throws {
        // In a host-application unit test, Bundle.main is the host app's bundle.
        let levels = try LevelLoader.loadAll(bundle: .main)
        XCTAssertFalse(levels.isEmpty, "Expected at least one bundled level")
        for level in levels {
            XCTAssertFalse(level.id.isEmpty)
            XCTAssertFalse(level.name.isEmpty)
        }
    }
}
