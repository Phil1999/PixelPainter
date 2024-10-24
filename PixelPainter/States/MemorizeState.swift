//
//  MemorizeState.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/22/24.
//

import GameplayKit
import SpriteKit

class MemorizeState: GKState {
    unowned let gameScene: GameScene
    var memorizeTimer: Timer?
    let memorizeTime: TimeInterval = 3
    
    init(gameScene: GameScene) {
        self.gameScene = gameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        setupMemorizeScene()
        startMemorizeTimer()
    }
    
    override func willExit(to nextState: GKState) {
        memorizeTimer?.invalidate()
        gameScene.removeAllChildren()
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is PlayState.Type
    }
    
    private func setupMemorizeScene() {
        let image = UIImage(named: "sample_image") // Replace with your image
        gameScene.context.gameInfo.currentImage = image
        
        let imageNode = SKSpriteNode(texture: SKTexture(image: image!))
        imageNode.size = gameScene.context.layoutInfo.gridSize
        imageNode.position = CGPoint(x: gameScene.size.width / 2, y: gameScene.size.height / 2)
        gameScene.addChild(imageNode)
        
        let timerLabel = SKLabelNode(text: "Time: \(Int(memorizeTime))")
        timerLabel.fontName = "AvenirNext-Bold"
        timerLabel.fontSize = 24
        timerLabel.position = CGPoint(x: gameScene.size.width / 2, y: gameScene.size.height - 100)
        timerLabel.name = "timerLabel"
        gameScene.addChild(timerLabel)
    }
    
    private func startMemorizeTimer() {
        var timeLeft = memorizeTime
        memorizeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            timeLeft -= 1
            if let timerLabel = self.gameScene.childNode(withName: "timerLabel") as? SKLabelNode {
                timerLabel.text = "Time: \(Int(timeLeft))"
            }
            if timeLeft <= 0 {
                timer.invalidate()
                self.gameScene.context.stateMachine?.enter(PlayState.self)
            }
        }
    }
}
