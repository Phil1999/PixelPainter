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
       let timerRadius: CGFloat = 35
       circularTimer = CircularTimer(
           radius: timerRadius,
           gameScene: gameScene
       )
       circularTimer?.position = CGPoint(x: 50, y: 0)
       circularTimer?.name = "circularTimer"
       hudNode.addChild(circularTimer!)

       // Create score container
       let scoreBoxWidth: CGFloat = 100
       let scoreBoxHeight: CGFloat = 40
       let scoreBox = SKShapeNode(rectOf: CGSize(width: scoreBoxWidth, height: scoreBoxHeight), cornerRadius: scoreBoxHeight/2)
       scoreBox.fillColor = UIColor(hex: "F5E3E3")
       scoreBox.lineWidth = 0
       scoreBox.position = CGPoint(x: gameScene.size.width/2, y: -60)
       hudNode.addChild(scoreBox)

       // Update score label position and style
       let scoreLabel = SKLabelNode(text: "\(gameScene.context.gameInfo.score)")
       scoreLabel.fontName = "PPNeueMontreal-Bold"
       scoreLabel.fontSize = 24
       scoreLabel.fontColor = .black
       scoreLabel.verticalAlignmentMode = .center
       scoreLabel.horizontalAlignmentMode = .center
       scoreLabel.position = CGPoint(x: 0, y: 0)
       scoreLabel.name = "scoreLabel"
       scoreBox.addChild(scoreLabel)
    }
  
    func updateScore() {
        guard let gameScene = gameScene else { return }

        if let scoreLabel = gameScene.childNode(withName: "//scoreLabel")
            as? SKLabelNode
        {
            scoreLabel.text = "\(gameScene.context.gameInfo.score)"
        }
    }
}
