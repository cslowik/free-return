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

    static func load(id: String, bundle: Bundle = .main) throws -> Level {
        guard let url = bundle.url(forResource: id, withExtension: "json") else {
            throw LevelLoaderError.levelNotFound(id: id)
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw LevelLoaderError.levelNotFound(id: id)
        }
        return try decodeLevel(from: data, expectingId: id)
    }

    static func decodeLevel(from data: Data, expectingId expectedId: String) throws -> Level {
        let level: Level
        do {
            level = try JSONDecoder().decode(Level.self, from: data)
        } catch {
            throw LevelLoaderError.decodeFailed(
                id: expectedId,
                underlying: String(describing: error)
            )
        }
        guard level.id == expectedId else {
            throw LevelLoaderError.idMismatch(expected: expectedId, actual: level.id)
        }
        return level
    }

    static func loadAll(bundle: Bundle = .main) throws -> [Level] {
        let manifest = try loadManifest(bundle: bundle)
        return try manifest.levels.map { try load(id: $0, bundle: bundle) }
    }
}
