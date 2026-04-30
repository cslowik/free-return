# Level Data Model Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hardcoded test level in `GameScene` with a Codable level data model loaded from JSON files in the app bundle, on a fixed 1080×1920 virtual canvas.

**Architecture:** Codable value types (`Vec2`, `PlanetData`, `TargetZoneData`, `Level`, `LevelManifest`) bundled as JSON resources. A static `LevelLoader` reads/decodes; a `LevelBuilder` instantiates scene nodes from a decoded `Level` and returns a `BuiltLevel` struct. `GameScene` wires the result into its existing fields.

**Tech Stack:** Swift 5, SpriteKit, XCTest, Xcode 15+. JSON via `JSONDecoder` (default `.useDefaultKeys`).

**Spec:** `docs/superpowers/specs/2026-04-29-level-data-model-design.md` — read this first.

**Conventions for this plan:**
- All paths are relative to the repo root: `/Users/chrisslowik/Developer/Free Return/`
- Source paths use `Free Return/...` (note the space).
- Test paths use `Free Return Tests/...`
- Run tests from the terminal with:
  ```
  xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Free Return Tests/<ClassName>/<methodName>"
  ```
  Or in Xcode: ⌘U for the whole suite, or click the diamond next to the test method.
- After every task, commit. Use `git add <specific files>`, never `git add .`.

---

## Task 1: Add `Free Return Tests` unit test target

**Files:**
- Modify (via Xcode UI): `Free Return.xcodeproj/project.pbxproj`

This is Xcode-UI work, not file-editing work. The pbxproj should not be edited by hand.

- [ ] **Step 1: Create the test target**

In Xcode: open `Free Return.xcodeproj`. File → New → Target… → iOS tab → "Unit Testing Bundle". Click Next.

Settings:
- Product Name: `Free Return Tests`
- Team: (leave default)
- Organization Identifier: (whatever the app target uses)
- Bundle Identifier: auto-derived
- Language: Swift
- Project: Free Return
- Target to be Tested: Free Return

Click Finish. Xcode creates a `Free Return Tests/` group with a starter `Free_Return_Tests.swift`.

- [ ] **Step 2: Verify the starter test runs**

In Xcode, ⌘U. Expected: build succeeds, the starter test (which is empty) passes.

Or from terminal:
```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15'
```
Expected: `** TEST SUCCEEDED **`.

If iPhone 15 isn't available, run `xcrun simctl list devices available` and substitute a real device name into the `-destination` flag.

- [ ] **Step 3: Delete the starter test file**

In Xcode, right-click `Free_Return_Tests.swift` → Delete → Move to Trash.

- [ ] **Step 4: Commit**

```bash
git add "Free Return.xcodeproj/project.pbxproj"
git commit -m "Add Free Return Tests unit test target"
```

---

## Task 2: Create `WorldCanvas` constant

**Files:**
- Create: `Free Return/Levels/WorldCanvas.swift`

- [ ] **Step 1: Create `Free Return/Levels/` group in Xcode**

In Xcode project navigator, right-click the `Free Return` group → New Group → name it `Levels`. This creates a yellow group (folder reference comes later, in Task 11).

- [ ] **Step 2: Create the file via Xcode**

Right-click the `Levels` group → New File → Swift File → name `WorldCanvas.swift`. Ensure target membership: `Free Return` only (NOT the test target).

- [ ] **Step 3: Write the file contents**

Replace the file contents with:

```swift
//
//  WorldCanvas.swift
//  Free Return
//

import CoreGraphics

enum WorldCanvas {
    static let size = CGSize(width: 1080, height: 1920)
}
```

- [ ] **Step 4: Verify build**

⌘B in Xcode. Expected: build succeeds.

- [ ] **Step 5: Commit**

```bash
git add "Free Return/Levels/WorldCanvas.swift" "Free Return.xcodeproj/project.pbxproj"
git commit -m "Add WorldCanvas constant for fixed virtual canvas size"
```

---

## Task 3: `Vec2` Codable struct (TDD)

**Files:**
- Test: `Free Return Tests/Levels/Vec2Tests.swift`
- Create: `Free Return/Levels/Level.swift` (will hold all level data structs)

- [ ] **Step 1: Create `Free Return Tests/Levels/` group**

In Xcode, right-click `Free Return Tests` → New Group → `Levels`.

- [ ] **Step 2: Write the failing test**

Create `Free Return Tests/Levels/Vec2Tests.swift` via Xcode (target membership: `Free Return Tests` only). Replace contents:

```swift
//
//  Vec2Tests.swift
//  Free Return Tests
//

import XCTest
@testable import Free_Return

final class Vec2Tests: XCTestCase {

    func test_decodesObjectFormFromJSON() throws {
        let json = #"{"x": 12.5, "y": -3.25}"#.data(using: .utf8)!
        let v = try JSONDecoder().decode(Vec2.self, from: json)
        XCTAssertEqual(v.x, 12.5)
        XCTAssertEqual(v.y, -3.25)
    }

    func test_roundTrips() throws {
        let original = Vec2(x: 7, y: 11)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Vec2.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
```

(Module name: when the app target is `Free Return`, `@testable import` uses an underscore-substituted name — `Free_Return`. If your build settings specify a different module name, adjust accordingly.)

- [ ] **Step 3: Run the test — expect compile failure**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Free Return Tests/Vec2Tests"
```
Expected: build error — `Cannot find 'Vec2' in scope`.

- [ ] **Step 4: Create `Level.swift`**

Create `Free Return/Levels/Level.swift` via Xcode (target membership: `Free Return` only). Replace contents:

```swift
//
//  Level.swift
//  Free Return
//

import CoreGraphics

struct Vec2: Codable, Equatable {
    let x: CGFloat
    let y: CGFloat
}
```

- [ ] **Step 5: Run the test — expect pass**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Free Return Tests/Vec2Tests"
```
Expected: both `test_decodesObjectFormFromJSON` and `test_roundTrips` pass.

- [ ] **Step 6: Commit**

```bash
git add "Free Return/Levels/Level.swift" "Free Return Tests/Levels/Vec2Tests.swift" "Free Return.xcodeproj/project.pbxproj"
git commit -m "Add Vec2 Codable struct"
```

