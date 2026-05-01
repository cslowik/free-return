//
//  OffscreenIndicator.swift
//  Free Return
//

import SpriteKit

class OffscreenIndicator: SKNode {

    private let dot: SKShapeNode
    private let baseRadius: CGFloat = 5
    private let edgeInset: CGFloat = 32
    private let appearDelay: TimeInterval = 0.25
    private let fadeInDuration: TimeInterval = 0.2

    private var offscreenSince: TimeInterval?

    override init() {
        dot = SKShapeNode(circleOfRadius: baseRadius)
        dot.fillColor = .white
        dot.strokeColor = .clear
        super.init()
        isHidden = true
        addChild(dot)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    func update(shipPosition: CGPoint, visibleRect: CGRect, lostBuffer: CGFloat) {
        let minX = visibleRect.minX, maxX = visibleRect.maxX
        let minY = visibleRect.minY, maxY = visibleRect.maxY

        let onScreen = shipPosition.x >= minX && shipPosition.x <= maxX &&
                       shipPosition.y >= minY && shipPosition.y <= maxY
        if onScreen {
            offscreenSince = nil
            isHidden = true
            return
        }

        let now = CACurrentMediaTime()
        if offscreenSince == nil {
            offscreenSince = now
        }
        let elapsed = now - (offscreenSince ?? now)
        if elapsed < appearDelay {
            isHidden = true
            return
        }

        let clampedX = min(max(shipPosition.x, minX + edgeInset), maxX - edgeInset)
        let clampedY = min(max(shipPosition.y, minY + edgeInset), maxY - edgeInset)
        let edgePoint = CGPoint(x: clampedX, y: clampedY)

        let dx = shipPosition.x - edgePoint.x
        let dy = shipPosition.y - edgePoint.y
        let distancePastEdge = sqrt(dx * dx + dy * dy)

        let t = max(0, min(1, 1 - distancePastEdge / lostBuffer))
        if t <= 0 {
            isHidden = true
            return
        }

        let fadeIn = CGFloat(min(1.0, (elapsed - appearDelay) / fadeInDuration))

        position = edgePoint
        dot.setScale(t)
        alpha = (0.4 + 0.6 * t) * fadeIn
        isHidden = false
    }

    func hide() {
        offscreenSince = nil
        isHidden = true
    }
}
