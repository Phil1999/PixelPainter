//
//  TutorialState.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/22/24.
//

import GameplayKit
import SpriteKit

class TutorialState: GKState {
    unowned let gameScene: GameScene
    
    init(gameScene: GameScene) {
        self.gameScene = gameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        setupTutorialScene()
    }
    
    override func willExit(to nextState: GKState) {
        gameScene.removeAllChildren()
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is MemorizeState.Type
    }
    
    private func setupTutorialScene() {
        gameScene.removeAllChildren()
        
        let padding: CGFloat = 20
        let safeWidth = gameScene.size.width - (padding * 2)
        let safeHeight = gameScene.size.height - (padding * 2)
        
        let background = SKSpriteNode(color: .systemTeal, size: gameScene.size)
        background.position = CGPoint(x: gameScene.size.width / 2, y: gameScene.size.height / 2)
        gameScene.addChild(background)
        
        let contentNode = SKNode()
        gameScene.addChild(contentNode)
        
        let titleLabel = SKLabelNode(text: "How to Play")
        titleLabel.fontName = "PPNeueMontreal-Bold"
        titleLabel.fontSize = 40
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: safeWidth / 2, y: safeHeight * 0.9)
        contentNode.addChild(titleLabel)
        
        let instructions = [
            "1. Memorize the image shown",
            "2. Recreate the image using pixels",
            "3. Complete the puzzle before time runs out",
            "4. Earn points for accuracy and speed"
        ]
        
        let instructionsNode = SKNode()
        contentNode.addChild(instructionsNode)
        
        for (index, instruction) in instructions.enumerated() {
            let label = SKLabelNode(text: instruction)
            label.fontName = "PPNeueMontreal-Regular"
            label.fontSize = 24
            label.fontColor = .white
            label.position = CGPoint(x: 0, y: -CGFloat(index * 40))
            instructionsNode.addChild(label)
        }
        
        instructionsNode.position = CGPoint(x: safeWidth / 2, y: safeHeight * 0.6)
        
        let startButton = createButton(text: "Start Game", size: CGSize(width: safeWidth * 0.5, height: 50))
        startButton.position = CGPoint(x: safeWidth / 2, y: safeHeight * 0.2)
        startButton.name = "startButton"
        contentNode.addChild(startButton)
        
        // Adjust content node position to respect safe area
        contentNode.position = CGPoint(x: padding, y: padding)
    }
    
    private func createButton(text: String, size: CGSize) -> SKNode {
        let button = SKSpriteNode(color: .systemBlue, size: size)
        
        let label = SKLabelNode(text: text)
        label.fontName = "PPNeueMontreal-Bold"
        label.fontSize = 20
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        button.addChild(label)
        
        return button
    }
}
