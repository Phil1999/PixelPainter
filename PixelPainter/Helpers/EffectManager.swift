//
//  EffectManager.swift
//  PixelPainter
//
//  Created by Philip Lee on 10/25/24.
//

import Foundation
import SpriteKit



class EffectManager {
    weak var gameScene: GameScene?
    private var isFlashing = false
    
    init(gameScene: GameScene) {
        self.gameScene = gameScene
    }
    
    func flashScreen(color: UIColor, alpha: CGFloat) {
        
        guard let gameScene = gameScene, !isFlashing else { return } // Prevent overlapping flashes
        
        isFlashing = true
        
        // add overlay
        let overlay = SKSpriteNode(color: color, size: gameScene.size)
        overlay.position = CGPoint(x: gameScene.size.width / 2, y: gameScene.size.height / 2)
        overlay.zPosition = 9999 // arbitrary value here just want to make it above everything
        overlay.alpha = 0 // Start transparent
        gameScene.addChild(overlay)
        
        // Flash the screen
        let fadeIn = SKAction.fadeAlpha(to: alpha, duration: 0.1)
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.1)
        let remove = SKAction.removeFromParent()
        let flashSequence = SKAction.sequence([fadeIn, fadeOut, fadeIn, fadeOut,
            SKAction.run { [weak self] in
                self?.isFlashing = false // reset flashing status
            },
            remove
        ])
        overlay.run(flashSequence)
    }
    
    func shakeNode(_ node: SKNode, duration: TimeInterval = 0.05, distance: CGFloat = 10) {
        let shakeLeft = SKAction.moveBy(x: -distance, y: 0, duration: duration)
        let shakeRight = SKAction.moveBy(x: distance * 2, y: 0, duration: duration)
        let shakeSequence = SKAction.sequence([shakeLeft, shakeRight, shakeLeft])
        node.run(shakeSequence)
    }
    
    func disableInteraction(for duration: TimeInterval = 1.0) {
        let disableTouchAction = SKAction.run { [weak self] in
                self?.gameScene?.isUserInteractionEnabled = false
        }
        let waitAction = SKAction.wait(forDuration: duration)
        let enableTouchAction = SKAction.run { [weak self] in
            self?.gameScene?.isUserInteractionEnabled = true
            
        }
        
        let sequence = SKAction.sequence([disableTouchAction, waitAction, enableTouchAction])
        gameScene?.run(sequence)
    }
    
}
