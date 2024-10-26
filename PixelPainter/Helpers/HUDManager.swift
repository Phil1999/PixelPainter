//
//  HUDManager.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/23/24.
//

import SpriteKit

class HUDManager {
    weak var gameScene: GameScene?
    
    init(gameScene: GameScene) {
        self.gameScene = gameScene
    }
    
    func createHUD() {
        guard let gameScene = gameScene else { return }
        
        let hudNode = SKNode()
        hudNode.position = CGPoint(x: 0, y: gameScene.size.height - 100)
        gameScene.addChild(hudNode)
        
        let timerLabel = SKLabelNode(text: "Time: \(Int(gameScene.context.gameInfo.timeRemaining))")
        timerLabel.fontName = "PPNeueMontreal-Bold"
        timerLabel.fontSize = 24
        timerLabel.horizontalAlignmentMode = .left
        timerLabel.position = CGPoint(x: 20, y: 0)
        timerLabel.name = "timerLabel"
        hudNode.addChild(timerLabel)
        
        let scoreLabel = SKLabelNode(text: "Score: \(gameScene.context.gameInfo.score)")
        scoreLabel.fontName = "PPNeueMontreal-Bold"
        scoreLabel.fontSize = 24
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: gameScene.size.width - 20, y: 0)
        scoreLabel.name = "scoreLabel"
        hudNode.addChild(scoreLabel)
    }
    
    func updateTimer() {
        guard let gameScene = gameScene else { return }
        
        gameScene.context.gameInfo.timeRemaining -= 1
        let timeRemaining = gameScene.context.gameInfo.timeRemaining
        
        // Update regular timer label
        if let timerLabel = gameScene.childNode(withName: "//timerLabel") as? SKLabelNode {
            timerLabel.text = "Time: \(Int(timeRemaining))"
            
            if timeRemaining > 0 && timeRemaining <= 5 {
                showBigCountdown(time: Int(timeRemaining))
            }
        }
        
        // Time warning flash before game over
        if timeRemaining > 0 && timeRemaining <= 5 {
            if let playState = gameScene.context.stateMachine?.currentState as? PlayState {
                playState.effectManager.flashScreen(color: .red, alpha: 0.3)
            }
        }
        
        // Game over check
        if timeRemaining <= 0 {
            gameScene.context.stateMachine?.enter(GameOverState.self)
        }
    }

    private func showBigCountdown(time: Int) {
        guard let gameScene = gameScene else { return }
        
        let countdownLabel = SKLabelNode(text: "\(time)")
        countdownLabel.fontName = "PPNeueMontreal-Bold"
        countdownLabel.fontSize = 100
        countdownLabel.fontColor = .red
        
        let gridTopY = (gameScene.size.height / 2 + 50) + (gameScene.context.layoutInfo.gridSize.height / 2)
        countdownLabel.position = CGPoint(
            x: gameScene.size.width / 2,
            y: gridTopY + 50
        )

        countdownLabel.zPosition = 9999
        gameScene.addChild(countdownLabel)
        
        // Animation sequence
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        
        let sequence = SKAction.sequence([
            scaleUp,
            scaleDown,
            fadeOut,
            remove
        ])
        
        countdownLabel.run(sequence)
    }
    
    func updateScore() {
        guard let gameScene = gameScene else { return }
        
        if let scoreLabel = gameScene.childNode(withName: "//scoreLabel") as? SKLabelNode {
            scoreLabel.text = "Score: \(gameScene.context.gameInfo.score)"
        }
    }
}
