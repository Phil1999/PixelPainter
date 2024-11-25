//
//  HUDManager.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/23/24.
//

import SpriteKit

class HUDManager {
    weak var gameScene: GameScene?
    private var circularTimer: CircularTimer?
    private var scoreCounter: ScoreCounter?
    
    init(gameScene: GameScene) {
        self.gameScene = gameScene
    }
    
    func createHUD() {
        guard let gameScene = gameScene else { return }
        
        let hudNode = SKNode()
        hudNode.position = CGPoint(x: 0, y: gameScene.size.height - 100)
        gameScene.addChild(hudNode)
        
        // timer
        let timerRadius: CGFloat = 35
        let timer = CircularTimer(
            radius: timerRadius,
            gameScene: gameScene
        )
        timer.position = CGPoint(x: 50, y: 0)
        timer.name = "circularTimer"
        hudNode.addChild(timer)
        self.circularTimer = timer
        
        // score counter
        let scoreCounter = ScoreCounter(text: "\(gameScene.context.gameInfo.score)")
        scoreCounter.position = CGPoint(x: gameScene.size.width / 2, y: -60)
        scoreCounter.name = "scoreCounter"
        hudNode.addChild(scoreCounter)
        self.scoreCounter = scoreCounter
        
    }
    
    func updateScore() {
        guard let gameScene = gameScene,
        let scoreCounter = self.scoreCounter else { return }
        
        let newScoreText = "\(gameScene.context.gameInfo.score)"
        scoreCounter.updateText(newScoreText)
       
        
    }
}