---

## Task 4: `PlanetData`, `TargetZoneData`, `Level` (TDD)

**Files:**
- Test: `Free Return Tests/Levels/LevelDecodingTests.swift`
- Modify: `Free Return/Levels/Level.swift`

- [ ] **Step 1: Write the failing test**

Create `Free Return Tests/Levels/LevelDecodingTests.swift` (target: `Free Return Tests` only):

```swift
//
//  LevelDecodingTests.swift
//  Free Return Tests
//

import XCTest
@testable import Free_Return

final class LevelDecodingTests: XCTestCase {

    func test_decodesCompleteLevel() throws {
        let json = #"""
        {
          "id": "level-001",
          "name": "First Steps",
          "shipStart": { "x": 540, "y": 346 },
          "planets": [
            { "position": { "x": 540, "y": 960 }, "mass": 8000, "radius": 40 }
          ],
          "target": { "position": { "x": 540, "y": 1690 }, "radius": 30 }
        }
        """#.data(using: .utf8)!

        let level = try JSONDecoder().decode(Level.self, from: json)

        XCTAssertEqual(level.id, "level-001")
        XCTAssertEqual(level.name, "First Steps")
        XCTAssertEqual(level.shipStart, Vec2(x: 540, y: 346))
        XCTAssertEqual(level.planets.count, 1)
        XCTAssertEqual(level.planets[0].position, Vec2(x: 540, y: 960))
        XCTAssertEqual(level.planets[0].mass, 8000)
        XCTAssertEqual(level.planets[0].radius, 40)
        XCTAssertEqual(level.target.position, Vec2(x: 540, y: 1690))
        XCTAssertEqual(level.target.radius, 30)
    }

    func test_decodesMultiplePlanetsInOrder() throws {
        let json = #"""
        {
          "id": "level-002",
          "name": "Triple",
          "shipStart": { "x": 0, "y": 0 },
          "planets": [
            { "position": { "x": 1, "y": 1 }, "mass": 100, "radius": 10 },
            { "position": { "x": 2, "y": 2 }, "mass": 200, "radius": 20 },
            { "position": { "x": 3, "y": 3 }, "mass": 300, "radius": 30 }
          ],
          "target": { "position": { "x": 9, "y": 9 }, "radius": 5 }
        }
        """#.data(using: .utf8)!

        let level = try JSONDecoder().decode(Level.self, from: json)

        XCTAssertEqual(level.planets.map(\.mass), [100, 200, 300])
    }

    func test_failsWhenRequiredFieldMissing() {
        // Missing "target" field
        let json = #"""
        {
          "id": "level-003",
          "name": "Broken",
          "shipStart": { "x": 0, "y": 0 },
          "planets": []
        }
        """#.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(Level.self, from: json))
    }
}
```

- [ ] **Step 2: Run the test — expect compile failure**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Free Return Tests/LevelDecodingTests"
```
Expected: build error — `Cannot find 'Level' / 'PlanetData' / 'TargetZoneData' in scope`.

- [ ] **Step 3: Add the structs**

Append to `Free Return/Levels/Level.swift`:

```swift
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
```

- [ ] **Step 4: Run the test — expect pass**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Free Return Tests/LevelDecodingTests"
```
Expected: all three tests pass.

- [ ] **Step 5: Commit**

```bash
git add "Free Return/Levels/Level.swift" "Free Return Tests/Levels/LevelDecodingTests.swift" "Free Return.xcodeproj/project.pbxproj"
git commit -m "Add Level / PlanetData / TargetZoneData Codable structs"
```

---

## Task 5: `LevelManifest` Codable struct (TDD)

**Files:**
- Test: `Free Return Tests/Levels/LevelManifestTests.swift`
- Create: `Free Return/Levels/LevelManifest.swift`

- [ ] **Step 1: Write the failing test**

Create `Free Return Tests/Levels/LevelManifestTests.swift` (target: `Free Return Tests`):

```swift
//
//  LevelManifestTests.swift
//  Free Return Tests
//

import XCTest
@testable import Free_Return

final class LevelManifestTests: XCTestCase {

    func test_decodesOrderedLevelIDs() throws {
        let json = #"""
        { "levels": ["level-001", "level-002", "level-003"] }
        """#.data(using: .utf8)!

        let manifest = try JSONDecoder().decode(LevelManifest.self, from: json)

        XCTAssertEqual(manifest.levels, ["level-001", "level-002", "level-003"])
    }

    func test_decodesEmptyList() throws {
        let json = #"{ "levels": [] }"#.data(using: .utf8)!
        let manifest = try JSONDecoder().decode(LevelManifest.self, from: json)
        XCTAssertEqual(manifest.levels, [])
    }
}
```

- [ ] **Step 2: Run — expect compile failure**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Free Return Tests/LevelManifestTests"
```
Expected: `Cannot find 'LevelManifest' in scope`.

- [ ] **Step 3: Create `LevelManifest.swift`**

Create `Free Return/Levels/LevelManifest.swift` via Xcode (target: `Free Return`):

```swift
//
//  LevelManifest.swift
//  Free Return
//

import Foundation

struct LevelManifest: Codable, Equatable {
    let levels: [String]
}
```

- [ ] **Step 4: Run — expect pass**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Free Return Tests/LevelManifestTests"
```
Expected: both tests pass.

- [ ] **Step 5: Commit**

```bash
git add "Free Return/Levels/LevelManifest.swift" "Free Return Tests/Levels/LevelManifestTests.swift" "Free Return.xcodeproj/project.pbxproj"
git commit -m "Add LevelManifest Codable struct"
```

---

## Task 6: `LevelLoaderError` + `LevelLoader.loadManifest` (TDD)

This task introduces test fixtures bundled in the test target. We add `Free Return Tests/Fixtures/Levels/` as a Folder Reference so the directory structure is preserved in the test bundle.

**Files:**
- Create: `Free Return Tests/Fixtures/Levels/manifest-valid.json`
- Create: `Free Return Tests/Fixtures/Levels/manifest-bad-shape/manifest.json` (folder for "exists but malformed" case — different subdirectory)
- Test: `Free Return Tests/Levels/LevelLoaderManifestTests.swift`
- Create: `Free Return/Levels/LevelLoader.swift`

