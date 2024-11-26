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
    private let memorizeTime: TimeInterval = GameConstants.DevSandBox.sceneTransitionTime
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
        let level = gameScene.context.gameInfo.level + 1  // Use next level's number

        // Define grid progression logic
        let newGridDimension: Int
        switch level {
        case 1...2:
            newGridDimension = 3
        case 3...4:
            newGridDimension = 4
        case 5...6:
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

        let readyLabel = SKLabelNode(text: "Ready?")
        readyLabel.fontName = "PPNeueMontreal-Bold"
        readyLabel.fontSize = 40
        readyLabel.fontColor = .white
        readyLabel.position = CGPoint(
            x: gameScene.size.width / 2, y: gameScene.size.height - 200)
        readyLabel.name = "readyLabel"
        gameScene.addChild(readyLabel)

        // Start the blinking animation
        blinkReadyLabel(readyLabel: readyLabel, blinkCount: Int(memorizeTime))

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
            circleNode.lineWidth = 4
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
            let fadeIn = SKAction.fadeIn(withDuration: 0.5)
            let wait = SKAction.wait(forDuration: 0.9)
            containerNode.run(SKAction.sequence([wait, fadeIn]))
        }
    }

    private func blinkReadyLabel(readyLabel: SKLabelNode, blinkCount: Int) {
        var remainingBlinks = blinkCount
        
        let blinkIn = SKAction.fadeIn(withDuration: 0.5)
        let blinkOut = SKAction.fadeOut(withDuration: 0.5)
        let blinkSequence = SKAction.sequence([blinkOut, blinkIn])

        let blinkAction = SKAction.run { [weak self] in
            guard let self = self else { return }

            remainingBlinks -= 1

            if remainingBlinks == 0 {
                // On the last blink, transition to "Tap!"
                readyLabel.text = "Tap!"

                readyLabel.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: 1.0),
                        SKAction.run {
                            self.transitionToPlayState()
                        },
                    ]))
            } else {
                readyLabel.run(blinkSequence)
            }
        }
        readyLabel.run(
            SKAction.repeat(
                SKAction.sequence([blinkSequence, blinkAction]),
                count: blinkCount))
    }

}
