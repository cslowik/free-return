# Starfield Shader Background — Design

Date: 2026-04-30
Status: Approved

## Goal

Add a procedural shader-driven starfield as the GameScene background. Subtly twinkling, fixed (does not scroll). Scaffolded so future "zones" can vary tint and star layout via uniforms without shader changes.

## Approach

`SKShader` on a full-screen `SKSpriteNode` placed behind the level. SpriteKit compiles the fragment shader to Metal under the hood, so we get Metal performance without standing up a separate `MTKView`/`CAMetalLayer` render path.

Procedural generation (hash-based) — no texture asset, no memory cost, infinite variation by changing `u_zoneSeed`.

## Files

**New:**
- `Free Return/Shaders/Starfield.fsh` — fragment shader
- `Free Return/StarfieldBackground.swift` — factory that builds the configured `SKSpriteNode`

**Modified:**
- `Free Return/GameScene.swift` — `didMove(to:)` adds the background sprite at `zPosition = -100`. Replaces the existing `backgroundColor = SKColor(red: 0.03, green: 0.03, blue: 0.12, alpha: 1)` line.

## Shader

Single fragment pass, two layers of stars over a tinted background.

**Cell hash:**
Divide UV into a grid, hash each cell deterministically (`fract(sin(dot(...)) * large_const)`) to derive: presence threshold, sub-cell position, base brightness, twinkle phase offset.

**Two layers:**
- Sparse + bright (foreground)
- Dense + dim (deep background)

Different grid densities give a depth feel. Each layer loops over the 3×3 neighbor cells so stars near cell edges render without seams.

**Star shape:**
Soft circular falloff via `smoothstep(radius, 0.0, dist)` raised to a power for tight cores. No diffraction spikes — keeping it subtle.

**Twinkle:**
Per-star brightness modulated by

```
brightness *= twinkleAmount * sin(u_time * twinkleSpeed + phase) + (1.0 - twinkleAmount)
```

`twinkleAmount ≈ 0.35` so stars never fully blink out. Per-star `phase` desyncs the field. `twinkleSpeed` slow (~1.0–1.5 rad/s).

**Background:**
Dark navy base (`vec3(0.03, 0.03, 0.12)`) multiplied/biased by `u_zoneTint`. Optional very subtle vertical gradient for depth — keep flat if it adds visible banding.

## Uniforms

| Uniform | Type | Purpose | Default |
|---|---|---|---|
| `u_time` | float | SpriteKit-provided, drives twinkle | (auto) |
| `u_zoneTint` | vec3 | Background color tint | `(0.03, 0.03, 0.12)` |
| `u_zoneSeed` | float | Offsets hash so different zones get different star layouts | `0.0` |

Level data model wiring is out of scope for this spec — uniforms exist so future zone work is a one-line plug-in, but for now they take their defaults.

## `StarfieldBackground.swift`

Single static factory:

```swift
enum StarfieldBackground {
    static func make(size: CGSize,
                     zoneTint: SIMD3<Float> = .init(0.03, 0.03, 0.12),
                     zoneSeed: Float = 0.0) -> SKSpriteNode
}
```

Behavior:
1. Create transparent `SKSpriteNode` of the given size, `anchorPoint = (0, 0)`, `position = (0, 0)`, `zPosition = -100`.
2. Load `Starfield.fsh` via `SKShader(fileNamed:)`.
3. Attach uniforms `u_zoneTint` (`SKUniform(name:vectorFloat3:)`) and `u_zoneSeed` (`SKUniform(name:float:)`).
4. Return the sprite. Caller adds it.

## GameScene integration

In `didMove(to:)`, before `LevelLoader.load`:

```swift
let bg = StarfieldBackground.make(size: size)
addChild(bg)
```

Remove the `backgroundColor = SKColor(red: 0.03, …)` line — the shader covers it. Keep the scene's default `backgroundColor` (or set black) so any uncovered pixel during rotation/resize doesn't flash navy.

## Testing

Manual only — visual shader, no automated coverage:

1. App launches, level-002 scene shows stars over navy.
2. Stars visibly twinkle but no star fully blinks out and motion is calm (not seizure-y).
3. No visible grid/cell artifacts at iPhone aspect ratios.
4. Frame rate unaffected on device (target 60fps; the shader is cheap — two small loops).
5. Restart preserves background; no memory growth on repeated `resetLevel()`.

## Out of scope

- Zone data model / per-level tint and seed (future spec; uniforms are the seam)
- Parallax / scrolling background
- Nebulae, dust, planets, or other non-star celestial bodies
- Diffraction spikes / lens flares
- True `MTKView` Metal pipeline
