//
//  EffectManager.swift
//  PixelPainter
//
//  Created by Philip Lee on 10/25/24.
//

import Foundation
import SpriteKit

class EffectManager {
    static let shared = EffectManager()
    private weak var gameScene: GameScene?
    private var isFlashing = false

    init() {}

    func setGameScene(_ scene: GameScene) {
        self.gameScene = scene
    }

    func flashScreen(color: UIColor, alpha: CGFloat) {

        guard let gameScene = gameScene, !isFlashing else { return }  // Prevent overlapping flashes

        isFlashing = true

        // add overlay
        let overlay = SKSpriteNode(color: color, size: gameScene.size)
        overlay.position = CGPoint(
            x: gameScene.size.width / 2, y: gameScene.size.height / 2)
        overlay.zPosition = 9999  // arbitrary value here just want to make it above everything
        overlay.alpha = 0  // Start transparent
        gameScene.addChild(overlay)

        // Flash the screen
        let fadeIn = SKAction.fadeAlpha(to: alpha, duration: 0.1)
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.1)
        let remove = SKAction.removeFromParent()
        let flashSequence = SKAction.sequence([
            fadeIn, fadeOut, fadeIn, fadeOut,
            SKAction.run { [weak self] in
                self?.isFlashing = false  // reset flashing status
            },
            remove,
        ])
        overlay.run(flashSequence)
    }

    func shakeNode(
        _ node: SKNode, duration: TimeInterval = 0.05, distance: CGFloat = 10
    ) {
        let shakeLeft = SKAction.moveBy(x: -distance, y: 0, duration: duration)
        let shakeRight = SKAction.moveBy(
            x: distance * 2, y: 0, duration: duration)
        let shakeSequence = SKAction.sequence([
            shakeLeft, shakeRight, shakeLeft,
        ])
        node.run(shakeSequence)
    }
    
    func applyPulseEffect(to node: SKNode, scaleUp: CGFloat = 1.2, scaleDown: CGFloat = 1.0, duration: TimeInterval = 0.5) {
        
        node.removeAction(forKey: "pulseEffect")
        
        let scaleUpAction = SKAction.scale(to: scaleUp, duration: duration / 2)
        let scaleDownAction = SKAction.scale(to: scaleDown, duration: duration / 2)
        let pulseSequence = SKAction.sequence([scaleUpAction, scaleDownAction])
                
        let repeatPulse = SKAction.repeatForever(pulseSequence)
                
        node.run(repeatPulse, withKey: "pulseEffect")
    }

    func temporarilyDisableInteraction(for duration: TimeInterval = 1.0) {
        let disableTouchAction = SKAction.run { [weak self] in
            self?.gameScene?.isUserInteractionEnabled = false
        }
        let waitAction = SKAction.wait(forDuration: duration)
        let enableTouchAction = SKAction.run { [weak self] in
            self?.gameScene?.isUserInteractionEnabled = true

        }

        let sequence = SKAction.sequence([
            disableTouchAction, waitAction, enableTouchAction,
        ])
        gameScene?.run(sequence)
    }

    private(set) var isPlayingGameOver = false
    
    func playGameOverEffect(completion: @escaping () -> Void) {
        guard let gameScene = gameScene,
            let gridNode = gameScene.childNode(withName: "grid")
                as? SKSpriteNode
        else { return }
        
        isPlayingGameOver = true // Set flag when starting animation
        
        // Play the game end sound effect
        SoundManager.shared.playSound(.gameOverWithPieces)

        // Step 1: Shake effect (left-right only)
        let shakeSequence = createShakeSequence()

        // Step 2: Prepare pieces for ejection
        let pieces = gridNode.children.filter {
            $0.name?.starts(with: "piece_") ?? false
        }

        // Step 3: Combine animations
        gridNode.run(shakeSequence) { [weak self] in
            self?.ejectPieces(pieces: pieces) {
                self?.isPlayingGameOver = false // Reset flag when animation is complete
                completion()
            }
        }
    }

    func ejectPieces(pieces: [SKNode], completion: @escaping () -> Void) {
        let group = DispatchGroup()

        for piece in pieces {
            group.enter()

            // Random horizontal offset for both jump and fall
            let jumpOffsetX = CGFloat.random(in: -100...100)
            let fallOffsetX = CGFloat.random(in: -200...200)

            // Random jump height
            let jumpHeight = CGFloat.random(in: 100...200)

            // Random slight delay for each piece
            let initialDelay = SKAction.wait(
                forDuration: Double.random(in: 0...0.2))

            // Jump up with random x offset
            let jumpUpAction = SKAction.moveBy(
                x: jumpOffsetX, y: jumpHeight, duration: 0.3)
            jumpUpAction.timingMode = .easeOut

            // Fall down with different random x offset
            let fallDownAction = SKAction.moveBy(
                x: fallOffsetX, y: -800, duration: 1.0)
            fallDownAction.timingMode = .easeIn

            let fadeOutAction = SKAction.fadeOut(withDuration: 0.5)

            // Combine the actions with initial random delay
            let jumpAndFallSequence = SKAction.sequence([
                initialDelay,
                jumpUpAction,
                SKAction.group([fallDownAction, fadeOutAction]),
            ])

            piece.run(jumpAndFallSequence) {
                piece.removeFromParent()
                group.leave()
            }
        }

        // Wait for all pieces to complete their animations
        DispatchQueue.global().async {
            group.wait()
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    private func createShakeSequence() -> SKAction {
        let shakeRight = SKAction.moveBy(x: 15, y: 0, duration: 0.05)
        let shakeLeft = SKAction.moveBy(x: -15, y: 0, duration: 0.05)

        let doubleShake = SKAction.sequence([
            shakeLeft, shakeRight, shakeRight, shakeLeft,
        ])

        return SKAction.sequence([
            SKAction.repeat(doubleShake, count: 4),
            SKAction.moveBy(x: 0, y: 0, duration: 0.1),  // Reset position
        ])
    }

}


// MARK: - Cooldown Effects
extension EffectManager {
    
    private struct NodeState {
        let alpha: CGFloat
        let color: UIColor?  // For colored nodes
        let fillColor: UIColor?  // For shape nodes
        let strokeColor: UIColor?  // For shape nodes
        let colorBlendFactor: CGFloat  // For sprite nodes
    }
    
    // Note that the duration should match with the actual expected duration.
    func cooldown(_ node: SKNode, duration: TimeInterval) {
        // Save original states recursively
        let originalStates = storeNodeStates(node)

        // Apply cooldown effect to all nodes
        greyOutNode(node)

        // Create cooldown overlay
        let cooldownNode = SKShapeNode(circleOfRadius: 33)  // Standard size for power-ups
        cooldownNode.strokeColor = UIColor.white.withAlphaComponent(0.3)
        cooldownNode.lineWidth = 3
        cooldownNode.name = "cooldown"

        let startAngle = CGFloat.pi / 2
        let path = CGMutablePath()
        path.addArc(
            center: .zero,
            radius: 33,
            startAngle: startAngle,
            endAngle: startAngle + CGFloat.pi * 2,
            clockwise: true
        )
        cooldownNode.path = path
        node.addChild(cooldownNode)

        // Animate cooldown
        let animate = SKAction.customAction(withDuration: duration) {
            node, elapsedTime in
            guard let cooldown = node as? SKShapeNode else { return }
            let progress = elapsedTime / CGFloat(duration)
            let endAngle = startAngle + (.pi * 2 * progress)

            let newPath = CGMutablePath()
            newPath.addArc(
                center: .zero,
                radius: 33,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: true
            )
            cooldown.path = newPath
        }

        // Reset everything back to original state
        let reset = SKAction.run { [weak self] in
            cooldownNode.removeFromParent()
            self?.restoreNodeStates(node, states: originalStates)
        }

        cooldownNode.run(SKAction.sequence([animate, reset]))
    }


    private func storeNodeStates(_ node: SKNode) -> [SKNode: NodeState] {
        var states: [SKNode: NodeState] = [:]

        // Store state for current node
        states[node] = NodeState(
            alpha: node.alpha,
            color: (node as? SKSpriteNode)?.color,
            fillColor: (node as? SKShapeNode)?.fillColor,
            strokeColor: (node as? SKShapeNode)?.strokeColor,
            colorBlendFactor: (node as? SKSpriteNode)?.colorBlendFactor ?? 0
        )

        // Recursively store states for all children
        node.children.forEach { child in
            states.merge(storeNodeStates(child)) { current, _ in current }
        }

        return states
    }

    private func greyOutNode(_ node: SKNode) {
        // Set alpha for all nodes
        node.alpha = 0.5

        // Handle specific node types
        if let shapeNode = node as? SKShapeNode {
            shapeNode.fillColor = .gray
            shapeNode.strokeColor = .darkGray
        }

        if let spriteNode = node as? SKSpriteNode {
            spriteNode.color = .gray
            spriteNode.colorBlendFactor = 0.8
        }

        // Recursively grey out children
        node.children.forEach { greyOutNode($0) }
    }

    private func restoreNodeStates(_ node: SKNode, states: [SKNode: NodeState])
    {
        if let state = states[node] {
            // Restore alpha
            node.alpha = state.alpha

            // Restore specific node properties
            if let shapeNode = node as? SKShapeNode {
                shapeNode.fillColor = state.fillColor ?? .clear
                shapeNode.strokeColor = state.strokeColor ?? .clear
            }

            if let spriteNode = node as? SKSpriteNode {
                spriteNode.color = state.color ?? .white
                spriteNode.colorBlendFactor = state.colorBlendFactor
            }
        }

        // Recursively restore children
        node.children.forEach { restoreNodeStates($0, states: states) }
    }
}
