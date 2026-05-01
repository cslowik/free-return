//
//  GameScene.swift
//  Free Return
//

import SpriteKit

private enum GameState {
    case aiming
    case flying
    case settled(GameOutcome)
}

class GameScene: SKScene {

    // World — wired up by LevelBuilder
    private var spacecraft: SpacecraftNode!
    private var trajectoryPreview: TrajectoryPreview!
    private var targetZone: TargetZoneNode!
    private var gravityBodies: [GravityBody] = []
    private var shipStart: CGPoint = .zero
    private var offscreenIndicator: OffscreenIndicator!

    // State
    private var gameState: GameState = .aiming
    private var messageNode: SKNode?

    // Drag input
    private var isDragging = false
    private let maxDragDistance: CGFloat = 220
    private let launchSpeedScale: CGFloat = 3
    private let dragCurveExponent: CGFloat = 1.6

    // Touch sample buffer — used to ignore the finger jerk at release
    private struct TouchSample {
        let point: CGPoint
        let time: TimeInterval
    }
    private var touchSamples: [TouchSample] = []
    private let touchBufferDuration: TimeInterval = 0.12
    private let stableSpeedThreshold: CGFloat = 200

    // Bounds — how far off-screen before we declare the craft lost
    private let offScreenBuffer: CGFloat = 800

    // HUD
    private let restartButtonName = "restartButton"

    override func didMove(to view: SKView) {
        backgroundColor = .black
        addChild(StarfieldBackground.make(size: size))
        do {
            let level = try LevelLoader.load(id: "level-002")
            let built = LevelBuilder.build(level, into: self)
            spacecraft = built.spacecraft
            trajectoryPreview = built.trajectoryPreview
            targetZone = built.targetZone
            gravityBodies = built.gravityBodies
            shipStart = built.shipStart
            offscreenIndicator = OffscreenIndicator()
            offscreenIndicator.zPosition = 80
            addChild(offscreenIndicator)
            setupHUD(in: view)
        } catch {
            showFatalError(error)
        }
    }

