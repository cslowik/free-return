# Level Data Model — Design Spec

**Date:** 2026-04-29
**Status:** Approved for planning
**Scope:** Data model + bundle loader only. No level select UI, no progression tracking, no editor.

## Goal

Replace the hardcoded test level in `GameScene.setupTestLevel()` with a Codable level data model loaded from JSON files in the app bundle. Levels describe today's entities only (gravity bodies, ship start, target zone). This is the foundational layer for all future level-related work (progression, level select, editor, additional gameplay elements).

## Architecture

- A `Level` value type with child structs (`PlanetData`, `TargetZoneData`, `Vec2`), all `Codable`.
- Level JSON files bundled as resources in `Free Return/Levels/levels/`.
- A `LevelManifest` JSON at `Free Return/Levels/manifest.json` listing levels in display order.
- A pure-static `LevelLoader` that reads bundle URLs and decodes typed structs.
- A `LevelBuilder` that takes a decoded `Level` and instantiates scene nodes + gravity bodies — replaces `setupTestLevel()`.
- All level coordinates are in a fixed virtual world: **1080 × 1920** points (portrait). The scene scales to fit any device.

## File Structure

**New files:**

| Path | Responsibility |
|---|---|
| `Free Return/Levels/Level.swift` | Codable structs: `Level`, `PlanetData`, `TargetZoneData`, `Vec2` |
| `Free Return/Levels/LevelManifest.swift` | `LevelManifest` Codable struct |
| `Free Return/Levels/LevelLoader.swift` | `LevelLoaderError` enum + static `loadManifest`, `load(id:)`, `loadAll` |
| `Free Return/Levels/LevelBuilder.swift` | `LevelBuilder.build(level, into: scene)` — populates scene from a `Level` |
| `Free Return/Levels/WorldCanvas.swift` | `WorldCanvas.size = CGSize(width: 1080, height: 1920)` |
| `Free Return/Levels/manifest.json` | Bundle resource: ordered list of level IDs |
| `Free Return/Levels/levels/level-001.json` | Bundle resource: first level (replaces hardcoded test level) |
| `Free Return Tests/LevelLoaderTests.swift` | Unit tests for loader |
| `Free Return Tests/LevelBuilderTests.swift` | Unit tests for builder |
| `Free Return Tests/Fixtures/...` | JSON fixtures for tests |

**Modified files:**

| Path | Change |
|---|---|
| `Free Return/GameScene.swift` | Remove `setupTestLevel`; replace with `LevelLoader.load(id:)` + `LevelBuilder.build(...)`; add `showFatalError`; bump tunables (`maxDragDistance`, `offScreenBuffer`) for the new larger canvas |
| `Free Return/GameViewController.swift` | Set `scene.size = WorldCanvas.size` and `scene.scaleMode = .aspectFill` |
| `Free Return.xcodeproj/project.pbxproj` | Add new source files to the `Free Return` target; add `Levels/` as a **Folder Reference** (preserves directory structure in bundle); add `Free Return Tests` target if it doesn't exist; wire test fixtures into the test bundle |

## Data Model

```swift
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
    let id: String        // e.g. "level-001" — must match filename
    let name: String      // human-readable, e.g. "First Steps"
    let shipStart: Vec2
    let planets: [PlanetData]
    let target: TargetZoneData
}

struct LevelManifest: Codable, Equatable {
    let levels: [String]  // ordered IDs
}
```

**Decisions:**
- `Vec2` instead of `CGPoint` directly: `CGPoint`'s default Codable form is `[x, y]` array; an explicit struct gives `{x, y}` object form, which is clearer in JSON.
- All numeric fields use `CGFloat` to match `PhysicsSimulator.swift`. No `Float`/`Double` mixing.
- No optional fields, no defaults, no `schemaVersion`. Malformed levels fail loudly. New entity types get added when they ship.
- `Equatable` everywhere for trivial test assertions.
- No initial-velocity field: today's mechanic is drag-to-launch from rest.
- Single target zone. Multi-target → future change.
- Visual styling is not in level data. Renderer picks `.systemBlue` for now. Add a `style` field when there are actually multiple planet looks.

## Sample Files

