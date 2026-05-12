# Menu Screen Design

## Overview

Add a main menu as the app's entry point, plus the supporting screens and in-game UI needed to return to it. Today `GameViewController` jumps straight into `GameScene`; this change makes `MenuScene` the entry point and gives the player a way back from any level.

The menu has five buttons: **New Game**, **Level Select**, **How to Play**, **Settings**, **Credits**. Level Select is its own SpriteKit scene reached via a custom warp transition; How to Play, Settings, and Credits are modal overlays drawn on top of the menu. Two in-game additions (a pause button and a results overlay) complete the navigation loop.

Implementation is pure SpriteKit, consistent with the rest of the game. The starfield background is reused everywhere for visual continuity.

## Architecture

**New scenes:**
- `MenuScene` — title + 5 menu buttons over the starfield
- `LevelSelectScene` — vertical list of levels from `LevelLoader.loadAll()`

**Modified scene:**
- `GameScene` — accepts a `levelId`, gains a pause button and a results overlay

**Modal overlays** (all subclass `ModalOverlay`, added as children of the active scene):
- `HowToPlayOverlay` — three-line instructional copy
- `SettingsOverlay` — "Coming soon" stub
- `CreditsOverlay` — title, author, year
- `PauseOverlay` — Resume / Restart / Menu
- `ResultsOverlay` — outcome-aware title (uses `GameOutcome`); Retry / Next / Menu

**Shared building blocks:**
- `MenuButton` — `SKNode` with a rounded background + label and an `onTap` closure
- `ModalOverlay` — base class handling the dim layer, card, close button, present/dismiss animations
- `WarpTransition` — helper performing a custom scale-up-and-fade-out → scale-down-and-fade-in swap between two scenes

**Entry point change:** `GameViewController.viewDidLoad` presents `MenuScene` instead of `GameScene`.

## Components

### `MenuScene`
- Background: `StarfieldBackground` (existing factory).
- Title: `SKLabelNode`, "Free Return", ~120pt bold system font, positioned around 75% screen height. Slow vertical drift via `SKAction.sequence` repeated forever (~0.5pt over 3s) to keep the screen alive.
- Button stack: 5 `MenuButton` nodes, centered horizontally, evenly spaced in the lower half of the screen, in this order:
  1. New Game → presents `GameScene` with `levelId: "level-001"` via `SKTransition.fade`.
  2. Level Select → presents `LevelSelectScene` via `WarpTransition.forward`.
  3. How to Play → presents `HowToPlayOverlay` as a child.
  4. Settings → presents `SettingsOverlay` as a child.
  5. Credits → presents `CreditsOverlay` as a child.
- Hit testing: `touchesBegan` calls `nodes(at:)` and walks up the parent chain until it finds a `MenuButton`, then invokes its `onTap`.

### `LevelSelectScene`
- Background: `StarfieldBackground`.
- Header: "Select Level" label near the top.
- Back button: top-left, returns to `MenuScene` via `WarpTransition.backward`.
- Body: fixed vertical stack of rows (one per level from `LevelLoader.loadAll()`). Each row shows the level number (zero-padded index, e.g. "01") and the level name (`Level.name` if available, else the level id). The whole row is the tap target.
- Tap a row → presents `GameScene` with that `levelId` via `SKTransition.fade`.
- No scrolling, locking, or progress markers in v1 (see Out of Scope).

