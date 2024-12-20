//
//  MemorizeState.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/22/24.
//

import AVFoundation
import GameplayKit
import SpriteKit
import UIKit

class PPMemorizeState: GKState {
    unowned let gameScene: PPGameScene
    private let memorizeTime: TimeInterval = 3
    private var isFirstLevel: Bool = false

    private var powerUpSelectionNodes: [PPPowerUpIcon] = []
    private var selectedPowerUps: Set<PPPowerUpType> = []
    private var chooseTwoLabel: SKLabelNode?
    private var levelLabelContainer: SKNode?
    private var countdownStarted = false
    private var currentInfoModal: SKNode?
    private var confirmButton: SKNode?
    private var infoButtons: [SKSpriteNode] = []
    private var scoreCounter: PPScoreCounter?
    private var powerUpSelectionComplete = false
    private var iconInstructionLabel: SKNode?

    private var tutorialVideoLooper: AVPlayerLooper?

    init(gameScene: PPGameScene) {
        self.gameScene = gameScene
        super.init()
    }

    override func didEnter(from previousState: GKState?) {
        gameScene.isUserInteractionEnabled = true

        resetPowerUpSelectionState()

        isFirstLevel = gameScene.context.gameInfo.level == 1

        if !isFirstLevel {
            moveToNextImage()
            updateGridSize()
            updateGameTime()
        }

        setupMemorizeScene()
        showPowerUpSelection()
    }

    private func resetPowerUpSelectionState() {
        powerUpSelectionNodes.removeAll()
        selectedPowerUps.removeAll()
        confirmButton = nil
        currentInfoModal = nil
        infoButtons.removeAll()
        countdownStarted = false
        powerUpSelectionComplete = false
        resetPulsatingAnimations()
    }

