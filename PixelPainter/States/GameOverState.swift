//
//  GameOverState.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/22/24.
//

import GameplayKit
import SpriteKit

class GameOverState: GKState {
    unowned let gameScene: GameScene
    
    init(gameScene: GameScene) {
        self.gameScene = gameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        SoundManager.shared.stopBackgroundMusic()
        setupGameOverScene()
    }
    
    override func willExit(to nextState: GKState) {
        gameScene.removeAllChildren()
        // May not need this later on (only used for restarting game)
        SoundManager.shared.playBackgroundMusic("game-bg", fileType: "mp3")
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is MemorizeState.Type
    }
    
    private func setupGameOverScene() {
        gameScene.removeAllChildren()
        
        let background = SKSpriteNode(color: .black, size: gameScene.size)
        background.position = CGPoint(x: gameScene.size.width / 2, y: gameScene.size.height / 2)
        background.zPosition = -1
        gameScene.addChild(background)
        
        let gameOverLabel = SKLabelNode(text: "Game Over")
        gameOverLabel.fontName = "PPNeueMontreal-Bold"
        gameOverLabel.fontSize = 48
        gameOverLabel.fontColor = .white
        gameOverLabel.position = CGPoint(x: gameScene.size.width / 2, y: gameScene.size.height * 0.7)
        gameScene.addChild(gameOverLabel)
        
        let scoreLabel = SKLabelNode(text: "Final Score: \(gameScene.gameInfo.score)")
        scoreLabel.fontName = "PPNeueMontreal-Medium"
        scoreLabel.fontSize = 32
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: gameScene.size.width / 2, y: gameScene.size.height * 0.6)
        gameScene.addChild(scoreLabel)
        
        let playAgainButton = createButton(text: "Play Again", position: CGPoint(x: gameScene.size.width / 2, y: gameScene.size.height * 0.4))
        playAgainButton.name = "playAgainButton"
        gameScene.addChild(playAgainButton)
        
        let mainMenuButton = createButton(text: "Main Menu", position: CGPoint(x: gameScene.size.width / 2, y: gameScene.size.height * 0.3))
        mainMenuButton.name = "mainMenuButton"
        gameScene.addChild(mainMenuButton)
    }
    
    private func createButton(text: String, position: CGPoint) -> SKNode {
        let button = SKSpriteNode(color: .systemBlue, size: CGSize(width: 200, height: 50))
        button.position = position
        
        let label = SKLabelNode(text: text)
        label.fontName = "PPNeueMontreal-Bold"
        label.fontSize = 20
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        button.addChild(label)
        
        return button
    }
    
    func handleTouches(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: gameScene)
        let touchedNodes = gameScene.nodes(at: location)
        
        for node in touchedNodes {
            if node.name == "playAgainButton" {
                gameScene.context.resetGame()
            } else if node.name == "mainMenuButton" {
                // If you have a main menu state, enter it here
                // For now, we'll just restart the game
                gameScene.context.resetGame()
            }
        }
    }
}
