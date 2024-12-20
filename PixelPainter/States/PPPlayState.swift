//
//  PlayState.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/22/24.
//

import GameplayKit
import SpriteKit

class PPPlayState: GKState {
    unowned let gameScene: PPGameScene
    let gridManager: PPGridManager
    let bankManager: PPBankManager
    let hudManager: PPHUDManager
    var powerUpManager: PPPowerUpManager!

    private var hintTimer: Timer?
    private var idleHintTimer: Timer?

    private var piecePlacedFromPowerup: Bool = false
    private var isLevelComplete: Bool = false

    init(gameScene: PPGameScene) {
        self.gameScene = gameScene
        self.gridManager = PPGridManager(gameScene: gameScene)
        self.bankManager = PPBankManager(gameScene: gameScene)
        self.hudManager = PPHUDManager(gameScene: gameScene)
        super.init()
        self.powerUpManager = PPPowerUpManager(
            gameScene: gameScene, playState: self)
    }

    override func didEnter(from previousState: GKState?) {
        setupPlayScene()
        startGame()
    }

    override func willExit(to nextState: GKState) {
        // Cleanup hint system related assets.
        stopHintTimer()
        stopIdleHintTimer()
        gridManager.hideHint()

        if let timerNode = gameScene.childNode(withName: "//circularTimer")
            as? PPCircularTimer
        {
            timerNode.stopTimer()
        }

        gameScene.removeAllChildren()
        isLevelComplete = false
    }

    private func setupPlayScene() {
        // Create and add background first
        let background = PPBackground()
        background.setup(screenSize: gameScene.size)
        background.zPosition = -2
        background.name = "backgroundNode"
        gameScene.addChild(background)

        gridManager.createGrid()
        bankManager.clearSelection()

        // Get grid reference for positioning other elements
        guard
            let gridNode = gameScene.childNode(withName: "grid")
                as? SKSpriteNode
        else { return }

        // Position grid in center
        let centerY = gameScene.size.height / 2 + 15
        gridNode.position = CGPoint(x: gameScene.size.width / 2, y: centerY)

        // Create HUD (timer and score)
        hudManager.createHUD()

        // Position HUD relative to grid top
        if let timerNode = gameScene.childNode(withName: "//circularTimer")
            as? PPCircularTimer,
            let hudNode = timerNode.parent
        {
            let hudOffset: CGFloat = 160
            hudNode.position = CGPoint(
                x: 0,
                y: gridNode.frame.maxY + hudOffset
            )
            timerNode.delegate = self
        }

        // Setup power-ups below grid with some spacing
        let powerUpOffset: CGFloat = isIPhoneSE ? 20 : 50
        powerUpManager.setupPowerUps(
            yPosition: gridNode.frame.minY - powerUpOffset)

        // Create bank below power-ups
        let bankOffset: CGFloat = isIPhoneSE ? 160 : 180
        let bankY = gridNode.frame.minY - bankOffset
        bankManager.createPictureBank(at: bankY)

        if !PPGameConstants.PPDeviceSizes.isIPad {
            adjustLayoutForIPhoneSE()
        }
    }

    private func startGame() {
        if let timerNode = gameScene.childNode(withName: "//circularTimer")
            as? PPCircularTimer
        {
            timerNode.delegate = self
            timerNode.startTimer(
                duration: gameScene.context.gameInfo.timeRemaining)
        }
        startIdleHintTimer()
    }

    // This function is only used from the place powerup.
    func notifyPiecePlaced(from powerup: Bool) {
        // Will always be true when called
        piecePlacedFromPowerup = powerup

        // If only one visible piece left place normally
        // This is necessary because in our place logic we will always place down
        // the final visible piece no matter what.
        if bankManager.getVisiblePieces().count > 1 {
            placePieceWithPowerUp()
        } else {
            didSuccessfullyPlacePiece()
        }

        piecePlacedFromPowerup = false
    }

    func updateTime(by seconds: Double) {
        if let timerNode = gameScene.childNode(withName: "//circularTimer")
            as? PPCircularTimer
        {
            timerNode.modifyTime(by: seconds)
            timerNode.showTimeBonus(seconds: seconds)  // Show the bonus animation
        }
    }