    func handleTouch(at location: CGPoint) {
        if powerUpSelectionComplete {
            return
        }
        // Handle info modal close button
        if let modal = currentInfoModal {
            let modalLocation = modal.convert(location, from: gameScene)

            // Get the modal background which defines the clickable area
            if let modalBg = modal.children.first as? SKShapeNode {
                if !modalBg.contains(modalLocation) {
                    // Click was outside modal, close it
                    modal.removeFromParent()
                    currentInfoModal = nil
                    return
                }
            }

            // Handle close button
            if let closeButton = modal.childNode(withName: "close_info"),
                closeButton.contains(modalLocation)
            {
                modal.removeFromParent()
                currentInfoModal = nil
                return
            }

            return  // If modal is open, only handle modal touches
        }

        // Handle confirm button
        if let confirmButton = confirmButton,
            confirmButton.contains(location)
        {
            completePowerUpSelection()
            return
        }

        // Touch logic for selecting tutorial icon
        if let touchedNode = gameScene.nodes(at: location).first,
            let name = touchedNode.name,
            name.starts(with: "info_")
        {
            let powerUpType = name.replacingOccurrences(of: "info_", with: "")
            if let type = PPPowerUpType(rawValue: powerUpType) {
                showPowerUpInfo(for: type)
            }
            return
        }

        // Handle power-up selection
        for icon in powerUpSelectionNodes {
            if icon.contains(location) {
                handlePowerUpSelection(icon)
                return
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

    private func updateGridSize() {
        let level = gameScene.context.gameInfo.level

        // Define grid progression logic
        let newGridDimension: Int
        switch level {
        case 1...2:
            newGridDimension = 3
        case 3...5:
            newGridDimension = 4
        case 6...9:
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
            newGameTime = 10  // 3x3 grid
        case 3...5:
            newGameTime = 10  // 4x4 grid
        case 6...9:
            newGameTime = 15  // 5x5 grid
        default:
            newGameTime = 20  // 6x6 grid
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
        return stateClass is PPPlayState.Type
    }

    private func setupMemorizeScene() {
        let background = PPBackground()
        background.setup(screenSize: gameScene.size)
        background.zPosition = -2
        gameScene.addChild(background)

        guard let image = gameScene.queueManager.getCurrentImage() else {
            return
        }
        gameScene.context.gameInfo.currentImage = image

        let imageNode = SKSpriteNode(texture: SKTexture(image: image))
        imageNode.name = "imageNode"
        imageNode.size = gameScene.context.layoutInfo.gridSize
        imageNode.position = CGPoint(
            x: gameScene.size.width / 2, y: gameScene.size.height / 1.85)
        gameScene.addChild(imageNode)

        // Add blur over the image
        let blurOverlay = SKEffectNode()
        blurOverlay.filter = CIFilter(
            name: "CIGaussianBlur", parameters: ["inputRadius": 25.0])
        blurOverlay.shouldRasterize = true
        blurOverlay.name = "blurImageNode"

        let blurredImage = SKSpriteNode(texture: SKTexture(image: image))
        blurredImage.size = CGSize(
            width: imageNode.size.width + 5,
            height: imageNode.size.height + 5)
        blurredImage.position = .zero
        blurOverlay.addChild(blurredImage)

        blurOverlay.position = imageNode.position
        blurOverlay.zPosition = imageNode.zPosition + 1
        gameScene.addChild(blurOverlay)

        let frameSize = CGSize(
            width: imageNode.size.width + 15,
            height: imageNode.size.height + 15)
        let frameNode = SKShapeNode(rectOf: frameSize, cornerRadius: 10)
        frameNode.strokeColor = .white
        frameNode.lineWidth = 4
        frameNode.position = imageNode.position
        frameNode.zPosition = imageNode.zPosition - 1
        frameNode.name = "frameNode"
        gameScene.addChild(frameNode)

        // level label container
        let levelContainer = SKNode()

        if let imageNode = gameScene.childNode(withName: "imageNode")
            as? SKSpriteNode
        {
            // Position the container above the image with some padding
            let verticalPadding: CGFloat = 80
            levelContainer.position = CGPoint(
                x: gameScene.size.width / 2,
                y: imageNode.position.y + (imageNode.size.height / 2)
                    + verticalPadding
            )
        }

        let numberFontSize: CGFloat = 56
        let levelFontSize: CGFloat = 20

        // Calculate max number width
        let tempLabel = SKLabelNode(fontNamed: "PPNeueMontreal-Bold")
        tempLabel.fontSize = numberFontSize
        tempLabel.text = "1000"  // reference number
        let maxNumberWidth = tempLabel.frame.width

        let levelText = SKLabelNode()
        levelText.fontName = "PPNeueMontreal-Bold"
        levelText.fontSize = levelFontSize
        levelText.text = "LEVEL"
        levelText.fontColor = .white.withAlphaComponent(0.75)
        levelText.verticalAlignmentMode = .center
        levelText.horizontalAlignmentMode = .center
        levelText.position = CGPoint(x: 5, y: 15)

        let levelNum = isFirstLevel ? 1 : Int(gameScene.context.gameInfo.level)
        let numberLabel = SKLabelNode(fontNamed: "PPNeueMontreal-Bold")
        numberLabel.fontSize = numberFontSize
        numberLabel.text = "\(levelNum)"
        numberLabel.fontColor = .white
        numberLabel.verticalAlignmentMode = .center
        numberLabel.horizontalAlignmentMode = .center
        numberLabel.position = CGPoint(x: 0, y: -20)

        let underline = SKShapeNode(
            rectOf: CGSize(width: maxNumberWidth, height: 2)
        )
        underline.fillColor = .white
        underline.strokeColor = .clear
        underline.alpha = 0.3
        underline.position = CGPoint(x: 0, y: -50)

        levelContainer.addChild(levelText)
        levelContainer.addChild(numberLabel)
        levelContainer.addChild(underline)
        self.levelLabelContainer = levelContainer
        gameScene.addChild(levelContainer)

        let chooseLabel = SKLabelNode(text: "Choose two")
        chooseLabel.fontName = "PPNeueMontreal-Bold"
        chooseLabel.fontSize = 32
        chooseLabel.position = CGPoint(
            x: gameScene.size.width / 2,
            y: gameScene.size.height / 2 - 200
        )
        self.chooseTwoLabel = chooseLabel
        gameScene.addChild(chooseLabel)

        // Instruction message
        let iconInstructionLabel = SKLabelNode(
            text: "Tap the info icon to learn about each power-up!")
        iconInstructionLabel.fontName = "PPNeueMontreal-Regular"
        iconInstructionLabel.fontSize = 12
        iconInstructionLabel.fontColor = .lightGray
        iconInstructionLabel.verticalAlignmentMode = .center
        iconInstructionLabel.position = CGPoint(
            x: gameScene.size.width / 2,
            y: gameScene.size.height / 2 - 220)
        gameScene.addChild(iconInstructionLabel)
        self.iconInstructionLabel = iconInstructionLabel

        if !isFirstLevel {
            // Calculate score position (relative to image)
            let xOffset: CGFloat = 130
            let yOffset: CGFloat = 100

            let scoreCounter = PPScoreCounter(
                text: "\(gameScene.context.gameInfo.score)")
            scoreCounter.position = CGPoint(
                x: imageNode.position.x - xOffset,
                y: imageNode.frame.maxY + yOffset
            )
            gameScene.addChild(scoreCounter)
            self.scoreCounter = scoreCounter
        }

        let readyLabel = SKLabelNode(text: "")
        readyLabel.fontName = "PPNeueMontreal-Bold"
        readyLabel.fontSize = 48
        readyLabel.fontColor = .white
        readyLabel.position = CGPoint(
            x: gameScene.size.width / 2, y: gameScene.size.height / 2 - 260)
        readyLabel.name = "readyLabel"
        readyLabel.alpha = 0  // Start hidden
        gameScene.addChild(readyLabel)

        adjustLayoutForIPhoneSE()
    }

    private func transitionToPlayState() {
        gameScene.queueManager.printCurrentQueue()
        gameScene.context.stateMachine?.enter(PPPlayState.self)
    }

    private func blinkCountdownLabel(readyLabel: SKLabelNode, blinkCount: Int) {
        // Remove the blur effect from image
        if let blurNode = self.gameScene.childNode(withName: "blurImageNode")
            as? SKEffectNode
        {
            let fadeOut = SKAction.sequence([
                SKAction.fadeOut(withDuration: 1.5),
                SKAction.removeFromParent(),
            ])
            blurNode.run(fadeOut)
        }

        let countdownSequence = ["3", "2", "1", "Go!"]
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
                readyLabel.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: 1.0),
                        SKAction.run { [weak self] in
                            guard let self = self,
                                let imageNode = self.gameScene.children.first(
                                    where: {
                                        $0 is SKSpriteNode
                                            && $0 != self.gameScene.background
                                    }) as? SKSpriteNode
                            else { return }

                            self.animateImageBreak(imageNode: imageNode)
                        },
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

        if let frameNode = gameScene.childNode(withName: "frameNode") {
            frameNode.removeFromParent()
        }

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
                    texture: SKTexture(
                        rect: textureRect, in: imageNode.texture!),
                    size: pieceSize
                )

                pieceNode.position = CGPoint(
                    x: CGFloat(col) * pieceSize.width - imageNode.size.width / 2
                        + pieceSize.width / 2,
                    y: CGFloat((gridDimension - 1) - row) * pieceSize.height
                        - imageNode.size.height / 2 + pieceSize.height / 2
                )

                piecesContainer.addChild(pieceNode)
                allPieces.append(pieceNode)
            }
        }

        imageNode.removeFromParent()

        for piece in allPieces {
            let randomAngle = CGFloat.random(in: 0...2 * .pi)
            let randomDistance = CGFloat.random(in: 200...400)
            let dx = randomDistance * cos(randomAngle)
            let dy = randomDistance * sin(randomAngle)

            let moveAction = SKAction.move(
                by: CGVector(dx: dx, dy: dy), duration: 0.5)
            let fadeOutAction = SKAction.fadeOut(withDuration: 0.5)
            let rotateAction = SKAction.rotate(
                byAngle: .pi * 2 * CGFloat.random(in: -1...1), duration: 0.5)
            let group = SKAction.group([
                moveAction, fadeOutAction, rotateAction,
            ])

            piece.run(group)
        }
        PPSoundManager.shared.playSound(.memorizeBreak)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            piecesContainer.removeFromParent()
            self?.transitionToPlayState()
        }
    }

}

