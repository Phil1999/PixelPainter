//
//  NextLevelState.swift
//  PixelPainter
//

import GameplayKit
import SpriteKit

class NextLevelState: GKState {
    unowned let gameScene: GameScene
    private var nextLevelTimer: Timer?
    private let nextLevelTime: TimeInterval = 3

    init(gameScene: GameScene) {
        self.gameScene = gameScene
        super.init()
    }

    override func didEnter(from previousState: GKState?) {
        setupNextLevelScene()
        startNextLevelTimer()
        moveToNextImage()
        updateGridSize()
        grantPowerUp()
    }

    override func willExit(to nextState: GKState) {
        nextLevelTimer?.invalidate()
        gameScene.removeAllChildren()
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is MemorizeState.Type
    }

    private func setupNextLevelScene() {
        // Setup background
        let background = Background()
        background.setup(screenSize: gameScene.size)
        background.zPosition = -2
        gameScene.addChild(background)

        // We show the previous image that the user cleared
        if let image = gameScene.queueManager.getCurrentImage() {
            gameScene.context.gameInfo.currentImage = image
            let imageNode = SKSpriteNode(texture: SKTexture(image: image))
            imageNode.size = gameScene.context.layoutInfo.gridSize
            imageNode.position = CGPoint(
                x: gameScene.size.width / 2, y: gameScene.size.height / 2)
            imageNode.zPosition = 1
            gameScene.addChild(imageNode)
        }

        // Level complete container - moved up
        let completeContainer = SKNode()
        completeContainer.position = CGPoint(
            x: gameScene.size.width / 2, y: gameScene.size.height - 100)  // Moved up from -150
        completeContainer.zPosition = 2
        gameScene.addChild(completeContainer)

        // Level Complete Text
        let levelCompleteLabel = SKLabelNode(text: "LEVEL COMPLETED!")
        levelCompleteLabel.fontName = "PPNeueMontreal-Bold"
        levelCompleteLabel.fontSize = 32
        levelCompleteLabel.fontColor = .yellow
        levelCompleteLabel.alpha = 0
        completeContainer.addChild(levelCompleteLabel)

        // Animate level complete text
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.3)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.3)
        let completeSequence = SKAction.sequence([fadeIn, scaleUp, scaleDown])
        levelCompleteLabel.run(completeSequence)


        let scoreCounter = ScoreCounter(
            text: "\(gameScene.context.gameInfo.score)")
        scoreCounter.position = CGPoint(
            x: gameScene.size.width / 2, y: gameScene.size.height - 210)
        gameScene.addChild(scoreCounter)

        // Timer label at bottom
        let timerLabel = SKLabelNode(
            text: "Next Level in: \(Int(nextLevelTime))")
        timerLabel.fontName = "PPNeueMontreal-Bold"
        timerLabel.fontSize = 24
        timerLabel.position = CGPoint(x: gameScene.size.width / 2, y: 100)
        timerLabel.name = "timerLabel"
        gameScene.addChild(timerLabel)
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

        // Add grid size information to the next level screen
        let gridSizeLabel = SKLabelNode(
            text: "Grid Size: \(newGridDimension)×\(newGridDimension)")
        gridSizeLabel.fontName = "PPNeueMontreal-Bold"
        gridSizeLabel.fontSize = 20
        gridSizeLabel.position = CGPoint(
            x: gameScene.size.width / 2,
            y: gameScene.size.height / 2 - 150
        )
        gridSizeLabel.name = "gridSizeLabel"
        gameScene.addChild(gridSizeLabel)

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
                y: gameScene.size.height / 2 - 240
            )
            containerNode.alpha = 0
            gameScene.addChild(containerNode)

            // Create the icon node
            let iconNode = SKSpriteNode(imageNamed: grantedPowerUp.iconName)
            iconNode.size = CGSize(width: 40, height: 40)

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

    private func startNextLevelTimer() {
        var timeLeft = nextLevelTime
        nextLevelTimer = Timer.scheduledTimer(
            withTimeInterval: 1, repeats: true
        ) { [weak self] timer in
            guard let self = self else { return }
            timeLeft -= 1
            if let timerLabel = self.gameScene.childNode(withName: "timerLabel")
                as? SKLabelNode
            {
                timerLabel.text = "Next Level in: \(Int(timeLeft))"
            }
            if timeLeft <= 0 {
                timer.invalidate()
                self.gameScene.context.stateMachine?.enter(MemorizeState.self)
            }
        }
    }

    private func moveToNextImage() {
        gameScene.queueManager.moveToNextImage()
        gameScene.queueManager.printCurrentQueue()
        print(
            "Moving to next image for level \(gameScene.context.gameInfo.level), Grid Size: \(gameScene.context.layoutInfo.gridDimension)×\(gameScene.context.layoutInfo.gridDimension)"
        )
    }

    private func grantPowerUp() {
        if let powerUpManager =
            (gameScene.context.stateMachine?.state(forClass: PlayState.self)
            as? PlayState)?.powerUpManager
        {
            if let grantedPowerUp = powerUpManager.grantRandomPowerup() {
                let powerUpName = grantedPowerUp.displayName
                let powerUpMessage = "Granted the '\(powerUpName)' Power-Up!"
                let powerUpLabel = SKLabelNode(text: powerUpMessage)

                powerUpLabel.fontName = "PPNeueMontreal-Bold"
                powerUpLabel.fontSize = 20
                powerUpLabel.position = CGPoint(
                    x: gameScene.size.width / 2,
                    y: gameScene.size.height / 2 - 200  // Moved down to accommodate grid size label
                )
                powerUpLabel.name = "powerUpLabel"
                gameScene.addChild(powerUpLabel)
            } else {
                // Notify user that all power-ups are maxed out
                let powerUpLabel = SKLabelNode(text: "All Power-Ups are maxed!")
                powerUpLabel.fontName = "PPNeueMontreal-Bold"
                powerUpLabel.fontSize = 20
                powerUpLabel.position = CGPoint(
                    x: gameScene.size.width / 2,
                    y: gameScene.size.height / 2 - 200  // Moved down to accommodate grid size label
                )
                powerUpLabel.name = "powerUpLabel"
                gameScene.addChild(powerUpLabel)
            }
        }
    }
}
