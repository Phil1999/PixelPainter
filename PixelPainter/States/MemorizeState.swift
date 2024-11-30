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
    private let memorizeTime: TimeInterval = 3
    private var isFirstLevel: Bool = false

    init(gameScene: GameScene) {
        self.gameScene = gameScene
        super.init()
    }

    override func didEnter(from previousState: GKState?) {
        isFirstLevel = gameScene.context.gameInfo.level == 1  // Check if it's the first level

        // Update the grid and image if not the first level
        if !isFirstLevel {
            moveToNextImage()
            updateGridSize()
            updateGameTime()
        }

        setupMemorizeScene()

    }

    private func moveToNextImage() {
        gameScene.queueManager.moveToNextImage()
        gameScene.queueManager.printCurrentQueue()
        print(
            "Moving to next image for level \(gameScene.context.gameInfo.level), Grid Size: \(gameScene.context.layoutInfo.gridDimension)×\(gameScene.context.layoutInfo.gridDimension)"
        )
    }

    private func updateGridSize() {
        let level = gameScene.context.gameInfo.level

        // Define grid progression logic
        let newGridDimension: Int
        switch level {
        case 1...2:
            newGridDimension = 3
        case 3...5:
            newGridDimension = 4
        case 6...8:
            newGridDimension = 5
        default:
            newGridDimension = 6  // Maximum size
        }

        // If grid size changed, reload images
        if newGridDimension != gameScene.context.layoutInfo.gridDimension {
            gameScene.queueManager.refreshImageQueue(
                forGridSize: newGridDimension)
        }

        // Update the grid dimension
        gameScene.context.updateGridDimension(newGridDimension)
    }
    
    private func updateGameTime() {
        let level = gameScene.context.gameInfo.level

        // Define grid progression logic
        let newGameTime: TimeInterval
        switch level {
        case 1...2:
            newGameTime = 10 // 3x3 grid
        case 3...5:
            newGameTime = 15 // 4x4 grid
        case 6...8:
            newGameTime = 20 // 5x5 grid
        default:
            newGameTime = 25 // 6x6 grid
        }

        // If grid size changed, reload images
        if newGameTime != gameScene.context.gameInfo.timeRemaining {
            gameScene.context.gameInfo.timeRemaining = newGameTime
        }
    }

    override func willExit(to nextState: GKState) {
        gameScene.removeAllChildren()
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is PlayState.Type
    }

    private func setupMemorizeScene() {
        let background = Background()
        background.setup(screenSize: gameScene.size)
        background.zPosition = -2
        gameScene.addChild(background)

        guard let image = gameScene.queueManager.getCurrentImage() else {
            return
        }
        gameScene.context.gameInfo.currentImage = image

        let imageNode = SKSpriteNode(texture: SKTexture(image: image))
        imageNode.size = gameScene.context.layoutInfo.gridSize
        imageNode.position = CGPoint(
            x: gameScene.size.width / 2, y: gameScene.size.height / 2)
        gameScene.addChild(imageNode)

        let levelLabel =
            isFirstLevel
            ? SKLabelNode(text: "Level 1")
            : SKLabelNode(
                text: "Level \(Int(gameScene.context.gameInfo.level))")

        levelLabel.fontName = "PPNeueMontreal-Bold"
        levelLabel.fontSize = 36
        levelLabel.fontColor = .white
        levelLabel.position = CGPoint(
            x: gameScene.size.width / 2, y: gameScene.size.height - 100)
        levelLabel.name = "levelLabel"
        gameScene.addChild(levelLabel)

        if !isFirstLevel {
            let scoreCounter = ScoreCounter(
                text: "\(gameScene.context.gameInfo.score)")
            scoreCounter.position = CGPoint(
                x: gameScene.size.width / 2, y: gameScene.size.height / 2 - 240)
            gameScene.addChild(scoreCounter)

            grantPowerUp()
        }

        let readyLabel = SKLabelNode(text: "Memorize")
        readyLabel.fontName = "PPNeueMontreal-Bold"
        readyLabel.fontSize = 48
        readyLabel.fontColor = .white
        readyLabel.position = CGPoint(
            x: gameScene.size.width / 2, y: gameScene.size.height - 200)
        readyLabel.name = "readyLabel"
        gameScene.addChild(readyLabel)

        // Start the blinking animation
        blinkCountdownLabel(readyLabel: readyLabel, blinkCount: Int(memorizeTime))

    }

    private func transitionToPlayState() {
        gameScene.queueManager.printCurrentQueue()
        gameScene.context.stateMachine?.enter(PlayState.self)
    }

    private func grantPowerUp() {
        if let powerUpManager =
            (gameScene.context.stateMachine?.state(forClass: PlayState.self)
            as? PlayState)?.powerUpManager,
            let grantedPowerUp = powerUpManager.grantRandomPowerup()
        {

            let containerNode = SKNode()
            containerNode.position = CGPoint(
                x: gameScene.size.width / 2,
                y: gameScene.size.height / 2 - 325
            )
            containerNode.alpha = 0
            gameScene.addChild(containerNode)

            // Create the icon node
            let iconNode = SKSpriteNode(imageNamed: grantedPowerUp.iconName)
            iconNode.size = CGSize(width: 40, height: 40)
            iconNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            iconNode.position = CGPoint.zero

            // Create the label node
            let plusOneLabel = SKLabelNode(text: "+1")
            plusOneLabel.fontName = "PPNeueMontreal-Bold"
            plusOneLabel.fontSize = 30
            plusOneLabel.verticalAlignmentMode = .center

            // Create the circle node
            let padding: CGFloat = 10
            let dynamicRadius =
                max(iconNode.size.width, iconNode.size.height) / 2 + padding

            let circleNode = SKShapeNode(circleOfRadius: dynamicRadius)
            circleNode.strokeColor = .white
            circleNode.lineWidth = 0 // changed to 0 to match current theme
            circleNode.fillColor = UIColor(hex: "252525").withAlphaComponent(
                0.9)

            // Position the icon inside the circle
            circleNode.addChild(iconNode)
            iconNode.position = CGPoint.zero  // Center the icon inside the circle

            let spacing: CGFloat = 15
            let totalWidth =
                circleNode.frame.width + plusOneLabel.frame.width + spacing

            // Position the label and circle node
            plusOneLabel.position = CGPoint(
                x: -totalWidth / 2 + plusOneLabel.frame.width / 2, y: 0)
            circleNode.position = CGPoint(
                x: totalWidth / 2 - circleNode.frame.width / 2, y: 0)

            containerNode.addChild(plusOneLabel)
            containerNode.addChild(circleNode)

            // Animate the reward appearance
            let fadeIn = SKAction.fadeIn(withDuration: 0.2)
            let wait = SKAction.wait(forDuration: 0.9)
            containerNode.run(SKAction.sequence([wait, fadeIn]))
        }
    }

    private func blinkCountdownLabel(readyLabel: SKLabelNode, blinkCount: Int) {
        let countdownSequence = ["3", "2", "1", "Ready?"]
        var currentIndex = 0
        
        let blinkIn = SKAction.fadeIn(withDuration: 0.8)
        let blinkOut = SKAction.fadeOut(withDuration: 0.2)
        let blinkSequence = SKAction.sequence([blinkOut, blinkIn])

        let countdownAction = SKAction.run { [weak self] in
            guard let self = self else { return }

            readyLabel.text = countdownSequence[currentIndex]
            
            if currentIndex == countdownSequence.count - 1 {
                // When "Ready?" appears, just show it without blinking
                readyLabel.alpha = 1.0
                
                // Trigger the image break animation after a short delay
                readyLabel.run(SKAction.sequence([
                    SKAction.wait(forDuration: 1.0),
                    SKAction.run { [weak self] in
                        guard let self = self,
                              let imageNode = self.gameScene.children.first(where: {
                                  $0 is SKSpriteNode && $0 != self.gameScene.background
                              }) as? SKSpriteNode
                        else { return }
                        
                        self.animateImageBreak(imageNode: imageNode)
                    }
                ]))
            } else {
                readyLabel.run(blinkSequence)
            }
            currentIndex += 1
        }
        readyLabel.run(
            SKAction.repeat(
                SKAction.sequence([blinkSequence, countdownAction]),
                count: countdownSequence.count))
    }
    
    private func animateImageBreak(imageNode: SKSpriteNode) {
        let gridDimension = gameScene.context.layoutInfo.gridDimension
        let pieceSize = CGSize(
            width: imageNode.size.width / CGFloat(gridDimension),
            height: imageNode.size.height / CGFloat(gridDimension)
        )
        
        let piecesContainer = SKNode()
        piecesContainer.position = imageNode.position
        gameScene.addChild(piecesContainer)
        
        var allPieces: [SKSpriteNode] = []
        
        for row in 0..<gridDimension {
            for col in 0..<gridDimension {
                let textureRect = CGRect(
                    x: CGFloat(col) / CGFloat(gridDimension),
                    y: 1.0 - (CGFloat(row + 1) / CGFloat(gridDimension)),
                    width: 1.0 / CGFloat(gridDimension),
                    height: 1.0 / CGFloat(gridDimension)
                )
                
                let pieceNode = SKSpriteNode(
                    texture: SKTexture(rect: textureRect, in: imageNode.texture!),
                    size: pieceSize
                )
                
                pieceNode.position = CGPoint(
                    x: CGFloat(col) * pieceSize.width - imageNode.size.width / 2 + pieceSize.width / 2,
                    y: CGFloat((gridDimension - 1) - row) * pieceSize.height - imageNode.size.height / 2 + pieceSize.height / 2
                )
                
                piecesContainer.addChild(pieceNode)
                allPieces.append(pieceNode)
            }
        }
        
        imageNode.removeFromParent()
        
        
        EffectManager.shared.ejectPieces(pieces: allPieces) { [weak self] in
                piecesContainer.removeFromParent()
                self?.transitionToPlayState()
        }
    }

}
