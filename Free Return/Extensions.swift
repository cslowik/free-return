//
//  Extensions.swift
//  Free Return
//
//  Created by Chris Slowik on 4/29/26.
//

import CoreGraphics

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        let dx = other.x - x
        let dy = other.y - y
        return (dx * dx + dy * dy).squareRoot()
    }
}

extension CGVector {
    var magnitude: CGFloat { (dx * dx + dy * dy).squareRoot() }

    func clamped(to maxLength: CGFloat) -> CGVector {
        let mag = magnitude
        guard mag > maxLength else { return self }
        return CGVector(dx: dx / mag * maxLength, dy: dy / mag * maxLength)
    }
}
