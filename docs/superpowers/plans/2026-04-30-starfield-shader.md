# Starfield Shader Background Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a procedural twinkling starfield as the GameScene background, scaffolded for future per-zone tint/seed.

**Architecture:** Single full-screen `SKSpriteNode` with an `SKShader` (GLSL-ES, compiled to Metal by SpriteKit). Procedural cell-hash starfield, two depth layers, per-star twinkle. Three uniforms: `u_zoneTint` (vec3), `u_zoneSeed` (float), `u_size` (vec2). Wired in `GameScene.didMove(to:)`.

**Tech Stack:** SpriteKit, SKShader (GLSL-ES 1.0 subset, SpriteKit-flavor), Swift, Xcode 16 file-system-synchronized groups (new files auto-added to the target).

---

## File Plan

- **Create:** `Free Return/Shaders/Starfield.fsh` — GLSL-ES fragment shader. Renders the tinted background and two starfield layers.
- **Create:** `Free Return/StarfieldBackground.swift` — small enum-namespaced factory that builds the configured `SKSpriteNode`.
- **Modify:** `Free Return/GameScene.swift` — `didMove(to:)`: add background sprite at `zPosition = -100`; remove the `backgroundColor = SKColor(red: 0.03, …)` line.

Xcode project membership: the project uses `PBXFileSystemSynchronizedRootGroup` (verified — `fileSystemSynchronizedGroups` present in `project.pbxproj`). New files dropped into `Free Return/` are auto-included. `.fsh` files are auto-classified as bundle resources by Xcode 16. **No `project.pbxproj` edits required.**

---

## Task 1: Create the Starfield fragment shader

**Files:**
- Create: `Free Return/Shaders/Starfield.fsh`

- [ ] **Step 1: Create the shader directory and file**

```bash
mkdir -p "Free Return/Shaders"
```

- [ ] **Step 2: Write the shader**

Create `Free Return/Shaders/Starfield.fsh` with the following exact contents:

```glsl
// Procedural twinkling starfield for SpriteKit (GLSL-ES 1.0).
// Uniforms (set by StarfieldBackground.swift):
//   u_zoneTint  vec3   background base color
//   u_zoneSeed  float  offsets the hash so different zones get different layouts
//   u_size      vec2   sprite size in points (used for aspect correction)

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec2 hash22(vec2 p) {
    vec2 q = vec2(dot(p, vec2(127.1, 311.7)),
                  dot(p, vec2(269.5, 183.3)));
    return fract(sin(q) * 43758.5453);
}

vec3 starLayer(vec2 uv, float density, float starSize, float threshold, float twinkleSpeed) {
    vec2 scaled = uv * density;
    vec2 cell = floor(scaled);
    vec2 frac = fract(scaled);
    vec3 col = vec3(0.0);

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 offset = vec2(float(x), float(y));
            vec2 ncell = cell + offset + vec2(u_zoneSeed);

            float presence = hash21(ncell);
            if (presence < threshold) {
                vec2 starPos = offset + 0.2 + 0.6 * hash22(ncell + 17.0);
                float dist = length(frac - starPos);

                float baseBrightness = 0.4 + 0.6 * hash21(ncell + 31.0);
                float phase = hash21(ncell + 53.0) * 6.28318;
                float twinkle = 0.65 + 0.35 * sin(u_time * twinkleSpeed + phase);

                float falloff = smoothstep(starSize, 0.0, dist);
                falloff = pow(falloff, 3.0);

                col += vec3(falloff * baseBrightness * twinkle);
            }
        }
    }
    return col;
}

void main() {
    vec2 uv = v_tex_coord;

    // Aspect-correct so stars are circular instead of squashed.
    float aspect = u_size.x / max(u_size.y, 1.0);
    vec2 auv = vec2(uv.x * aspect, uv.y);

    // Subtle vertical gradient: slightly brighter at the bottom.
    vec3 col = u_zoneTint * (0.9 + 0.15 * (1.0 - uv.y));

    // Sparse + bright foreground stars.
    col += starLayer(auv, 18.0, 0.04, 0.35, 1.4) * 1.0;
    // Dense + dim deep-background stars.
    col += starLayer(auv, 36.0, 0.025, 0.5, 1.0) * 0.45;

    gl_FragColor = vec4(col, 1.0);
}
```

- [ ] **Step 3: Commit**

```bash
git add "Free Return/Shaders/Starfield.fsh"
git commit -m "Add procedural starfield fragment shader"
```

---

## Task 2: Create the Swift factory

**Files:**
- Create: `Free Return/StarfieldBackground.swift`

- [ ] **Step 1: Write the factory**

Create `Free Return/StarfieldBackground.swift` with the following exact contents:

