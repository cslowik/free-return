# Free Return

A 2D physics puzzle / arcade game for iOS. Orbital mechanics meets pinball — drag back on the spacecraft, release to launch, and let gravity do the steering.

## Concept

Single-shot launch: aim by dragging backward on the ship (slingshot-style), release to fire. Once airborne, the craft is steered entirely by gravity wells. Land in the target zone to win; crash into a planet or drift off-screen and you're lost in space.

## How it works

- **Custom gravity integrator** — Velocity Verlet, runs every frame against all `GravityBody` instances. SpriteKit physics is reserved for collision detection only; motion is hand-rolled.
- **Trajectory preview** — while dragging, the launch vector is pre-simulated 420 steps (1/60s each) and drawn as fading dots so you can see your arc before committing.
- **Drag mechanics** — max drag 80pt, launch velocity scaled ×3 in the opposite direction.

## Architecture

Flat file layout under `Free Return/`:

| File | Role |
|---|---|
| `PhysicsSimulator.swift` | `GravityBody`, `SimState`, gravity integration (G=1000) |
| `SpacecraftNode.swift` | `SKNode` driven manually from `SimState`; rotates to face velocity |
| `TrajectoryPreview.swift` | Pre-simulated path drawn as fading dots |
| `TargetZoneNode.swift` | Win-condition zone |
| `GameScene.swift` | Test level (one planet, mass 8000, radius 40) and game-state machine |
| `Extensions.swift` | `CGPoint.distance`, `CGVector.clamped` |

## Build

Open `Free Return.xcodeproj` in Xcode. Portrait-only, iPhone target.

## Roadmap

- Multiple gravity bodies and moving bodies
- Kinetic bumpers, asteroid-belt hazards, wormholes
- Codable level data (JSON-loaded)
- HUD, scoring, level progression
