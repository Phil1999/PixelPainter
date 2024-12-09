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
        
        // timer - now positioned where score counter was
        let timerRadius: CGFloat = 40
        let timer = CircularTimer(
            radius: timerRadius,
            gameScene: gameScene
        )
        timer.position = CGPoint(x: gameScene.size.width / 2, y: -30)
        timer.name = "circularTimer"
        hudNode.addChild(timer)
        self.circularTimer = timer
        
        // score counter - now positioned where timer was
        let scoreCounter = ScoreCounter(text: "\(gameScene.context.gameInfo.score)")
        scoreCounter.position = CGPoint(x: 65, y: 0)
        scoreCounter.name = "scoreCounter"
        hudNode.addChild(scoreCounter)
        self.scoreCounter = scoreCounter
    }
    
    func updateScore(withAnimation: Bool = false) {
        guard let gameScene = gameScene,
        let scoreCounter = self.scoreCounter else { return }
        
        scoreCounter.updateScore(gameScene.context.gameInfo.score, withAnimation: withAnimation)
        
        let newScoreText = "\(gameScene.context.gameInfo.score)"
        scoreCounter.updateText(newScoreText)
    }
}