    private func didSuccessfullyPlacePiece() {
        PPSoundManager.shared.playSound(.piecePlaced)

        updateTime(by: 2)

        // Clear hint effects on successful placement
        stopHintTimer()
        stopIdleHintTimer()
        gridManager.hideHint()

        gameScene.context.gameInfo.score += 30
        hudManager.updateScore(withAnimation: true)

        bankManager.clearSelection()
        bankManager.refreshBankIfNeeded()

        startIdleHintTimer()

        if bankManager.isBankEmpty() {
            handleLevelComplete()
        }
        let impactLight = UIImpactFeedbackGenerator(style: .light)
        impactLight.prepare()
        impactLight.impactOccurred()
    }

    private func placePieceWithPowerUp() {
        print("placed with powerup")
        PPSoundManager.shared.playSound(.piecePlaced)
        updateTime(by: 2)

        // Update score and refresh the bank
        gameScene.context.gameInfo.score += 30
        hudManager.updateScore(withAnimation: true)

        startIdleHintTimer()

        bankManager.refreshBankIfNeeded()

        if bankManager.isBankEmpty() {
            handleLevelComplete()
        }

        let impactLight = UIImpactFeedbackGenerator(style: .light)
        impactLight.prepare()
        impactLight.impactOccurred()
    }

    private func handleLevelComplete() {
        isLevelComplete = true
        // Stop timers immediately
        stopHintTimer()
        stopIdleHintTimer()

        if let timerNode = gameScene.childNode(withName: "//circularTimer")
            as? PPCircularTimer
        {
            timerNode.stopTimer()
        }

        PPSoundManager.shared.stopBackgroundMusic()
        PPSoundManager.shared.playSound(.levelComplete)

        // Disable interaction during victory sequence
        PPEffectManager.shared.temporarilyDisableInteraction(for: 5.5)  // Match total animation duration

        let timeBonus = Int(gameScene.context.gameInfo.timeRemaining)
        gameScene.context.gameInfo.score += timeBonus
        gameScene.context.gameInfo.level += 1

        // Play victory animation before transitioning to the next state
        if let backgroundNode = gameScene.childNode(withName: "backgroundNode")
            as? PPBackground,
            let gridNode = gameScene.childNode(withName: "grid")
                as? SKSpriteNode
        {

            if let snow = gameScene.childNode(withName: "snowEffect"),
                let overlay = gameScene.childNode(withName: "freezeOverlay")
            {
                snow.removeFromParent()
                overlay.removeFromParent()
            }

            // Calculate the vertical offset based on the grid position
            let verticalOffset = gridNode.position.y - gameScene.size.height / 2

            backgroundNode.fadeOutWarningOverlay {
                // Pass the grid position to the victory animation
                backgroundNode.playVictoryAnimation(gridOffset: verticalOffset)
                { [weak self] in
                    guard let self = self else { return }
                    PPSoundManager.shared.ensureBackgroundMusic()

                    if self.gameScene.context.gameInfo.level % 4 == 0
                        && self.gameScene.context.gameInfo.boardSize < 6
                    {
                        self.gameScene.context.gameInfo.boardSize += 1
                    }

                    self.gameScene.context.stateMachine?.enter(
                        PPMemorizeState.self)
                }
            }
        } else {
            gameScene.context.stateMachine?.enter(PPMemorizeState.self)
        }
    }

    private func handleGameOver() {

        PPEffectManager.shared.temporarilyDisableInteraction()
        PPEffectManager.shared.triggerGameOverVibrations()

        stopHintTimer()
        stopIdleHintTimer()
        gridManager.hideHint()
        self.bankManager.clearSelection()
        PPSoundManager.shared.stopBackgroundMusic()

        let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
        impactHeavy.prepare()
        impactHeavy.impactOccurred()

        if let gridNode = gameScene.childNode(withName: "grid")
            as? SKSpriteNode,
            !gridNode.children.filter({
                $0.name?.starts(with: "piece_") ?? false
            }).isEmpty
        {
            // Only play animation if there are pieces
            self.powerUpManager.removeFlashImage()  // Add this line
            PPEffectManager.shared.playGameOverEffect { [weak self] in
                guard let self = self else { return }
                self.gameScene.context.stateMachine?.enter(PPGameOverState.self)
            }
        } else {
            // Go directly to game over if no pieces
            self.powerUpManager.removeFlashImage()  // Add this line
            self.gameScene.context.stateMachine?.enter(PPGameOverState.self)
            PPSoundManager.shared.playSound(.gameOverNoPieces)
        }
    }

