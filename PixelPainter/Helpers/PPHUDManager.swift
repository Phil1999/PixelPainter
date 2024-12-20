//
//  HUDManager.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/23/24.
//

import SpriteKit

class PPHUDManager {
    weak var gameScene: PPGameScene?
    private var circularTimer: PPCircularTimer?
    private var scoreCounter: PPScoreCounter?

    init(gameScene: PPGameScene) {
        self.gameScene = gameScene
    }

    func createHUD() {
        guard let gameScene = gameScene else { return }

        let hudNode = SKNode()
        hudNode.position = CGPoint(x: 0, y: gameScene.size.height - 100)
        gameScene.addChild(hudNode)

        let timerRadius: CGFloat = 55
        let timer = PPCircularTimer(
            radius: timerRadius,
            gameScene: gameScene
        )
        timer.position = CGPoint(x: gameScene.size.width / 2, y: -65)
        timer.name = "circularTimer"
        hudNode.addChild(timer)
        self.circularTimer = timer

        // Position score counter relative to timer
        let scoreCounter = PPScoreCounter(
            text: "\(gameScene.context.gameInfo.score)")

        let xOffset: CGFloat = 130
        let yOffset: CGFloat = 60
        scoreCounter.position = CGPoint(
            x: timer.position.x - xOffset,
            y: timer.position.y + yOffset
        )
        scoreCounter.name = "scoreCounter"
        hudNode.addChild(scoreCounter)
        self.scoreCounter = scoreCounter
    }

    func updateScore(withAnimation: Bool = false) {
        guard let gameScene = gameScene,
            let scoreCounter = self.scoreCounter
        else { return }

        scoreCounter.updateScore(
            gameScene.context.gameInfo.score, withAnimation: withAnimation)

        let newScoreText = "\(gameScene.context.gameInfo.score)"
        scoreCounter.updateText(newScoreText)
    }
}
