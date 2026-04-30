//
//  PhysicsSimulator.swift
//  Free Return
//
//  Created by Chris Slowik on 4/29/26.
//

import CoreGraphics

struct GravityBody {
    let position: CGPoint
    let mass: CGFloat
    let radius: CGFloat
}

struct SimState {
    var position: CGPoint
    var velocity: CGVector
}

enum PhysicsSimulator {

    // Tunable gravitational constant — adjust to taste during level design
    static let G: CGFloat = 1000

    static func acceleration(at position: CGPoint, from bodies: [GravityBody]) -> CGVector {
        var ax: CGFloat = 0
        var ay: CGFloat = 0
        for body in bodies {
            let dx = body.position.x - position.x
            let dy = body.position.y - position.y
            // Clamp r² to body surface to avoid singularity inside the body
            let r2 = max(dx * dx + dy * dy, body.radius * body.radius)
            let r = r2.squareRoot()
            let mag = G * body.mass / r2
            ax += mag * dx / r
            ay += mag * dy / r
        }
        return CGVector(dx: ax, dy: ay)
    }

    // Velocity Verlet integration — better energy conservation than Euler
    static func step(_ state: SimState, bodies: [GravityBody], dt: CGFloat) -> SimState {
        let a0 = acceleration(at: state.position, from: bodies)
        let nextPos = CGPoint(
            x: state.position.x + state.velocity.dx * dt + 0.5 * a0.dx * dt * dt,
            y: state.position.y + state.velocity.dy * dt + 0.5 * a0.dy * dt * dt
        )
        let a1 = acceleration(at: nextPos, from: bodies)
        let nextVel = CGVector(
            dx: state.velocity.dx + 0.5 * (a0.dx + a1.dx) * dt,
            dy: state.velocity.dy + 0.5 * (a0.dy + a1.dy) * dt
        )
        return SimState(position: nextPos, velocity: nextVel)
    }

    static func simulate(from state: SimState, bodies: [GravityBody], steps: Int, dt: CGFloat) -> [CGPoint] {
        var points = [CGPoint]()
        points.reserveCapacity(steps)
        var current = state
        for _ in 0..<steps {
            current = step(current, bodies: bodies, dt: dt)
            points.append(current.position)
        }
        return points
    }
}