- [ ] **Step 1: Create the fixtures directory**

```bash
mkdir -p "Free Return Tests/Fixtures/Levels"
mkdir -p "Free Return Tests/Fixtures/Levels-bad/Levels"
```

- [ ] **Step 2: Write fixture files**

`Free Return Tests/Fixtures/Levels/manifest.json`:

```json
{ "levels": ["level-001", "level-002"] }
```

`Free Return Tests/Fixtures/Levels-bad/Levels/manifest.json`:

```json
{ this is not valid json
```

- [ ] **Step 3: Add fixtures to Xcode test target as Folder References**

In Xcode: right-click `Free Return Tests` → "Add Files to 'Free Return'…" → navigate to `Free Return Tests/Fixtures/`. **Important:** in the dialog, choose:
- "Create folder references" (NOT "Create groups")
- Add to targets: `Free Return Tests` only

The `Fixtures` folder appears as a blue folder in the project navigator. Repeat for `Levels-bad` if it isn't included automatically.

Verify the test bundle includes them: in `Free Return Tests` target → Build Phases → Copy Bundle Resources should list `Fixtures` (or its contents).

- [ ] **Step 4: Write the failing test**

Create `Free Return Tests/Levels/LevelLoaderManifestTests.swift` (target: `Free Return Tests`):

```swift
//
//  LevelLoaderManifestTests.swift
//  Free Return Tests
//

import XCTest
@testable import Free_Return

final class LevelLoaderManifestTests: XCTestCase {

    private var goodBundle: Bundle { Bundle(for: type(of: self)) }

    func test_loadsManifest_returnsLevelsInOrder() throws {
        // Fixtures live under Fixtures/Levels in the test bundle.
        // We point the loader at a per-test bundle wrapper that exposes the right subdir.
        let manifest = try LevelLoader.loadManifest(
            bundle: goodBundle,
            subdirectory: "Fixtures/Levels"
        )
        XCTAssertEqual(manifest.levels, ["level-001", "level-002"])
    }

    func test_loadsManifest_throwsManifestNotFound_whenAbsent() {
        XCTAssertThrowsError(
            try LevelLoader.loadManifest(
                bundle: goodBundle,
                subdirectory: "Fixtures/DoesNotExist"
            )
        ) { error in
            XCTAssertEqual(error as? LevelLoaderError, .manifestNotFound)
        }
    }

    func test_loadsManifest_throwsDecodeFailed_whenMalformed() {
        XCTAssertThrowsError(
            try LevelLoader.loadManifest(
                bundle: goodBundle,
                subdirectory: "Fixtures/Levels-bad/Levels"
            )
        ) { error in
            guard case .decodeFailed(let id, _) = error as? LevelLoaderError else {
                return XCTFail("Expected .decodeFailed, got \(error)")
            }
            XCTAssertEqual(id, "manifest")
        }
    }
}
```

(Note: this test signature uses `subdirectory:` so we can point at fixtures without monkey-patching the production bundle layout. Production code calls without the parameter via a default — see Step 5.)