    // MARK: - Touch Handling

    func handleGridPlacement(at location: CGPoint) {
        guard
            let gridNode = gameScene.childNode(withName: "grid")
                as? SKSpriteNode,
            let selectedPiece = bankManager.getSelectedPiece(),
            gridNode.contains(location)
        else { return }

        let gridLocation = gridNode.convert(location, from: gameScene)

        // exit early if cell not empty
        guard gridManager.isCellEmpty(at: gridLocation) else { return }

        if gridManager.tryPlacePiece(selectedPiece, at: gridLocation) {
            didSuccessfullyPlacePiece()
        } else {
            showWrongPlacementAnimation(for: selectedPiece, at: location)
        }
    }

    private func showWrongPlacementAnimation(
        for piece: SKSpriteNode, at location: CGPoint
    ) {
        PPSoundManager.shared.playSound(.incorrectPiecePlaced)
        PPEffectManager.shared.temporarilyDisableInteraction(
            for: PPGameConstants.PPGeneralGamePlay.wrongPlacementBufferTime)
        if let cropNode = piece.children.first as? SKCropNode {
            PPEffectManager.shared.cooldown(
                cropNode,
                duration: PPGameConstants.PPGeneralGamePlay.wrongPlacementBufferTime
            )
        }
        PPEffectManager.shared.shakeNode(piece)

        let impactMedium = UIImpactFeedbackGenerator(style: .medium)
        impactMedium.prepare()
        impactMedium.impactOccurred()

        // Locate the grid slot based on touch location
        guard
            let gridNode = gameScene.childNode(withName: "grid")
                as? SKSpriteNode
        else { return }

        let gridDimension = gameScene.context.layoutInfo.gridDimension
        let pieceSize = gameScene.context.layoutInfo.pieceSize

        // Convert touch location to grid coordinates
        let gridLocation = gridNode.convert(location, from: gameScene)
        let col = Int(
            (gridLocation.x + gridNode.size.width / 2) / pieceSize.width)
        let row =
            gridDimension - 1
            - Int(
                (gridLocation.y + gridNode.size.height / 2) / pieceSize.height)

        // Validate grid slot
        guard row >= 0, row < gridDimension, col >= 0, col < gridDimension
        else { return }
        let gridSlotName = "frame_\(row)_\(col)"

        if let gridSlot = gridNode.childNode(withName: gridSlotName)
            as? SKSpriteNode
        {
            flashGridSlotRed(gridSlot)
        }
    }

    private func flashGridSlotRed(_ slot: SKSpriteNode) {
        let originalColor = slot.color
        let flashAction = SKAction.sequence([
            SKAction.group([
                SKAction.colorize(
                    with: .red, colorBlendFactor: 1.0, duration: 0.15),
                SKAction.scale(to: 1.05, duration: 0.15),  // Slight scale up
            ]),
            SKAction.wait(forDuration: 0.1),
            SKAction.group([
                SKAction.colorize(
                    with: originalColor, colorBlendFactor: 0.0, duration: 0.15),
                SKAction.scale(to: 1.0, duration: 0.15),  // Return to normal size
            ]),
        ])
        slot.run(flashAction, withKey: "flashRedEffect")
    }

    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: gameScene)

        // Check for power-up touches first, before any other processing
        if !isLevelComplete && powerUpManager.handleTouch(at: location) {
            return
        }

        // Handle piece selection in bank
        if let bankNode = bankManager.bankNode,
            bankNode.contains(location)
        {
            let bankLocation = bankNode.convert(location, from: gameScene)
            if let touchedPiece = bankNode.nodes(at: bankLocation)
                .first(where: { $0.name?.starts(with: "piece_") == true })
                as? SKSpriteNode
            {

                if touchedPiece != bankManager.getSelectedPiece() {
                    stopHintTimer()
                    stopIdleHintTimer()
                    gridManager.hideHint()
                    bankManager.selectPiece(touchedPiece)
                    startHintTimer()
                }
            }
            return
        }

        // Handle grid placement
        handleGridPlacement(at: location)
    }

    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: gameScene)
        handlePieceHovering(at: location)
    }

    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

    // MARK: - Hint System
    private func startHintTimer() {
        hintTimer = Timer.scheduledTimer(
            withTimeInterval: PPGameConstants.PPGeneralGamePlay.hintWaitTime,
            repeats: false
        ) { [weak self] _ in
            guard let self = self,
                let selectedPiece = self.bankManager.getSelectedPiece()
            else { return }

            self.gridManager.showHintForPiece(selectedPiece)
        }
    }

    func stopHintTimer() {
        hintTimer?.invalidate()
        hintTimer = nil
    }

    func startIdleHintTimer() {
        stopIdleHintTimer()

        idleHintTimer = Timer.scheduledTimer(
            withTimeInterval: PPGameConstants.PPGeneralGamePlay.idleHintWaitTime,
            repeats: false
        ) { [weak self] _ in
            guard let self = self,
                self.bankManager.getSelectedPiece() == nil
            else { return }

            // Only show hint if no piece is currently selected
            if let randomPiece = self.bankManager
                .getRandomVisibleUnplacedPiece()
            {
                self.bankManager.selectPiece(randomPiece)
                self.gridManager.showHintForPiece(randomPiece)
            }
        }
    }

    private func stopIdleHintTimer() {
        idleHintTimer?.invalidate()
        idleHintTimer = nil
    }

    private func handlePieceHovering(at location: CGPoint) {
        guard let bankNode = bankManager.bankNode,
            bankNode.contains(location)
        else {
            // If not hovering over bank, clear any existing hover effects
            bankManager.clearHoverEffects()
            return
        }

        let bankLocation = bankNode.convert(location, from: gameScene)
        if let touchedPiece = bankNode.nodes(at: bankLocation)
            .first(where: { $0.name?.starts(with: "piece_") == true })
            as? SKSpriteNode
        {
            bankManager.applyHoverEffect(to: touchedPiece)
        } else {
            bankManager.clearHoverEffects()
        }
    }
}