// MARK: Power-Up Selection UI
extension PPMemorizeState {

    private func showPowerUpInfo(for type: PPPowerUpType) {
        // Remove any existing modal
        currentInfoModal?.removeFromParent()

        // Create modal container
        let modal = SKNode()

        let backgroundSize = CGSize(width: 325, height: 500)
        let bg = SKShapeNode(rectOf: backgroundSize, cornerRadius: 20)
        bg.fillColor = UIColor(white: 0.1, alpha: 1)
        bg.strokeColor = UIColor(white: 1, alpha: 0.1)
        bg.lineWidth = 2
        modal.addChild(bg)

        // Title
        let titleLabel = SKLabelNode(fontNamed: "PPNeueMontreal-Bold")
        titleLabel.text = type.displayName
        titleLabel.fontSize = 24
        titleLabel.fontColor = type.themeColor
        titleLabel.position = CGPoint(x: 0, y: 200)
        titleLabel.horizontalAlignmentMode = .center
        modal.addChild(titleLabel)

        // Video container
        let videoContainerSize = CGSize(width: 119.35, height: 250)

        let cropNode = SKCropNode()
        let maskNode = SKShapeNode(rectOf: videoContainerSize, cornerRadius: 12)
        maskNode.fillColor = .white
        cropNode.maskNode = maskNode
        cropNode.position = CGPoint(x: 0, y: 50)

        // video player
        if let url = Bundle.main.url(
            forResource: "\(type.videoFileName)", withExtension: "mp4")
        {
            let asset = AVAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            let player = AVQueuePlayer()

            player.automaticallyWaitsToMinimizeStalling = false
            player.preventsDisplaySleepDuringVideoPlayback = false
            player.isMuted = true

            // Video should loop
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                self?.tutorialVideoLooper = AVPlayerLooper(
                    player: player, templateItem: playerItem)
            }

            // Create and configure video node
            let videoNode = SKVideoNode(avPlayer: player)
            videoNode.size = videoContainerSize

            cropNode.addChild(videoNode)
            videoNode.play()
        }

