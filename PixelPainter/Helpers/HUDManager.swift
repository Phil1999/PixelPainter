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

    init(gameScene: GameScene) {
        self.gameScene = gameScene
    }

    func createHUD() {
        guard let gameScene = gameScene else { return }

        let hudNode = SKNode()
        hudNode.position = CGPoint(x: 0, y: gameScene.size.height - 100)
        gameScene.addChild(hudNode)

        // timer
        let timerRadius: CGFloat = 30
        circularTimer = CircularTimer(
            radius: timerRadius,
            gameScene: gameScene
        )
        circularTimer?.position = CGPoint(x: 50, y: 0)
        circularTimer?.name = "circularTimer"
        hudNode.addChild(circularTimer!)

        let scoreLabel = SKLabelNode(
            text: "Score: \(gameScene.context.gameInfo.score)")
        scoreLabel.fontName = "PPNeueMontreal-Bold"
        scoreLabel.fontSize = 24
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: gameScene.size.width - 20, y: 0)
        scoreLabel.name = "scoreLabel"
        hudNode.addChild(scoreLabel)
    }

    func updateScore() {
        guard let gameScene = gameScene else { return }

        if let scoreLabel = gameScene.childNode(withName: "//scoreLabel")
            as? SKLabelNode
        {
            scoreLabel.text = "Score: \(gameScene.context.gameInfo.score)"
        }
    }
}