**`Levels/levels/level-001.json`** (equivalent to today's hardcoded test level on the 1080×1920 canvas):

```json
{
  "id": "level-001",
  "name": "First Steps",
  "shipStart": { "x": 540, "y": 346 },
  "planets": [
    { "position": { "x": 540, "y": 960 }, "mass": 8000, "radius": 40 }
  ],
  "target": { "position": { "x": 540, "y": 1690 }, "radius": 30 }
}
```

Y-coordinate derivation: 346 = round(0.18 × 1920); 1690 = round(0.88 × 1920); 960 = 0.50 × 1920.

**`Levels/manifest.json`:**

```json
{ "levels": ["level-001"] }
```

## Storage Layout

```
Free Return/
└── Levels/
    ├── manifest.json
    └── levels/
        ├── level-001.json
        └── (level-002.json, level-003.json, ...)
```

- `Levels/` is added to the Xcode target as a **Folder Reference** (blue folder), not a Group Reference (yellow). Folder references preserve directory structure inside the app bundle.
- Loader uses `Bundle.main.url(forResource:withExtension:subdirectory:)` with `subdirectory: "Levels/levels"` for level files and `subdirectory: "Levels"` for the manifest.

**ID convention:**
- Level ID equals the filename without extension (`level-001.json` → `"level-001"`).
- Loader validates that the JSON's `"id"` field matches the requested ID. Mismatch is an error.

## Loader API

```swift
enum LevelLoaderError: Error, Equatable {
    case manifestNotFound
    case levelNotFound(id: String)
    case decodeFailed(id: String, underlying: String)
    case idMismatch(expected: String, actual: String)
}

enum LevelLoader {
    static func loadManifest(bundle: Bundle = .main) throws -> LevelManifest
    static func load(id: String, bundle: Bundle = .main) throws -> Level
    static func loadAll(bundle: Bundle = .main) throws -> [Level]
}
```

**Behavior:**
- `loadManifest` reads `Levels/manifest.json`. Missing file → `.manifestNotFound`. Decode failure → `.decodeFailed(id: "manifest", ...)`.
- `load(id:)` reads `Levels/levels/<id>.json`. Missing → `.levelNotFound(id:)`. Decode failure → `.decodeFailed`. JSON `id` mismatch with requested ID → `.idMismatch`.
- `loadAll` is `loadManifest` + `try manifest.levels.map { try load(id: $0) }`. Used by the smoke test that validates every shipped level decodes cleanly.
- `bundle` parameter is injectable so tests use a fixture bundle (`Bundle(for: SomeTestClass.self)`).
- Stateless. No caching. Loads are infrequent and small; if profiling later shows it matters, add caching then.

## Coordinate Scaling

```swift
enum WorldCanvas {
    static let size = CGSize(width: 1080, height: 1920)
}
```

- `GameViewController` sets `scene.size = WorldCanvas.size` and `scene.scaleMode = .aspectFill`. SpriteKit handles the scale-to-fit / letterbox automatically.
- Physics constants and level-data values both live in this 1080×1920 space — physics is now device-independent.
- Existing scene-coordinate constants in `GameScene` need re-tuning for the larger canvas:
  - `maxDragDistance: CGFloat = 80` → `220` (≈ 80 × 1080/390, where 390 ≈ today's iPhone scene width in points). Final value tuned during implementation.
  - `offScreenBuffer: CGFloat = 300` → `800`. Final value tuned during implementation.
  - `launchSpeedScale: CGFloat = 3` likely needs no change (it's a unitless multiplier on drag distance, but with drag and physics both scaled up, retuning may be required — verified in implementation).

## LevelBuilder

```swift
struct BuiltLevel {
    let spacecraft: SpacecraftNode
    let trajectoryPreview: TrajectoryPreview
    let targetZone: TargetZoneNode
    let planetNodes: [SKNode]
    let gravityBodies: [GravityBody]
    let shipStart: CGPoint
}

enum LevelBuilder {
    static func build(_ level: Level, into scene: SKScene) -> BuiltLevel
}
```

**Responsibilities:**
1. For each `PlanetData`: create a `GravityBody`, create an `SKShapeNode` planet visual (the existing `makePlanetNode` logic moves out of `GameScene` into here), add the visual to the scene.
2. Create the `SpacecraftNode` at `level.shipStart`, add it to the scene.
3. Create the `TargetZoneNode` from `level.target`, add it to the scene.
4. Create the `TrajectoryPreview`, add it to the scene.
5. Return a `BuiltLevel` struct with references to everything created. `GameScene` assigns its private properties from the returned struct.

This avoids exposing `GameScene`'s internals or having `LevelBuilder` reach into a concrete `GameScene` type — it takes `SKScene` and returns refs explicitly.

**Why move builder logic out of `GameScene`:** keeps `GameScene` focused on input + state machine, and lets `LevelBuilder` be unit-tested with a bare `SKScene` (no `SKView` needed).

## GameScene Integration

```swift
override func didMove(to view: SKView) {
    backgroundColor = SKColor(red: 0.03, green: 0.03, blue: 0.12, alpha: 1)
    do {
        let level = try LevelLoader.load(id: "level-001")
        let built = LevelBuilder.build(level, into: self)
        spacecraft = built.spacecraft
        trajectoryPreview = built.trajectoryPreview
        targetZone = built.targetZone
        gravityBodies = built.gravityBodies
        shipStart = built.shipStart
        setupHUD()
    } catch {
        showFatalError(error)
    }
}

private func showFatalError(_ error: Error) {
    backgroundColor = .black
    let label = SKLabelNode(text: "Level load failed:\n\(error)")
    label.fontName = "Avenir-Heavy"
    label.fontSize = 18
    label.fontColor = .systemRed
    label.numberOfLines = 0
    label.preferredMaxLayoutWidth = WorldCanvas.size.width - 80
    label.position = CGPoint(x: WorldCanvas.size.width / 2,
                             y: WorldCanvas.size.height / 2)
    addChild(label)
}
```

- `setupTestLevel()` is deleted entirely.
- `resetLevel()` keeps using the stored `shipStart`, which now comes from the loaded `Level`.

## Error Handling

- A bundled level failing to decode is a build/data bug, not a recoverable runtime state.
- `GameScene.didMove(to:)` catches and shows a red on-black overlay with the error description. No crash, no fallback level, no retry.

## Testing

A `Free Return Tests` unit test target is added if it doesn't already exist.

**Test fixtures** (in test target bundle, at `TestFixtures/`):
- `valid-minimal.json` — one planet
- `valid-multi-planet.json` — three planets
- `mismatched-id.json` — JSON id ≠ filename id
- `malformed.json` — invalid JSON syntax
- `missing-required-field.json` — e.g. no `target`
- `valid-manifest.json`
- `manifest-references-missing-level.json`

**Test cases:**

1. `LevelLoader.load` returns the expected `Level` for `valid-minimal.json` — assert all fields equal.
2. `LevelLoader.load` decodes `valid-multi-planet.json` correctly; planet count and order preserved.
3. `LevelLoader.load` throws `.idMismatch` for `mismatched-id.json`.
4. `LevelLoader.load` throws `.decodeFailed` for `malformed.json`.
5. `LevelLoader.load` throws `.decodeFailed` for `missing-required-field.json`.
6. `LevelLoader.load` throws `.levelNotFound` for an ID with no file.
7. `LevelLoader.loadManifest` returns level IDs in declared order.
8. `LevelLoader.loadManifest` throws `.manifestNotFound` when the manifest is absent.
9. `LevelLoader.loadAll` returns one `Level` per manifest entry, in order.
10. `LevelLoader.loadAll` throws when the manifest references a missing level.
11. **Smoke test against the production bundle:** `LevelLoader.loadAll(bundle: .main)` succeeds. Catches "added a level, forgot a field" regressions at test time.
12. `LevelBuilder.build`: for a known fixture, the scene contains the expected number of planet nodes, the spacecraft is at `level.shipStart`, the target zone is at the expected position, and the returned `[GravityBody]` matches `level.planets` 1:1.
13. `Vec2` round-trips through `JSONEncoder`/`JSONDecoder` with object form `{"x": _, "y": _}`.

## Out of Scope

These are deliberately deferred to follow-up specs:

- Level select UI / level browser screen.
- Progression: which levels are unlocked / completed, persistence of player state.
- "Next level" flow after winning.
- Level editor / authoring tools.
- New gameplay entities (kinetic bumpers, asteroid belts, wormholes, moving bodies). The schema is intentionally narrow today; each new entity gets its own design when it lands.
- Visual styling per planet (color, sprite). Rendering picks defaults today.
- `schemaVersion` field. Add when the first breaking schema change is needed.