        // Border container
        let videoContainer = SKShapeNode(
            rectOf: videoContainerSize, cornerRadius: 12)
        videoContainer.fillColor = .clear
        videoContainer.strokeColor = type.themeColor
        videoContainer.lineWidth = 2
        videoContainer.position = cropNode.position

        modal.addChild(cropNode)
        modal.addChild(videoContainer)

        // Description section
        let containerWidth = backgroundSize.width - 40
        let descriptionText = getPowerUpDescription(type)

        let tempLabel = SKLabelNode(fontNamed: "PPNeueMontreal-Regular")
        tempLabel.text = descriptionText
        tempLabel.fontSize = 16
        tempLabel.numberOfLines = 0
        tempLabel.preferredMaxLayoutWidth = containerWidth - 40  // Add padding
        let textHeight = tempLabel.calculateAccumulatedFrame().height

        let descriptionContainer = SKShapeNode(
            rectOf: CGSize(width: containerWidth, height: textHeight + 30),
            cornerRadius: 12)
        descriptionContainer.fillColor = UIColor(white: 0.1, alpha: 0.95)
        descriptionContainer.strokeColor = UIColor(white: 1, alpha: 0.1)
        descriptionContainer.position = CGPoint(x: 0, y: -135)
        modal.addChild(descriptionContainer)

        let descLabel = SKLabelNode(fontNamed: "PPNeueMontreal-Regular")
        descLabel.text = descriptionText
        descLabel.fontSize = 16
        descLabel.fontColor = .white
        descLabel.numberOfLines = 0
        descLabel.preferredMaxLayoutWidth = containerWidth - 40
        descLabel.horizontalAlignmentMode = .left

        descLabel.position = CGPoint(
            x: -containerWidth / 2 + 20,
            y: descriptionContainer.position.y + (textHeight / 2) - textHeight
        )
        modal.addChild(descLabel)

        // Uses
        let usesLabel = SKLabelNode(fontNamed: "PPNeueMontreal-Medium")
        usesLabel.text = "Uses: \(type.uses)"
        usesLabel.fontSize = 16
        usesLabel.fontColor = .white
        usesLabel.horizontalAlignmentMode = .center
        usesLabel.position = CGPoint(x: 0, y: -208)
        modal.addChild(usesLabel)