// MARK: - CircularTimerDelegate
extension PPPlayState: PPCircularTimerDelegate {
    func timerDidComplete() {
        handleGameOver()
    }

    func timerDidUpdate(currentTime: TimeInterval) {
        gameScene.context.gameInfo.timeRemaining = currentTime
        if let background = gameScene.childNode(withName: "backgroundNode")
            as? PPBackground
        {
            background.updateWarningLevel(timeRemaining: currentTime)
        }
    }
}

extension PPPlayState {
    private var isIPhoneSE: Bool {
        let screenSize = UIScreen.main.bounds.size
        return screenSize.height <= PPGameConstants.PPDeviceSizes.SE_HEIGHT
    }

    func adjustLayoutForIPhoneSE() {
        // Only adjust for SE, not iPad
        guard
            !PPGameConstants.PPDeviceSizes.isIPad
                && gameScene.size.height <= PPGameConstants.PPDeviceSizes.SE_HEIGHT
        else { return }

        // Adjust timer position
        if let timerNode = gameScene.childNode(withName: "//circularTimer") {
            // Move timer up by adjusting its parent (HUD) position
            if let hudNode = timerNode.parent {
                // Original position is gameScene.size.height - 100
                hudNode.position = CGPoint(x: 0, y: gameScene.size.height - 45)
            }
        }

        // Adjust power-up positions
        powerUpManager.adjustPowerUpsForIPhoneSE()
    }

    private func adjustLayoutForIPad() {
        // Fixed positions for iPad
        let timerYPosition: CGFloat = 1050  // Fixed position from top
        let powerUpsYPosition: CGFloat = 350  // Fixed Y position for power-ups
        let bankYPosition: CGFloat = 150  // Fixed Y position for bank

        // Adjust timer position
        if let timerNode = gameScene.childNode(withName: "//circularTimer") {
            if let hudNode = timerNode.parent {
                hudNode.position = CGPoint(x: 0, y: timerYPosition)
            }
        }

        // Adjust bank position
        if let bankNode = bankManager.bankNode {
            bankNode.position = CGPoint(
                x: gameScene.size.width / 2, y: bankYPosition)
        }

        // Adjust grid position to be more centered
        if let gridNode = gameScene.childNode(withName: "grid") as? SKSpriteNode
        {
            gridNode.position = CGPoint(
                x: gameScene.size.width / 2,
                y: gameScene.size.height / 2 + 15
            )
        }

        // Adjust power-ups position through PowerUpManager
        powerUpManager.adjustLayoutForIPad(yPosition: powerUpsYPosition)
    }
}
