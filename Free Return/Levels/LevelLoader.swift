//
//  LevelLoader.swift
//  Free Return
//

import Foundation

enum LevelLoaderError: Error, Equatable {
    case manifestNotFound
    case levelNotFound(id: String)
    case decodeFailed(id: String, underlying: String)
    case idMismatch(expected: String, actual: String)
}

enum LevelLoader {

    static func loadManifest(bundle: Bundle = .main) throws -> LevelManifest {
        guard let url = bundle.url(forResource: "manifest", withExtension: "json") else {
            throw LevelLoaderError.manifestNotFound
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw LevelLoaderError.manifestNotFound
        }
        return try decodeManifest(from: data)
    }

    static func decodeManifest(from data: Data) throws -> LevelManifest {
        do {
            return try JSONDecoder().decode(LevelManifest.self, from: data)
        } catch {
            throw LevelLoaderError.decodeFailed(
                id: "manifest",
                underlying: String(describing: error)
            )
        }
    }
}
