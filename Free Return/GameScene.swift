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

        guard gameState == .aiming, let spacecraft = spacecraft else { return }
        if pos.distance(to: spacecraft.position) < 44 {
            isDragging = true
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let touch = touches.first, let spacecraft = spacecraft else { return }
        let velocity = launchVector(from: spacecraft.position, draggedTo: touch.location(in: self))
        let previewState = SimState(position: spacecraft.position, velocity: velocity)
        trajectoryPreview.update(from: previewState, bodies: gravityBodies)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let touch = touches.first, let spacecraft = spacecraft else { return }
        isDragging = false
        trajectoryPreview.hide()
        let velocity = launchVector(from: spacecraft.position, draggedTo: touch.location(in: self))
        spacecraft.launch(velocity: velocity)
        gameState = .flying
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
        trajectoryPreview?.hide()
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
