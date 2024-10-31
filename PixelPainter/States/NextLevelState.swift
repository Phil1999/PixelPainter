//
//  NextLevelState.swift
//  PixelPainter
//
//  Created by Jason Huang on 10/25/24.
//

import GameplayKit
import SpriteKit

class NextLevelState: GKState {
    unowned let gameScene: GameScene
    var nextLevelTimer: Timer?
    let nextLevelTime: TimeInterval = 3
    
    init(gameScene: GameScene) {
        self.gameScene = gameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        setupNextLvlScene()
        startNextLvlTimer()
        moveToNextImage()
    }
    
    override func willExit(to nextState: GKState) {
        nextLevelTimer?.invalidate()
        gameScene.removeAllChildren()
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is MemorizeState.Type
    }
    
    private func setupNextLvlScene() {
        let timerLabel = SKLabelNode(text: "Time: \(Int(nextLevelTime))")
        timerLabel.fontName = "PPNeueMontreal-Bold"
        timerLabel.fontSize = 24
        timerLabel.position = CGPoint(x: gameScene.size.width / 2, y: gameScene.size.height - 100)
        timerLabel.name = "timerLabel"
        gameScene.addChild(timerLabel)
        
        let nextLevelLabel = SKLabelNode(text: "NEXT LEVEL")
        nextLevelLabel.fontName = "PPNeueMontreal-Bold"
        nextLevelLabel.fontSize = 24
        nextLevelLabel.position = CGPoint(x: gameScene.size.width / 2, y: gameScene.size.height / 2)
        nextLevelLabel.name = "nextLevelLabel"
        gameScene.addChild(nextLevelLabel)
        
        let levelLabel = SKLabelNode(text: "Level: \(gameScene.context.gameInfo.level)")
        levelLabel.fontName = "PPNeueMontreal-Bold"
        levelLabel.fontSize = 24
        levelLabel.position = CGPoint(x: gameScene.size.width / 2, y: gameScene.size.height / 2 - 50)
        levelLabel.name = "levelLabel"
        gameScene.addChild(levelLabel)
    }
    
    private func startNextLvlTimer() {
        var timeLeft = nextLevelTime
        nextLevelTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            timeLeft -= 1
            if let timerLabel = self.gameScene.childNode(withName: "timerLabel") as? SKLabelNode {
                timerLabel.text = "Time: \(Int(timeLeft))"
            }
            if timeLeft <= 0 {
                timer.invalidate()
                print("Changing to memorize state")
                self.gameScene.context.stateMachine?.enter(MemorizeState.self)
            }
        }
    }
    
    private func moveToNextImage() {
        gameScene.queueManager.moveToNextImage()
        gameScene.queueManager.printCurrentQueue()
        print("Moving to next image for level \(gameScene.context.gameInfo.level)")
    }
}