        let dividerLine = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -backgroundSize.width / 2 + 20, y: -220))
        path.addLine(to: CGPoint(x: backgroundSize.width / 2 - 20, y: -220))
        dividerLine.path = path
        dividerLine.strokeColor = UIColor(white: 0.3, alpha: 1)
        dividerLine.lineWidth = 1
        modal.addChild(dividerLine)

        let instructionLabel = SKLabelNode(fontNamed: "PPNeueMontreal-Regular")
        instructionLabel.text =
            "Tap the power-up icon during gameplay to activate"
        instructionLabel.fontSize = 10
        instructionLabel.fontColor = UIColor(white: 0.7, alpha: 1)
        instructionLabel.horizontalAlignmentMode = .center
        instructionLabel.position = CGPoint(x: 0, y: -240)
        modal.addChild(instructionLabel)

        // Close button
        let closeButton = SKSpriteNode(imageNamed: "close-icon")
        closeButton.size = CGSize(width: 18, height: 18)
        closeButton.position = CGPoint(x: 135, y: 225)
        closeButton.name = "close_info"
        modal.addChild(closeButton)

        modal.position = CGPoint(
            x: gameScene.size.width / 2, y: gameScene.size.height / 2)
        modal.zPosition = 100
        gameScene.addChild(modal)

        currentInfoModal = modal
    }

    private func getPowerUpDescription(_ type: PPPowerUpType) -> String {
        switch type {
        case .timeStop:
            return
                "Freezes the timer for 5 seconds, giving you extra time to think and place pieces."
        case .place:
            return
                "Automatically places the leftmost unplaced piece in its correct position."
        case .flash:
            return
                "Briefly flashes the complete image for 5 seconds over the grid."
        case .shuffle:
            return
                "Immediately refreshes the piece bank helping you find the pieces you need."
        }
    }

    private func getCooldownText(_ type: PPPowerUpType) -> String {
        switch type {
        case .timeStop: return "5s"
        case .place: return "None"
        case .flash: return "5s"
        case .shuffle: return "None"
        }
    }

    // Add power-up selection UI
    private func showPowerUpSelection() {

        let powerUps = PPPowerUpType.allCases

        for (index, type) in powerUps.enumerated() {
            let icon = PPPowerUpIcon(type: type, uses: type.uses, minimal: true)
            positionPowerUpIcon(icon, at: index, totalPowerUps: powerUps.count)
            icon.alpha = 0.5
            gameScene.addChild(icon)
            powerUpSelectionNodes.append(icon)
            startPulsatingAnimation(for: icon)

            // Add info button
            let infoButton = SKSpriteNode(imageNamed: "info-icon")
            infoButton.size = CGSize(width: 20, height: 20)
            infoButton.position = CGPoint(
                x: icon.position.x + 25,
                y: icon.position.y + 25
            )
            infoButton.colorBlendFactor = 1.0
            infoButton.color = type.themeColor
            infoButton.name = "info_\(type.rawValue)"

            gameScene.addChild(infoButton)
            infoButtons.append(infoButton)
        }
    }

    private func handlePowerUpSelection(_ icon: PPPowerUpIcon) {
        guard
            let type = PPPowerUpType(
                rawValue: icon.name?.replacingOccurrences(
                    of: "powerup_", with: "") ?? "")
        else { return }

        if selectedPowerUps.contains(type) {
            selectedPowerUps.remove(type)
            icon.alpha = 0.5
            // Hide confirm button when deselecting
            confirmButton?.removeFromParent()
            confirmButton = nil
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            PPSoundManager.shared.playSound(.deselect)

            // Pulsate all unselected icons
            powerUpSelectionNodes.forEach { node in
                if !selectedPowerUps.contains(
                    PPPowerUpType(
                        rawValue: node.name?.replacingOccurrences(
                            of: "powerup_", with: "") ?? "") ?? .timeStop)
                {
                    startPulsatingAnimation(for: node)
                }
            }
        } else if selectedPowerUps.count < 2 {
            selectedPowerUps.insert(type)
            icon.alpha = 1.0
            icon.removeAction(forKey: "pulsate")
            icon.setScale(1.0)  // Reset to default size when selected
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            PPSoundManager.shared.playSound(.select)

            // Show confirm button when we have 2 selections
            if selectedPowerUps.count == 2 {
                showConfirmButton()
                // Stop pulsating for all icons
                powerUpSelectionNodes.forEach {
                    $0.removeAction(forKey: "pulsate")
                    $0.setScale(1.0)  // Reset all to default size
                }
            } else {
                // Pulsate only unselected icons
                powerUpSelectionNodes.forEach { node in
                    if !selectedPowerUps.contains(
                        PPPowerUpType(
                            rawValue: node.name?.replacingOccurrences(
                                of: "powerup_", with: "") ?? "") ?? .timeStop)
                    {
                        startPulsatingAnimation(for: node)
                    } else {
                        node.removeAction(forKey: "pulsate")
                        node.setScale(1.0)  // Reset to default size
                    }
                }
            }
        }
    }

    private func showConfirmButton() {
        // Remove existing button if any
        confirmButton?.removeFromParent()

        // Create button container
        let button = SKNode()

        // Background
        let bg = SKShapeNode(
            rectOf: CGSize(width: 200, height: 50), cornerRadius: 25)
        bg.fillColor = UIColor(hex: "252525").withAlphaComponent(0.9)
        bg.strokeColor = .white
        bg.lineWidth = 2
        button.addChild(bg)

        // Label
        let label = SKLabelNode(text: "Confirm")
        label.fontName = "PPNeueMontreal-Bold"
        label.fontSize = 20
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        button.addChild(label)

        // Position below power-up icons
        positionConfirmButton(button)
        button.name = "confirm_button"

        gameScene.addChild(button)
        confirmButton = button

        startPulsatingAnimation(for: button)
    }

    private func completePowerUpSelection() {
        PPSoundManager.shared.playSound(.confirm)
        if let playState = gameScene.context.stateMachine?.state(
            forClass: PPPlayState.self) as? PPPlayState
        {
            playState.powerUpManager.setPowerUps(Array(selectedPowerUps))
        }
        powerUpSelectionComplete = true

        // Clean up all UI elements
        powerUpSelectionNodes.forEach { $0.removeFromParent() }
        infoButtons.forEach { $0.removeFromParent() }
        confirmButton?.removeFromParent()
        chooseTwoLabel?.removeFromParent()
        levelLabelContainer?.removeFromParent()
        scoreCounter?.removeFromParent()
        iconInstructionLabel?.removeFromParent()
        chooseTwoLabel = nil

        if !countdownStarted {
            countdownStarted = true
            if let readyLabel = gameScene.childNode(withName: "readyLabel")
                as? SKLabelNode
            {
                readyLabel.alpha = 1.0
                blinkCountdownLabel(
                    readyLabel: readyLabel, blinkCount: Int(memorizeTime))
            }
        }
    }

    private func startPulsatingAnimation(for node: SKNode) {
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        node.setScale(1.0)  // Start from default scale
        node.run(SKAction.repeatForever(pulse), withKey: "pulsate")
    }

    private func resetPulsatingAnimations() {
        powerUpSelectionNodes.forEach { node in
            node.removeAction(forKey: "pulsate")
            startPulsatingAnimation(for: node)
        }
    }
}