### `GameScene` (modifications)
- Add an initializer parameter `levelId: String`. Update `GameViewController` and all entry points to pass it.
- Add a pause button as a child node, pinned to the top-right corner with a safe-area inset. Tapping it:
  - Freezes the physics simulation (mechanism: gate the existing `SimState` update in the scene's `update(_:)` on an `isPausedByUI` flag).
  - Presents `PauseOverlay`.
- On level outcome (existing `GameOutcome` flow): present `ResultsOverlay`, configured with the outcome and the current `levelId`.

### `MenuButton`
- `SKNode` subclass.
- Children: `SKShapeNode` rounded-rect background + centered `SKLabelNode`.
- Properties: `title: String`, `onTap: () -> Void`, configurable size (default sized for the menu).
- Visual: filled background with subtle stroke.
- API: `playPressFeedback()` runs a brief scale-down→scale-up `SKAction` for tactile feedback; `trigger()` runs the press feedback and then invokes `onTap` (with a small delay so the animation is visible before any scene transition).
- Hit testing is performed by the parent scene/overlay (a single `touchesBegan` entry point per scene). On a hit, the parent calls `button.trigger()`.

### `ModalOverlay` (base class)
- `SKNode` subclass.
- Children:
  - Dim layer: full-canvas black `SKShapeNode` at ~70% alpha, `zPosition` above scene content. Catches taps to prevent passthrough.
  - Card: rounded `SKShapeNode`, ~80% screen width, height fits content, centered.
  - Close button: "✕" `MenuButton` in the top-right of the card.
- `present(on scene: SKScene)`: adds self as a child, animates dim layer fade-in (0.2s) and card scale 0.9→1.0 + fade-in.
- `dismiss()`: reverses the animation, then `removeFromParent()`.
- Dismiss triggers: close button tap, or tap on the dim layer outside the card.

### Per-overlay content
- `HowToPlayOverlay`: card with three text rows:
  1. "Drag back from your ship to aim."
  2. "Release to launch. Gravity does the rest."
  3. "Reach the target zone to win."
- `SettingsOverlay`: card with title "Settings" and body "Coming soon."
- `CreditsOverlay`: card with three lines: "Free Return", "Made by Chris Slowik", "© 2026".
- `PauseOverlay`: card with title "Paused" and three `MenuButton`s: Resume (dismisses overlay + unpauses), Restart (reloads current `levelId`), Menu (returns to `MenuScene` via `WarpTransition.backward`).
- `ResultsOverlay`: card title derived from `GameOutcome` (titles already exist on the enum). Three `MenuButton`s: Retry (reload current `levelId`), Next (load next id from manifest), Menu (return to `MenuScene`). Next is **hidden** when the outcome is a failure OR when the current level is the last in the manifest.

### `WarpTransition`
- Not an `SKTransition` subclass (those are limited); a helper that animates the outgoing and incoming scenes manually.
- `WarpTransition.forward(from: SKView, to next: SKScene)`:
  1. Animate current scene's root content scale 1.0→1.4 + alpha 1.0→0.0 over 0.4s.
  2. On completion, present `next` with the incoming scene starting at scale 0.7 + alpha 0, animating to 1.0/1.0 over 0.4s.
- `WarpTransition.backward(from:to:)`: same idea, reversed (outgoing scales down + fades, incoming scales down to up).
- Total perceived duration ~0.6–0.8s.

## Data flow

1. App launch → `GameViewController` presents `MenuScene`.
2. User taps "New Game" → `MenuScene` presents `GameScene(levelId: "level-001")` with fade transition.
3. User taps "Level Select" → `MenuScene` presents `LevelSelectScene` via forward warp.
4. User taps a level row → `LevelSelectScene` presents `GameScene(levelId: tappedId)` with fade.
5. In game, user taps pause button → `PauseOverlay` appears; physics frozen until Resume/Restart/Menu.
6. Level ends (existing outcome flow) → `ResultsOverlay` appears configured with `outcome` and `levelId`.
7. User taps Menu (from pause or results) → `WarpTransition.backward` to `MenuScene`.

`GameScene` needs to know its `levelId` so Retry and Restart can reload, and so Next can compute the following id by looking up the current position in `LevelLoader.loadAll()`.

## Error handling

- `LevelSelectScene` calls `LevelLoader.loadAll()`. If it returns empty (no levels), the body shows a single "No levels available" label and only the back button is interactive.
- "Next Level" computes the next id by index lookup in the manifest. If the current id is the last one (or somehow not in the manifest), the Next button is hidden, not shown disabled.
- Tapping a button during a transition (warp or fade) should not double-fire. Buttons disable their `onTap` while a transition is in flight (a simple `isTransitioning` flag on the scene gates touches).
- The pause button is disabled while a results overlay is active to prevent double-modal states.

## Testing

The existing project has a production smoke test (per recent commits). Add:

- **Smoke test:** Build the app and verify `MenuScene` is the initial scene presented by `GameViewController`. Tap the five menu buttons in sequence (programmatic touch dispatch) and verify the right scene/overlay appears each time.
- **Level Select test:** Verify the level row count matches `LevelLoader.loadAll().count`, and that tapping a row hands the right `levelId` to `GameScene`.
- **Results overlay test:** For each `GameOutcome` case, instantiate `ResultsOverlay` and assert the title matches the outcome's expected title and that Next is shown only for non-failure outcomes that aren't on the last level.
- **Transition double-tap test:** During a warp transition, additional taps on the originating button should be ignored.

Manual QA pass on device: visual check of warp transition, overlay animations, pause flow during active physics simulation, safe-area positioning of pause button on a notched device.

## Out of scope

Explicit non-goals for this work:

- Save / progress system (no "Continue", no level locking, no star ratings).
- Sound and haptics (no audio system exists yet).
- Real settings toggles — Settings is a "Coming soon" stub.
- Localization — all strings are hardcoded English.
- Custom fonts or logo art — title is a `SKLabelNode` with the system font; logo can replace it later.
- Animated or illustrated How to Play diagram — text only in v1.
- Accessibility (VoiceOver labels, Dynamic Type) — worth its own pass later.
- Scrolling in Level Select — fixed vertical stack is fine for 2 levels; revisit when count grows.
