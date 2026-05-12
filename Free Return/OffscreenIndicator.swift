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
        dot.fillColor = SKColor(red: 0.65, green: 0.45, blue: 1.0, alpha: 1)
        dot.strokeColor = .clear
        super.init()
        isHidden = true
        addChild(dot)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    func update(shipPosition: CGPoint, visibleRect: CGRect, screenCornerRadius: CGFloat, lostBuffer: CGFloat) {
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

        let edgePoint = clampToRoundedRect(
            point: shipPosition,
            rect: visibleRect,
            cornerRadius: screenCornerRadius
        )

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

    private func clampToRoundedRect(point: CGPoint, rect: CGRect, cornerRadius: CGFloat) -> CGPoint {
        var x = min(max(point.x, rect.minX + edgeInset), rect.maxX - edgeInset)
        var y = min(max(point.y, rect.minY + edgeInset), rect.maxY - edgeInset)

        guard cornerRadius > edgeInset else { return CGPoint(x: x, y: y) }

        let centers: [CGPoint] = [
            CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
            CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
            CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
            CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
        ]
        let inZone: [Bool] = [
            x < centers[0].x && y < centers[0].y,
            x > centers[1].x && y < centers[1].y,
            x < centers[2].x && y > centers[2].y,
            x > centers[3].x && y > centers[3].y,
        ]
        if let idx = inZone.firstIndex(of: true) {
            let c = centers[idx]
            let dx = x - c.x, dy = y - c.y
            let d = sqrt(dx * dx + dy * dy)
            let limit = cornerRadius - edgeInset
            if d > limit && d > 0 {
                x = c.x + dx * limit / d
                y = c.y + dy * limit / d
            }
        }
        return CGPoint(x: x, y: y)
    }
}