extension PPMemorizeState {
    private var isIPhoneSE: Bool {
        let screenSize = UIScreen.main.bounds.size
        return screenSize.height <= PPGameConstants.PPDeviceSizes.SE_HEIGHT
    }

    private func adjustLayoutForIPhoneSE() {
        guard isIPhoneSE else { return }

        // Adjust "Choose two" label position
        if let chooseLabel = chooseTwoLabel {
            chooseLabel.position.y = gameScene.size.height / 2 - 155
        }

        // Adjust instruction text
        if let instructionLabel = iconInstructionLabel {
            instructionLabel.position.y = gameScene.size.height / 2 - 170
        }

        // Adjust power-up icons and info buttons
        for (index, icon) in powerUpSelectionNodes.enumerated() {
            // Move power-ups up by 50 points
            icon.position.y = gameScene.size.height / 2 - 225

            // Adjust associated info button
            if index < infoButtons.count {
                let infoButton = infoButtons[index]
                infoButton.position.y = icon.position.y + 25
            }
        }

        // Adjust confirm button when it appears
        if let confirmButton = confirmButton {
            confirmButton.position.y = gameScene.size.height / 2 - 300
        }
    }
}

extension PPMemorizeState {
    // Call this after creating the confirm button
    private func positionConfirmButton(_ button: SKNode) {
        let baseY =
            isIPhoneSE
            ? gameScene.size.height / 2 - 300
            :  // Adjusted for SE
            gameScene.size.height / 2 - 350  // Original position

        button.position = CGPoint(
            x: gameScene.size.width / 2,
            y: baseY
        )
    }

    // Call this when showing power-up selection
    private func positionPowerUpIcon(
        _ icon: PPPowerUpIcon, at index: Int, totalPowerUps: Int
    ) {
        let centerX = gameScene.size.width / 2
        let spacing: CGFloat = 100
        let totalWidth = CGFloat(totalPowerUps - 1) * spacing
        let startX = centerX - (totalWidth / 2)

        let baseY =
            isIPhoneSE
            ? gameScene.size.height / 2 - 225
            :  // Adjusted for SE
            gameScene.size.height / 2 - 275  // Original position

        icon.position = CGPoint(
            x: startX + CGFloat(index) * spacing,
            y: baseY
        )
    }
}