- [ ] **Step 5: Run — expect compile failure**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Free Return Tests/LevelLoaderManifestTests"
```
Expected: `Cannot find 'LevelLoader' / 'LevelLoaderError' in scope`.

- [ ] **Step 6: Implement `LevelLoader`**

Create `Free Return/Levels/LevelLoader.swift` (target: `Free Return`):

```swift
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

    static let defaultManifestSubdirectory = "Levels"
    static let defaultLevelsSubdirectory = "Levels/levels"

    static func loadManifest(
        bundle: Bundle = .main,
        subdirectory: String = defaultManifestSubdirectory
    ) throws -> LevelManifest {
        guard let url = bundle.url(
            forResource: "manifest",
            withExtension: "json",
            subdirectory: subdirectory
        ) else {
            throw LevelLoaderError.manifestNotFound
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw LevelLoaderError.manifestNotFound
        }
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
```

- [ ] **Step 7: Run — expect pass**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Free Return Tests/LevelLoaderManifestTests"
```
Expected: all three tests pass.

- [ ] **Step 8: Commit**

```bash
git add "Free Return/Levels/LevelLoader.swift" "Free Return Tests/Levels/LevelLoaderManifestTests.swift" "Free Return Tests/Fixtures" "Free Return.xcodeproj/project.pbxproj"
git commit -m "Add LevelLoader.loadManifest with bundle injection"
```

---

## Task 7: `LevelLoader.load(id:)` (TDD)

**Files:**
- Create: `Free Return Tests/Fixtures/Levels/levels/level-001.json`
- Create: `Free Return Tests/Fixtures/Levels/levels/level-002.json`
- Create: `Free Return Tests/Fixtures/Levels/levels/mismatched-id.json`
- Create: `Free Return Tests/Fixtures/Levels/levels/malformed.json`
- Create: `Free Return Tests/Fixtures/Levels/levels/missing-field.json`
- Test: `Free Return Tests/Levels/LevelLoaderLoadTests.swift`
- Modify: `Free Return/Levels/LevelLoader.swift`

- [ ] **Step 1: Create fixture level files**

`Free Return Tests/Fixtures/Levels/levels/level-001.json`:

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

`Free Return Tests/Fixtures/Levels/levels/level-002.json`:

```json
{
  "id": "level-002",
  "name": "Triple",
  "shipStart": { "x": 100, "y": 100 },
  "planets": [
    { "position": { "x": 200, "y": 400 }, "mass": 5000, "radius": 30 },
    { "position": { "x": 800, "y": 400 }, "mass": 5000, "radius": 30 },
    { "position": { "x": 540, "y": 1200 }, "mass": 7000, "radius": 35 }
  ],
  "target": { "position": { "x": 540, "y": 1700 }, "radius": 30 }
}
```

`Free Return Tests/Fixtures/Levels/levels/mismatched-id.json`:

```json
{
  "id": "actually-something-else",
  "name": "Wrong",
  "shipStart": { "x": 0, "y": 0 },
  "planets": [],
  "target": { "position": { "x": 0, "y": 0 }, "radius": 1 }
}
```

`Free Return Tests/Fixtures/Levels/levels/malformed.json`:

```
{ this is { not [ valid
```

`Free Return Tests/Fixtures/Levels/levels/missing-field.json`:

```json
{
  "id": "missing-field",
  "name": "No Target",
  "shipStart": { "x": 0, "y": 0 },
  "planets": []
}
```

(These are inside the existing `Fixtures` folder reference — they pick up automatically. Verify in Xcode that the `levels/` subdirectory shows under the blue `Fixtures` folder. If not, the folder reference is correctly tracking, but you may need to do File → Refresh in Finder, then close/reopen the project.)

- [ ] **Step 2: Write the failing test**

Create `Free Return Tests/Levels/LevelLoaderLoadTests.swift`:

```swift
//
//  LevelLoaderLoadTests.swift
//  Free Return Tests
//

import XCTest
@testable import Free_Return

final class LevelLoaderLoadTests: XCTestCase {

    private var bundle: Bundle { Bundle(for: type(of: self)) }
    private let subdir = "Fixtures/Levels/levels"

    func test_load_returnsExpectedLevel_forValidJSON() throws {
        let level = try LevelLoader.load(
            id: "level-001",
            bundle: bundle,
            subdirectory: subdir
        )
        XCTAssertEqual(level.id, "level-001")
        XCTAssertEqual(level.name, "First Steps")
        XCTAssertEqual(level.shipStart, Vec2(x: 540, y: 346))
        XCTAssertEqual(level.planets.count, 1)
        XCTAssertEqual(level.target.radius, 30)
    }

    func test_load_decodesMultiplePlanetsInOrder() throws {
        let level = try LevelLoader.load(
            id: "level-002",
            bundle: bundle,
            subdirectory: subdir
        )
        XCTAssertEqual(level.planets.map(\.mass), [5000, 5000, 7000])
    }

    func test_load_throwsLevelNotFound_whenFileMissing() {
        XCTAssertThrowsError(
            try LevelLoader.load(id: "level-999", bundle: bundle, subdirectory: subdir)
        ) { error in
            XCTAssertEqual(error as? LevelLoaderError, .levelNotFound(id: "level-999"))
        }
    }

    func test_load_throwsIdMismatch_whenJSONIDDiffersFromFilename() {
        XCTAssertThrowsError(
            try LevelLoader.load(id: "mismatched-id", bundle: bundle, subdirectory: subdir)
        ) { error in
            XCTAssertEqual(
                error as? LevelLoaderError,
                .idMismatch(expected: "mismatched-id", actual: "actually-something-else")
            )
        }
    }

    func test_load_throwsDecodeFailed_whenMalformed() {
        XCTAssertThrowsError(
            try LevelLoader.load(id: "malformed", bundle: bundle, subdirectory: subdir)
        ) { error in
            guard case .decodeFailed(let id, _) = error as? LevelLoaderError else {
                return XCTFail("Expected .decodeFailed, got \(error)")
            }
            XCTAssertEqual(id, "malformed")
        }
    }

    func test_load_throwsDecodeFailed_whenRequiredFieldMissing() {
        XCTAssertThrowsError(
            try LevelLoader.load(id: "missing-field", bundle: bundle, subdirectory: subdir)
        ) { error in
            guard case .decodeFailed(let id, _) = error as? LevelLoaderError else {
                return XCTFail("Expected .decodeFailed, got \(error)")
            }
            XCTAssertEqual(id, "missing-field")
        }
    }
}
```

- [ ] **Step 3: Run — expect compile failure**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Free Return Tests/LevelLoaderLoadTests"
```
Expected: build error — `LevelLoader has no member 'load'`.

- [ ] **Step 4: Implement `load`**

Append to `Free Return/Levels/LevelLoader.swift` (inside the `enum LevelLoader { ... }` block):

```swift
    static func load(
        id: String,
        bundle: Bundle = .main,
        subdirectory: String = defaultLevelsSubdirectory
    ) throws -> Level {
        guard let url = bundle.url(
            forResource: id,
            withExtension: "json",
            subdirectory: subdirectory
        ) else {
            throw LevelLoaderError.levelNotFound(id: id)
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw LevelLoaderError.levelNotFound(id: id)
        }
        let level: Level
        do {
            level = try JSONDecoder().decode(Level.self, from: data)
        } catch {
            throw LevelLoaderError.decodeFailed(
                id: id,
                underlying: String(describing: error)
            )
        }
        guard level.id == id else {
            throw LevelLoaderError.idMismatch(expected: id, actual: level.id)
        }
        return level
    }
```

- [ ] **Step 5: Run — expect pass**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Free Return Tests/LevelLoaderLoadTests"
```
Expected: all six tests pass.

- [ ] **Step 6: Commit**

```bash
git add "Free Return/Levels/LevelLoader.swift" "Free Return Tests/Levels/LevelLoaderLoadTests.swift" "Free Return Tests/Fixtures" "Free Return.xcodeproj/project.pbxproj"
git commit -m "Add LevelLoader.load(id:) with id-mismatch and decode-error handling"
```

---

## Task 8: `LevelLoader.loadAll` (TDD)

**Files:**
- Create: `Free Return Tests/Fixtures/Levels-missing-ref/Levels/manifest.json` (manifest references a level that doesn't exist alongside it)
- Test: `Free Return Tests/Levels/LevelLoaderLoadAllTests.swift`
- Modify: `Free Return/Levels/LevelLoader.swift`

- [ ] **Step 1: Create the broken-manifest fixture**

`Free Return Tests/Fixtures/Levels-missing-ref/Levels/manifest.json`:

```json
{ "levels": ["does-not-exist"] }
```

(Note: there is no corresponding `levels/does-not-exist.json` under this fixture's directory — that's the point.)

- [ ] **Step 2: Write the failing test**

Create `Free Return Tests/Levels/LevelLoaderLoadAllTests.swift`:

```swift
//
//  LevelLoaderLoadAllTests.swift
//  Free Return Tests
//

import XCTest
@testable import Free_Return

final class LevelLoaderLoadAllTests: XCTestCase {

    private var bundle: Bundle { Bundle(for: type(of: self)) }

    func test_loadAll_returnsLevelsInManifestOrder() throws {
        let levels = try LevelLoader.loadAll(
            bundle: bundle,
            manifestSubdirectory: "Fixtures/Levels",
            levelsSubdirectory: "Fixtures/Levels/levels"
        )
        XCTAssertEqual(levels.map(\.id), ["level-001", "level-002"])
    }

    func test_loadAll_throwsLevelNotFound_whenManifestReferencesMissingLevel() {
        XCTAssertThrowsError(
            try LevelLoader.loadAll(
                bundle: bundle,
                manifestSubdirectory: "Fixtures/Levels-missing-ref/Levels",
                levelsSubdirectory: "Fixtures/Levels-missing-ref/Levels/levels"
            )
        ) { error in
            XCTAssertEqual(
                error as? LevelLoaderError,
                .levelNotFound(id: "does-not-exist")
            )
        }
    }
}
```

- [ ] **Step 3: Run — expect compile failure**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Free Return Tests/LevelLoaderLoadAllTests"
```
Expected: `LevelLoader has no member 'loadAll'`.

- [ ] **Step 4: Implement `loadAll`**

Append inside `enum LevelLoader { ... }` in `Free Return/Levels/LevelLoader.swift`:

```swift
    static func loadAll(
        bundle: Bundle = .main,
        manifestSubdirectory: String = defaultManifestSubdirectory,
        levelsSubdirectory: String = defaultLevelsSubdirectory
    ) throws -> [Level] {
        let manifest = try loadManifest(
            bundle: bundle,
            subdirectory: manifestSubdirectory
        )
        return try manifest.levels.map {
            try load(id: $0, bundle: bundle, subdirectory: levelsSubdirectory)
        }
    }
```

- [ ] **Step 5: Run — expect pass**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Free Return Tests/LevelLoaderLoadAllTests"
```
Expected: both tests pass.

- [ ] **Step 6: Commit**

```bash
git add "Free Return/Levels/LevelLoader.swift" "Free Return Tests/Levels/LevelLoaderLoadAllTests.swift" "Free Return Tests/Fixtures" "Free Return.xcodeproj/project.pbxproj"
git commit -m "Add LevelLoader.loadAll convenience method"
```

---

## Task 9: `LevelBuilder` + `BuiltLevel` (TDD)

**Files:**
- Test: `Free Return Tests/Levels/LevelBuilderTests.swift`
- Create: `Free Return/Levels/LevelBuilder.swift`

- [ ] **Step 1: Write the failing test**

Create `Free Return Tests/Levels/LevelBuilderTests.swift`:

```swift
//
//  LevelBuilderTests.swift
//  Free Return Tests
//

import XCTest
import SpriteKit
@testable import Free_Return

final class LevelBuilderTests: XCTestCase {

    private func makeLevel() -> Level {
        Level(
            id: "test",
            name: "Test",
            shipStart: Vec2(x: 100, y: 200),
            planets: [
                PlanetData(position: Vec2(x: 300, y: 400), mass: 1000, radius: 25),
                PlanetData(position: Vec2(x: 500, y: 600), mass: 2000, radius: 35)
            ],
            target: TargetZoneData(position: Vec2(x: 700, y: 800), radius: 40)
        )
    }

    func test_build_addsExpectedNodesToScene() {
        let scene = SKScene(size: CGSize(width: 1080, height: 1920))
        let level = makeLevel()

        let built = LevelBuilder.build(level, into: scene)

        // Spacecraft, target zone, trajectory preview, and one node per planet.
        XCTAssertTrue(scene.children.contains(built.spacecraft))
        XCTAssertTrue(scene.children.contains(built.targetZone))
        XCTAssertTrue(scene.children.contains(built.trajectoryPreview))
        XCTAssertEqual(built.planetNodes.count, 2)
        for node in built.planetNodes {
            XCTAssertTrue(scene.children.contains(node))
        }
    }

    func test_build_positionsSpacecraftAtShipStart() {
        let scene = SKScene(size: CGSize(width: 1080, height: 1920))
        let level = makeLevel()

        let built = LevelBuilder.build(level, into: scene)

        XCTAssertEqual(built.spacecraft.position, CGPoint(x: 100, y: 200))
        XCTAssertEqual(built.shipStart, CGPoint(x: 100, y: 200))
    }

    func test_build_returnsGravityBodiesMatchingPlanetData() {
        let scene = SKScene(size: CGSize(width: 1080, height: 1920))
        let level = makeLevel()

        let built = LevelBuilder.build(level, into: scene)

        XCTAssertEqual(built.gravityBodies.count, 2)
        XCTAssertEqual(built.gravityBodies[0].position, CGPoint(x: 300, y: 400))
        XCTAssertEqual(built.gravityBodies[0].mass, 1000)
        XCTAssertEqual(built.gravityBodies[0].radius, 25)
        XCTAssertEqual(built.gravityBodies[1].position, CGPoint(x: 500, y: 600))
        XCTAssertEqual(built.gravityBodies[1].mass, 2000)
        XCTAssertEqual(built.gravityBodies[1].radius, 35)
    }

    func test_build_positionsTargetZoneCorrectly() {
        let scene = SKScene(size: CGSize(width: 1080, height: 1920))
        let level = makeLevel()

        let built = LevelBuilder.build(level, into: scene)

        XCTAssertEqual(built.targetZone.position, CGPoint(x: 700, y: 800))
        XCTAssertEqual(built.targetZone.radius, 40)
    }
}
```

- [ ] **Step 2: Run — expect compile failure**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Free Return Tests/LevelBuilderTests"
```
Expected: `Cannot find 'LevelBuilder' / 'BuiltLevel' in scope`.

- [ ] **Step 3: Implement `LevelBuilder`**

Create `Free Return/Levels/LevelBuilder.swift` (target: `Free Return`):

```swift
//
//  LevelBuilder.swift
//  Free Return
//

import SpriteKit

struct BuiltLevel {
    let spacecraft: SpacecraftNode
    let trajectoryPreview: TrajectoryPreview
    let targetZone: TargetZoneNode
    let planetNodes: [SKNode]
    let gravityBodies: [GravityBody]
    let shipStart: CGPoint
}

enum LevelBuilder {

    static func build(_ level: Level, into scene: SKScene) -> BuiltLevel {
        var planetNodes: [SKNode] = []
        var gravityBodies: [GravityBody] = []

        for planet in level.planets {
            let body = GravityBody(
                position: CGPoint(x: planet.position.x, y: planet.position.y),
                mass: planet.mass,
                radius: planet.radius
            )
            gravityBodies.append(body)

            let node = makePlanetNode(for: body, color: .systemBlue)
            scene.addChild(node)
            planetNodes.append(node)
        }

        let shipStart = CGPoint(x: level.shipStart.x, y: level.shipStart.y)
        let spacecraft = SpacecraftNode(at: shipStart)
        scene.addChild(spacecraft)

        let trajectoryPreview = TrajectoryPreview()
        scene.addChild(trajectoryPreview)

        let targetPosition = CGPoint(x: level.target.position.x, y: level.target.position.y)
        let targetZone = TargetZoneNode(at: targetPosition, radius: level.target.radius)
        scene.addChild(targetZone)

        return BuiltLevel(
            spacecraft: spacecraft,
            trajectoryPreview: trajectoryPreview,
            targetZone: targetZone,
            planetNodes: planetNodes,
            gravityBodies: gravityBodies,
            shipStart: shipStart
        )
    }

    private static func makePlanetNode(for body: GravityBody, color: SKColor) -> SKNode {
        let node = SKShapeNode(circleOfRadius: body.radius)
        node.position = body.position
        node.fillColor = color
        node.strokeColor = color.withAlphaComponent(0.4)
        node.lineWidth = body.radius * 0.25

        let halo = SKShapeNode(circleOfRadius: body.radius * 1.7)
        halo.fillColor = color.withAlphaComponent(0.08)
        halo.strokeColor = .clear
        node.addChild(halo)

        return node
    }
}
```

- [ ] **Step 4: Run — expect pass**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Free Return Tests/LevelBuilderTests"
```
Expected: all four tests pass.

- [ ] **Step 5: Commit**

```bash
git add "Free Return/Levels/LevelBuilder.swift" "Free Return Tests/Levels/LevelBuilderTests.swift" "Free Return.xcodeproj/project.pbxproj"
git commit -m "Add LevelBuilder that turns a Level into scene nodes"
```

---

## Task 10: Bundle production level + manifest as folder reference

**Files:**
- Create: `Free Return/Levels/manifest.json`
- Create: `Free Return/Levels/levels/level-001.json`
- Modify (Xcode UI): convert `Levels` to a folder reference for resources

This task ships actual gameplay content. The trick: `Levels/` is currently a yellow Group containing `.swift` files (compiled into the binary) AND we need its `.json` files to be copied as bundle resources with directory structure preserved.

The cleanest way: keep `.swift` files as a yellow Group, but add the JSON files and their directory as **folder references** separately. The folder reference becomes part of "Copy Bundle Resources" in build phases.

- [ ] **Step 1: Create the JSON files on disk**

```bash
mkdir -p "Free Return/Levels/levels"
```

`Free Return/Levels/manifest.json`:

```json
{ "levels": ["level-001"] }
```

`Free Return/Levels/levels/level-001.json`:

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

- [ ] **Step 2: Add as folder reference in Xcode**

In Xcode project navigator, right-click the existing `Levels` group → "Add Files to 'Free Return'…" → select `Free Return/Levels/manifest.json` and the `Free Return/Levels/levels` directory.

In the dialog:
- "Create folder references" (NOT "Create groups") — applies to the `levels` directory
- For the single `manifest.json` file, "Create groups" or "folder references" — the file itself doesn't matter, but ensure target membership: **`Free Return` only**, NOT the test target.

Verify under `Free Return` target → Build Phases → Copy Bundle Resources: `manifest.json` and the `levels` folder (blue) appear.

- [ ] **Step 3: Verify build succeeds**

In Xcode: ⌘B. Expected: build succeeds.

- [ ] **Step 4: Add a smoke test that the production bundle decodes**

Create `Free Return Tests/Levels/ProductionBundleSmokeTests.swift`:

```swift
//
//  ProductionBundleSmokeTests.swift
//  Free Return Tests
//
//  Critical regression test: every shipped level must decode cleanly.
//  Catches "added a level, forgot a field" before the app runs.
//

import XCTest
@testable import Free_Return

final class ProductionBundleSmokeTests: XCTestCase {

    func test_allBundledLevelsLoadSuccessfully() throws {
        let levels = try LevelLoader.loadAll(bundle: appBundle())
        XCTAssertFalse(levels.isEmpty, "Expected at least one bundled level")
        for level in levels {
            XCTAssertFalse(level.id.isEmpty)
            XCTAssertFalse(level.name.isEmpty)
        }
    }

    /// The app target's bundle, located by walking up from the test bundle.
    /// In iOS test runs, `Bundle.main` is the test runner — not the app under test.
    private func appBundle() -> Bundle {
        // The test target embeds the host app at runtime. Bundle for the app:
        if let host = Bundle.main.builtInPlugInsURL {
            // Not relevant for iOS unit test bundles; left as defensive fallback.
            _ = host
        }
        // For iOS unit tests configured with a host application, Bundle.main IS the host app.
        return Bundle.main
    }
}
```

- [ ] **Step 5: Run the smoke test**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Free Return Tests/ProductionBundleSmokeTests"
```
Expected: test passes (one level found, decodes cleanly).

If it fails with `manifestNotFound`: the folder reference in Step 2 wasn't set up correctly. Inspect the built `.app` bundle: in Xcode, Product → Show Build Folder in Finder → navigate to `Build/Products/Debug-iphonesimulator/Free Return.app/`. You should see `manifest.json` at the top level and a `levels/` folder beneath it. If they're missing, redo Step 2.

- [ ] **Step 6: Commit**

```bash
git add "Free Return/Levels/manifest.json" "Free Return/Levels/levels" "Free Return Tests/Levels/ProductionBundleSmokeTests.swift" "Free Return.xcodeproj/project.pbxproj"
git commit -m "Bundle level-001.json + manifest as folder reference; add smoke test"
```

---

## Task 11: Update `GameViewController` to use `WorldCanvas.size`

**Files:**
- Modify: `Free Return/GameViewController.swift`

- [ ] **Step 1: Edit `GameViewController.swift`**

Replace the contents of `Free Return/GameViewController.swift` with:

```swift
//
//  GameViewController.swift
//  Free Return
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let scene = GameScene(size: WorldCanvas.size)
        scene.scaleMode = .aspectFill

        if let view = self.view as? SKView {
            view.presentScene(scene)
            view.ignoresSiblingOrder = true
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
```

(The only change is `view.bounds.size` → `WorldCanvas.size`.)

- [ ] **Step 2: Verify build**

⌘B. Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add "Free Return/GameViewController.swift"
git commit -m "Use WorldCanvas.size for the SpriteKit scene"
```

---

## Task 12: Wire `LevelLoader` + `LevelBuilder` into `GameScene`

**Files:**
- Modify: `Free Return/GameScene.swift`

This task removes `setupTestLevel` and `makePlanetNode`, and routes scene setup through `LevelLoader.load(id:)` + `LevelBuilder.build`.

- [ ] **Step 1: Replace the contents of `GameScene.swift`**

Replace `Free Return/GameScene.swift` with:

```swift
//
//  GameScene.swift
//  Free Return
//

import SpriteKit

private enum GameState {
    case aiming
    case flying
    case won
    case crashed
}

class GameScene: SKScene {

    // World — wired up by LevelBuilder
    private var spacecraft: SpacecraftNode!
    private var trajectoryPreview: TrajectoryPreview!
    private var targetZone: TargetZoneNode!
    private var gravityBodies: [GravityBody] = []
    private var shipStart: CGPoint = .zero

    // State
    private var gameState: GameState = .aiming
    private var messageNode: SKNode?

    // Drag input
    private var isDragging = false
    private let maxDragDistance: CGFloat = 80
    private let launchSpeedScale: CGFloat = 3

    // Bounds — how far off-screen before we declare the craft lost
    private let offScreenBuffer: CGFloat = 300

    // HUD
    private let restartButtonName = "restartButton"

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

    private func setupHUD() {
        let restart = SKLabelNode(text: "↺")
        restart.fontName = "Avenir-Heavy"
        restart.fontSize = 32
        restart.fontColor = SKColor(white: 1, alpha: 0.55)
        restart.position = CGPoint(x: 35, y: size.height - 70)
        restart.name = restartButtonName
        restart.zPosition = 100
        restart.horizontalAlignmentMode = .center
        addChild(restart)
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

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let pos = touch.location(in: self)

        if isRestartTap(at: pos) {
            resetLevel()
            return
        }

        if gameState == .won || gameState == .crashed {
            resetLevel()
            return
        }

        guard gameState == .aiming else { return }
        if pos.distance(to: spacecraft.position) < 44 {
            isDragging = true
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let touch = touches.first else { return }
        let velocity = launchVector(from: spacecraft.position, draggedTo: touch.location(in: self))
        let previewState = SimState(position: spacecraft.position, velocity: velocity)
        trajectoryPreview.update(from: previewState, bodies: gravityBodies)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let touch = touches.first else { return }
        isDragging = false
        trajectoryPreview.hide()
        let velocity = launchVector(from: spacecraft.position, draggedTo: touch.location(in: self))
        spacecraft.launch(velocity: velocity)
        gameState = .flying
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
        trajectoryPreview.hide()
    }

    private func isRestartTap(at pos: CGPoint) -> Bool {
        nodes(at: pos).contains { $0.name == restartButtonName }
    }

    // MARK: - Launch math

    private func launchVector(from origin: CGPoint, draggedTo dragPoint: CGPoint) -> CGVector {
        let raw = CGVector(dx: dragPoint.x - origin.x, dy: dragPoint.y - origin.y)
        let clamped = raw.clamped(to: maxDragDistance)
        return CGVector(dx: -clamped.dx * launchSpeedScale, dy: -clamped.dy * launchSpeedScale)
    }

    // MARK: - Update / Collisions

    override func update(_ currentTime: TimeInterval) {
        spacecraft?.advance(bodies: gravityBodies, dt: 1.0 / 60.0)
        if gameState == .flying {
            checkCollisions()
        }
    }

    private func checkCollisions() {
        guard let spacecraft = spacecraft else { return }
        let pos = spacecraft.simState.position

        if targetZone.contains(pos) {
            winLevel()
            return
        }

        for body in gravityBodies {
            if pos.distance(to: body.position) <= body.radius {
                crash(at: pos)
                return
            }
        }

        if pos.x < -offScreenBuffer || pos.x > size.width + offScreenBuffer ||
           pos.y < -offScreenBuffer || pos.y > size.height + offScreenBuffer {
            crash(at: pos)
        }
    }

    // MARK: - Outcomes

    private func winLevel() {
        gameState = .won
        playBurst(at: spacecraft.position, color: .systemGreen, count: 3)
        spacecraft.isHidden = true
        showMessage("Free Return Achieved", color: .systemGreen)
    }

    private func crash(at position: CGPoint) {
        gameState = .crashed
        playBurst(at: position, color: .systemRed, count: 1)
        spacecraft.isHidden = true
        showMessage("Lost in Space", color: .systemRed)
    }

    private func resetLevel() {
        clearMessage()
        spacecraft.reset(at: shipStart)
        trajectoryPreview.hide()
        gameState = .aiming
    }

    // MARK: - Effects / Messages

    private func playBurst(at position: CGPoint, color: SKColor, count: Int) {
        for i in 0..<count {
            let burst = SKShapeNode(circleOfRadius: 8)
            burst.position = position
            burst.fillColor = .clear
            burst.strokeColor = color
            burst.lineWidth = 2
            burst.alpha = 0
            addChild(burst)

            burst.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.1 * Double(i)),
                SKAction.fadeIn(withDuration: 0.05),
                SKAction.group([
                    SKAction.scale(to: 4.5, duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func showMessage(_ text: String, color: SKColor) {
        clearMessage()

        let group = SKNode()
        group.zPosition = 90

        let title = SKLabelNode(text: text)
        title.fontName = "Avenir-Heavy"
        title.fontSize = 28
        title.fontColor = color
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 80)
        group.addChild(title)

        let hint = SKLabelNode(text: "Tap to retry")
        hint.fontName = "Avenir"
        hint.fontSize = 16
        hint.fontColor = SKColor(white: 1, alpha: 0.65)
        hint.position = CGPoint(x: size.width / 2, y: size.height / 2 + 45)
        group.addChild(hint)

        group.alpha = 0
        addChild(group)
        group.run(SKAction.fadeIn(withDuration: 0.3))
        messageNode = group
    }

    private func clearMessage() {
        messageNode?.removeFromParent()
        messageNode = nil
    }
}
```

**Changes summarized:**
- `setupTestLevel()` deleted.
- `makePlanetNode(for:color:)` deleted (moved into `LevelBuilder`).
- `didMove(to:)` now loads `level-001` and wires the result.
- `showFatalError` added.
- `update(_:)` now uses `spacecraft?.advance(...)` (optional chaining) so a failed load doesn't crash.
- `checkCollisions` early-returns if `spacecraft` is nil.

- [ ] **Step 2: Verify build**

⌘B. Expected: build succeeds.

- [ ] **Step 3: Run the smoke test plus the whole suite**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15'
```
Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add "Free Return/GameScene.swift"
git commit -m "Drive GameScene from LevelLoader + LevelBuilder"
```

---

## Task 13: Re-tune scene constants for the 1080×1920 canvas

**Files:**
- Modify: `Free Return/GameScene.swift`

The previous tunables were calibrated for ~390-point-wide iPhone screens. The scene is now 1080 points wide (≈ 2.77× larger). Drag distance and off-screen buffer must scale.

**Why each value:**
- `maxDragDistance: 80 → 220`: today the drag threshold is ~80 points on a ~390-wide screen, i.e. roughly 20% of the width. 220 / 1080 ≈ 20%. Same feel.
- `offScreenBuffer: 300 → 800`: the original 300-point buffer was ~75% of screen width. 800 / 1080 ≈ 75%. Same feel.
- `launchSpeedScale: 3` stays — it's a unitless multiplier, and the drag in/physics out are both in the same coordinate space, so the ratio is preserved.

These are starting values. Final tuning happens by playing the game; nothing in this plan asserts on them.

- [ ] **Step 1: Run the app once, observe failure mode (optional sanity check)**

In Xcode, ⌘R to run on a simulator. You'll see the level loaded, but if you try to drag-launch, the drag will feel cramped (because 80 points is a tiny fraction of the new canvas). This confirms the constants need updating.

- [ ] **Step 2: Update constants**

Edit `Free Return/GameScene.swift`:

Find:
```swift
    private let maxDragDistance: CGFloat = 80
    private let launchSpeedScale: CGFloat = 3
```
Change to:
```swift
    private let maxDragDistance: CGFloat = 220
    private let launchSpeedScale: CGFloat = 3
```

Find:
```swift
    private let offScreenBuffer: CGFloat = 300
```
Change to:
```swift
    private let offScreenBuffer: CGFloat = 800
```

- [ ] **Step 3: Run the app**

⌘R. Expected: drag-launch the ship — feel should match the original (~20% screen-width drag throw). Trajectory preview should appear during drag. Reaching the green target zone shows "Free Return Achieved". Crashing into the planet or flying way off-screen shows "Lost in Space".

If the launch feels off (too weak / too strong), nudge `launchSpeedScale` ±0.5 and re-run. Document the chosen value in a follow-up commit if you change it.

- [ ] **Step 4: Run the full test suite to confirm no regressions**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15'
```
Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add "Free Return/GameScene.swift"
git commit -m "Retune drag and off-screen buffer for 1080x1920 canvas"
```

---

## Task 14: Final integration sanity check

**Files:**
- (None modified — verification only.)

- [ ] **Step 1: Run the full test suite**

```
xcodebuild test -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15'
```
Expected: every test in every test file passes. Suite count should include:
- `Vec2Tests` (2)
- `LevelDecodingTests` (3)
- `LevelManifestTests` (2)
- `LevelLoaderManifestTests` (3)
- `LevelLoaderLoadTests` (6)
- `LevelLoaderLoadAllTests` (2)
- `LevelBuilderTests` (4)
- `ProductionBundleSmokeTests` (1)

**Total: 23 tests.**

- [ ] **Step 2: Run the app on simulator**

⌘R in Xcode. Play the level once — drag, launch, hit the target. Verify:
- The blue planet appears in the middle of the screen.
- Ship starts ~20% from the bottom.
- Target zone (green pulsing ring) is ~88% from the bottom.
- Drag-and-release launches the ship; trajectory preview shows during drag.
- Reaching the target shows "Free Return Achieved".
- Crashing into the planet shows "Lost in Space".
- Tapping the screen after a win/loss resets to aiming.
- Tapping the ↺ button at top-left resets at any time.

- [ ] **Step 3: Push to remote**

```bash
git push
```

The data model layer is complete. Future work (level select, progression, additional gameplay entities) can build on top.

---

## Self-Review Notes

The author of this plan ran the following checks:

**Spec coverage:** every section of the design spec maps to a task —
- Architecture, file structure → Tasks 2-12 collectively
- Data model → Tasks 3-4
- Sample files / storage layout → Tasks 7, 10
- Loader API → Tasks 6-8
- Coordinate scaling → Tasks 2, 11, 13
- LevelBuilder → Task 9
- GameScene integration → Task 12
- Error handling (`showFatalError`) → Task 12
- Testing (all 13 listed cases) → Tasks 3-10

**Type consistency:** `Vec2`/`PlanetData`/`TargetZoneData`/`Level`/`LevelManifest`/`LevelLoaderError`/`LevelLoader`/`BuiltLevel`/`LevelBuilder` are defined in their first introducing tasks and reused with the same signatures in later ones.

**Loader signature note:** the `LevelLoader` API in production code is `load(id:bundle:subdirectory:)` with `subdirectory` defaulted. The spec described `load(id:bundle:)` — equivalent at call sites, but the test-injectable subdirectory parameter is necessary so test fixtures can live alongside production code in the same test bundle. This is a minor extension of the spec, not a deviation.
