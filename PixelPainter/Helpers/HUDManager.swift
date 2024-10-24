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
        timerLabel.fontName = "AvenirNext-Bold"
        timerLabel.fontSize = 24
        timerLabel.horizontalAlignmentMode = .left
        timerLabel.position = CGPoint(x: 20, y: 0)
        timerLabel.name = "timerLabel"
        hudNode.addChild(timerLabel)
        
        let scoreLabel = SKLabelNode(text: "Score: \(gameScene.context.gameInfo.score)")
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 24
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: gameScene.size.width - 20, y: 0)
        scoreLabel.name = "scoreLabel"
        hudNode.addChild(scoreLabel)
    }
    
    func updateTimer() {
        guard let gameScene = gameScene else { return }
        
        gameScene.context.gameInfo.timeRemaining -= 1
        if let timerLabel = gameScene.childNode(withName: "//timerLabel") as? SKLabelNode {
            timerLabel.text = "Time: \(Int(gameScene.context.gameInfo.timeRemaining))"
        }
        
        if gameScene.context.gameInfo.timeRemaining <= 0 {
            gameScene.context.stateMachine?.enter(GameOverState.self)
        }
    }
    
    func updateScore() {
        guard let gameScene = gameScene else { return }
        
        if let scoreLabel = gameScene.childNode(withName: "//scoreLabel") as? SKLabelNode {
            scoreLabel.text = "Score: \(gameScene.context.gameInfo.score)"
        }
    }
}
