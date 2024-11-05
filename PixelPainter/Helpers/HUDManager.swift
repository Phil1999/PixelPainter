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
    
    private var isWarningActive = false //5 second warning checker
    
    func updateTimer() {
        guard let gameScene = gameScene else { return }
        
        gameScene.context.gameInfo.timeRemaining -= 1
        let timeRemaining = gameScene.context.gameInfo.timeRemaining
        
        // Update regular timer label
        if let timerLabel = gameScene.childNode(withName: "//timerLabel") as? SKLabelNode {
            timerLabel.text = "Time: \(Int(timeRemaining))"
            
            if timeRemaining > 0 && timeRemaining <= 5 {
                triggerFiveSecondWarning(time: Int(timeRemaining))
            } else if isWarningActive && timeRemaining > 5 {
                // Reset the warning if time goes above 5 seconds
                resetTimerLabelAppearance(timerLabel)
            }
        }
        
        
        // Game over check
        if timeRemaining <= 0 {
            gameScene.context.stateMachine?.enter(GameOverState.self)
        }
    }

    private func triggerFiveSecondWarning(time: Int) {
        guard let gameScene = gameScene else { return }
        
        if let timerLabel = gameScene.childNode(withName: "//timerLabel") as? SKLabelNode {
            isWarningActive = true
            
            timerLabel.fontColor = .red
            
            let minDuration: Double = 0.05
            let maxDuration: Double = 0.6
            // Using sinusoidal easing to make the animation smoother. Dividing by 5 to normalize values
            let scaleDuration = minDuration + (maxDuration - minDuration) * sin(Double(time) / 5.0 * .pi / 2)
            
            let scaleUp = SKAction.scale(to: 1.25, duration: scaleDuration / 2)
            let scaleDown = SKAction.scale(to: 1.0, duration: scaleDuration / 2)
            let pulsate = SKAction.sequence([scaleUp, scaleDown])
            
            
            timerLabel.run(pulsate)
        }
        
    }
    
    private func resetTimerLabelAppearance(_ timerLabel: SKLabelNode) {
        timerLabel.fontColor = .white
        timerLabel.removeAction(forKey: "pulsate") // Stop the pulsate animation
        isWarningActive = false
    }
    
    func updateScore() {
        guard let gameScene = gameScene else { return }
        
        if let scoreLabel = gameScene.childNode(withName: "//scoreLabel") as? SKLabelNode {
            scoreLabel.text = "Score: \(gameScene.context.gameInfo.score)"
        }
    }
}
