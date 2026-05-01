//
//  GameOutcome.swift
//  Free Return
//

import Foundation

enum GameOutcome {
    case targetReached
    case freeReturnAccomplished
    case orbitAchieved
    case crashed
    case lostInSpace

    var title: String {
        switch self {
        case .targetReached:           return "Target Reached"
        case .freeReturnAccomplished:  return "Free Return Accomplished"
        case .orbitAchieved:           return "Orbit Achieved"
        case .crashed:                 return "Crashed"
        case .lostInSpace:             return "Lost in Space"
        }
    }

    var isSuccess: Bool {
        switch self {
        case .targetReached, .freeReturnAccomplished, .orbitAchieved:
            return true
        case .crashed, .lostInSpace:
            return false
        }
    }
}
