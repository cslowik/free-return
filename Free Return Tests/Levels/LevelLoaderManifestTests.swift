//
//  LevelLoaderManifestTests.swift
//  Free Return Tests
//

import XCTest
@testable import Free_Return

final class LevelLoaderManifestTests: XCTestCase {

    private var bundle: Bundle { Bundle(for: type(of: self)) }

    func test_loadsManifest_returnsLevelsInOrder() throws {
        let manifest = try LevelLoader.loadManifest(bundle: bundle)
        XCTAssertEqual(manifest.levels, ["level-001", "level-002"])
    }

    func test_loadsManifest_throwsManifestNotFound_whenAbsent() {
        // Brand-new empty bundle has no manifest.json.
        let emptyBundle = Bundle(for: NSObject.self)
        XCTAssertThrowsError(try LevelLoader.loadManifest(bundle: emptyBundle)) { error in
            XCTAssertEqual(error as? LevelLoaderError, .manifestNotFound)
        }
    }

    func test_decodeManifest_throwsDecodeFailed_whenMalformed() {
        let bad = "{ this is not valid json".data(using: .utf8)!
        XCTAssertThrowsError(try LevelLoader.decodeManifest(from: bad)) { error in
            guard case .decodeFailed(let id, _) = error as? LevelLoaderError else {
                return XCTFail("Expected .decodeFailed, got \(error)")
            }
            XCTAssertEqual(id, "manifest")
        }
    }

    func test_decodeManifest_throwsDecodeFailed_whenWrongShape() {
        let bad = #"{"unrelated": "field"}"#.data(using: .utf8)!
        XCTAssertThrowsError(try LevelLoader.decodeManifest(from: bad)) { error in
            guard case .decodeFailed(let id, _) = error as? LevelLoaderError else {
                return XCTFail("Expected .decodeFailed, got \(error)")
            }
            XCTAssertEqual(id, "manifest")
        }
    }
}