```swift
//
//  StarfieldBackground.swift
//  Free Return
//

import SpriteKit
import simd

enum StarfieldBackground {

    static func make(size: CGSize,
                     zoneTint: vector_float3 = vector_float3(0.03, 0.03, 0.12),
                     zoneSeed: Float = 0.0) -> SKSpriteNode {
        let node = SKSpriteNode(color: .black, size: size)
        node.anchorPoint = .zero
        node.position = .zero
        node.zPosition = -100

        let shader = SKShader(fileNamed: "Starfield.fsh")
        shader.uniforms = [
            SKUniform(name: "u_zoneTint", vectorFloat3: zoneTint),
            SKUniform(name: "u_zoneSeed", float: zoneSeed),
            SKUniform(name: "u_size",
                      vectorFloat2: vector_float2(Float(size.width),
                                                  Float(size.height)))
        ]
        node.shader = shader
        return node
    }
}
```

Notes for the engineer:
- `SKSpriteNode(color: .black, size:)` gives the shader real fragments to run on. The shader output replaces the color, so `.black` is just a safe fallback if the shader fails to load.
- `anchorPoint = .zero` + `position = .zero` aligns the sprite's bottom-left to the scene origin (SpriteKit default coord system).
- `zPosition = -100` keeps it behind every level element. Other nodes default to `0`; HUD is `100`; off-screen indicator is `80`.
- `SKShader(fileNamed:)` looks up `Starfield.fsh` in the main bundle. Xcode 16 sync'd groups auto-bundle `.fsh` as a resource.

- [ ] **Step 2: Commit**

```bash
git add "Free Return/StarfieldBackground.swift"
git commit -m "Add StarfieldBackground factory"
```

---

## Task 3: Wire the background into GameScene

**Files:**
- Modify: `Free Return/GameScene.swift` (`didMove(to:)`, around line 49–66)

- [ ] **Step 1: Replace `backgroundColor` with the shader sprite**

In `Free Return/GameScene.swift`, find the start of `didMove(to:)`:

```swift
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.03, blue: 0.12, alpha: 1)
        do {
            let level = try LevelLoader.load(id: "level-002")
```

Replace with:

```swift
    override func didMove(to view: SKView) {
        backgroundColor = .black
        addChild(StarfieldBackground.make(size: size))
        do {
            let level = try LevelLoader.load(id: "level-002")
```

Rationale: `backgroundColor = .black` is the fallback color shown for any pixel the sprite doesn't cover (e.g. during a brief layout change). The shader sprite covers the full scene at `zPosition = -100`, behind everything else, so the navy tint now comes from `u_zoneTint` inside the shader.

- [ ] **Step 2: Build the project**

Run from the project root:

```bash
xcodebuild -project "Free Return.xcodeproj" -scheme "Free Return" -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -40
```

Expected: `** BUILD SUCCEEDED **` at the end. If the build fails on `StarfieldBackground` not found, the file wasn't picked up by the sync'd group — confirm it lives directly under `Free Return/` (not nested deeper than the synchronized root expects).

- [ ] **Step 3: Commit**

```bash
git add "Free Return/GameScene.swift"
git commit -m "Use starfield shader as GameScene background"
```

---

## Task 4: Manual visual verification

**Files:** none (runtime check)

The spec calls for manual verification only — visual shaders don't yield to automated tests cheaply.

- [ ] **Step 1: Run on iOS Simulator**

Open the project in Xcode and run on an iPhone simulator (e.g. iPhone 15), or use:

```bash
xcodebuild -project "Free Return.xcodeproj" -scheme "Free Return" -destination 'platform=iOS Simulator,name=iPhone 15' build
```

Then launch the app via Xcode's run button (CLI run is not the focus here; the engineer should observe the running app).

- [ ] **Step 2: Verify the checklist**

While the app is running, confirm:

1. Stars are visible against the navy background.
2. Twinkling is noticeable but calm — no star fully blinks out, no strobing.
3. Stars look round (not horizontally squashed) — confirms aspect correction is working.
4. No visible grid/cell artifacts (straight lines, repeating patterns) anywhere on screen.
5. The HUD restart button (`↺`) and any level elements (planets, target zone, ship) are still visible *in front of* the starfield.
6. Restarting the level (tap `↺`) does not visually change the starfield and does not stutter.
7. Frame rate stays smooth (no visible lag). Optional: enable Xcode's "Show Frames Per Second" in Debug → View Debugging → Rendering, expect ~60fps.

If any check fails, do not mark this task complete — file the issue and stop here.

- [ ] **Step 3: Final commit (only if any whitespace/cleanup landed)**

If checks pass with no further changes, nothing to commit. Otherwise:

```bash
git add -A
git commit -m "Polish starfield after visual verification"
```

---

## Out of Scope (per spec)

- Per-level zone tint/seed wiring (uniforms exist; level data model integration is a future spec).
- Parallax/scrolling.
- Nebulae, planets, dust, lens flares.
- True `MTKView`/`CAMetalLayer` Metal pipeline.
