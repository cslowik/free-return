//
//  Level.swift
//  Free Return
//

import CoreGraphics

struct Vec2: Codable, Equatable {
    let x: CGFloat
    let y: CGFloat
}

struct PlanetData: Codable, Equatable {
    let position: Vec2
    let mass: CGFloat
    let radius: CGFloat
}

struct TargetZoneData: Codable, Equatable {
    let position: Vec2
    let radius: CGFloat
}

struct Level: Codable, Equatable {
    let id: String
    let name: String
    let shipStart: Vec2
    let planets: [PlanetData]
    let target: TargetZoneData
}