    private func setupHUD(in view: SKView) {
        // Convert the view's top safe-area inset into scene units so the button
        // never lands under the notch/Dynamic Island under .aspectFill scaling.
        let viewHeight = max(view.bounds.height, 1)
        let sceneUnitsPerViewPoint = size.height / viewHeight
        let topInset = view.safeAreaInsets.top * sceneUnitsPerViewPoint
        let leftInset = view.safeAreaInsets.left * sceneUnitsPerViewPoint

        let restart = SKLabelNode(text: "↺")
        restart.fontName = "Avenir-Heavy"
        restart.fontSize = 32
        restart.fontColor = SKColor(white: 1, alpha: 0.55)
        restart.position = CGPoint(x: 35 + leftInset,
                                   y: size.height - 50 - topInset)
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

        if case .settled = gameState {
            resetLevel()
            return
        }

        guard case .aiming = gameState, let spacecraft = spacecraft else { return }
        if pos.distance(to: spacecraft.position) < 44 {
            isDragging = true
            touchSamples.removeAll(keepingCapacity: true)
            recordTouchSample(pos, time: touch.timestamp)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let touch = touches.first, let spacecraft = spacecraft else { return }
        let pos = touch.location(in: self)
        recordTouchSample(pos, time: touch.timestamp)
        let velocity = launchVector(from: spacecraft.position, draggedTo: pos)
        let previewState = SimState(position: spacecraft.position, velocity: velocity)
        trajectoryPreview.update(from: previewState, bodies: gravityBodies)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let touch = touches.first, let spacecraft = spacecraft else { return }
        isDragging = false
        trajectoryPreview.hide()
        let releasePoint = stableReleasePoint(fallback: touch.location(in: self))
        touchSamples.removeAll(keepingCapacity: true)
        let velocity = launchVector(from: spacecraft.position, draggedTo: releasePoint)
        spacecraft.launch(velocity: velocity)
        gameState = .flying
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
        touchSamples.removeAll(keepingCapacity: true)
        trajectoryPreview?.hide()
    }

    private func recordTouchSample(_ point: CGPoint, time: TimeInterval) {
        touchSamples.append(TouchSample(point: point, time: time))
        let cutoff = time - touchBufferDuration
        while let first = touchSamples.first, first.time < cutoff {
            touchSamples.removeFirst()
        }
    }

    // Most recent sample whose arrival speed was below the held-still threshold.
    private func stableReleasePoint(fallback: CGPoint) -> CGPoint {
        guard touchSamples.count >= 2 else { return fallback }
        for i in stride(from: touchSamples.count - 1, through: 1, by: -1) {
            let curr = touchSamples[i]
            let prev = touchSamples[i - 1]
            let dt = curr.time - prev.time
            guard dt > 0 else { continue }
            let speed = CGFloat(curr.point.distance(to: prev.point) / dt)
            if speed < stableSpeedThreshold {
                return curr.point
            }
        }
        return touchSamples.first?.point ?? fallback
    }

    private func isRestartTap(at pos: CGPoint) -> Bool {
        nodes(at: pos).contains { $0.name == restartButtonName }
    }

    // MARK: - Launch math

    private func launchVector(from origin: CGPoint, draggedTo dragPoint: CGPoint) -> CGVector {
        let raw = CGVector(dx: dragPoint.x - origin.x, dy: dragPoint.y - origin.y)
        let clamped = raw.clamped(to: maxDragDistance)
        let length = sqrt(clamped.dx * clamped.dx + clamped.dy * clamped.dy)
        guard length > 0.01 else { return .zero }
        let normalized = length / maxDragDistance
        let curved = pow(normalized, dragCurveExponent)
        let magnitude = curved * maxDragDistance * launchSpeedScale
        let scale = -magnitude / length
        return CGVector(dx: clamped.dx * scale, dy: clamped.dy * scale)
    }

    // MARK: - Update / Collisions

    override func update(_ currentTime: TimeInterval) {
        spacecraft?.advance(bodies: gravityBodies, dt: 1.0 / 60.0)
        if case .flying = gameState {
            checkCollisions()
            offscreenIndicator.update(
                shipPosition: spacecraft.simState.position,
                visibleRect: visibleRectInScene(),
                lostBuffer: offScreenBuffer
            )
        }
    }

    private func visibleRectInScene() -> CGRect {
        guard let view = view else {
            return CGRect(origin: .zero, size: size)
        }
        let bottomLeft = convertPoint(fromView: CGPoint(x: 0, y: view.bounds.height))
        let topRight = convertPoint(fromView: CGPoint(x: view.bounds.width, y: 0))
        return CGRect(
            x: bottomLeft.x,
            y: bottomLeft.y,
            width: topRight.x - bottomLeft.x,
            height: topRight.y - bottomLeft.y
        )
    }

    private func checkCollisions() {
        guard let spacecraft = spacecraft else { return }
        let pos = spacecraft.simState.position

        if targetZone.contains(pos) {
            settle(with: .targetReached)
            return
        }

        for body in gravityBodies {
            if pos.distance(to: body.position) <= body.radius {
                settle(with: .crashed)
                return
            }
        }

        if pos.x < -offScreenBuffer || pos.x > size.width + offScreenBuffer ||
           pos.y < -offScreenBuffer || pos.y > size.height + offScreenBuffer {
            settle(with: .lostInSpace)
        }
    }

    // MARK: - Outcomes

    private func settle(with outcome: GameOutcome) {
        gameState = .settled(outcome)
        let color: SKColor = outcome.isSuccess ? .systemGreen : .systemRed
        let burstCount = outcome.isSuccess ? 3 : 1
        playBurst(at: spacecraft.position, color: color, count: burstCount)
        spacecraft.isHidden = true
        offscreenIndicator.hide()
        showMessage(outcome.title, color: color)
    }

    private func resetLevel() {
        clearMessage()
        spacecraft.reset(at: shipStart)
        trajectoryPreview.hide()
        offscreenIndicator.hide()
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
        if title.frame.width > 0 {
            title.setScale((size.width * 0.5) / title.frame.width)
        }
        group.addChild(title)

        let hint = SKLabelNode(text: "Tap to retry")
        hint.fontName = "Avenir"
        hint.fontSize = 16
        hint.fontColor = SKColor(white: 1, alpha: 0.65)
        hint.position = CGPoint(x: size.width / 2, y: title.position.y - title.frame.height / 2 - 20)
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
