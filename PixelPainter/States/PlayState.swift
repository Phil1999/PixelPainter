//
//  PlayState.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/22/24.
//

import GameplayKit
import SpriteKit

class PlayState: GKState {
    unowned let gameScene: GameScene
    let gridManager: GridManager
    let bankManager: BankManager
    let hudManager: HUDManager
    var powerUpManager: PowerUpManager!

    private var hintTimer: Timer?
    private var idleHintTimer: Timer?

    init(gameScene: GameScene) {
        self.gameScene = gameScene
        self.gridManager = GridManager(gameScene: gameScene)
        self.bankManager = BankManager(gameScene: gameScene)
        self.hudManager = HUDManager(gameScene: gameScene)
        super.init()
        self.powerUpManager = PowerUpManager(
            gameScene: gameScene, playState: self)
    }

    override func didEnter(from previousState: GKState?) {
        print("Entering Play State")
        setupPlayScene()
        startGame()
    }

    override func willExit(to nextState: GKState) {
        // Cleanup hint system related assets.
        stopHintTimer()
        stopIdleHintTimer()
        gridManager.hideHint()
        

        if let timerNode = gameScene.childNode(withName: "//circularTimer")
            as? CircularTimer
        {
            timerNode.stopTimer()
        }

        gameScene.removeAllChildren()
    }

    private func setupPlayScene() {
        // Create and add background first
        let background = Background()
        background.setup(screenSize: gameScene.size)
        background.zPosition = -2
        background.name = "backgroundNode"
        gameScene.addChild(background)

        // Then add game elements
        gridManager.createGrid()
        bankManager.clearSelection()
        bankManager.createPictureBank()
        hudManager.createHUD()
        powerUpManager.setupPowerUps()

        if let timerNode = gameScene.childNode(withName: "//circularTimer")
            as? CircularTimer
        {
            timerNode.delegate = self
        }
    }

    private func startGame() {
        if let timerNode = gameScene.childNode(withName: "//circularTimer")
            as? CircularTimer
        {
            timerNode.delegate = self
            timerNode.startTimer(
                duration: gameScene.context.gameInfo.timeRemaining)
        }
        startIdleHintTimer()
    }


    func notifyPiecePlaced() {
        didSuccessfullyPlacePiece()
    }

    func updateTime(by seconds: Double) {
        if let timerNode = gameScene.childNode(withName: "//circularTimer")
            as? CircularTimer
        {
            timerNode.modifyTime(by: seconds)
            timerNode.showTimeBonus(seconds: seconds)  // Show the bonus animation
        }
    }

    private func didSuccessfullyPlacePiece() {
        SoundManager.shared.playSound(.piecePlaced)

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

    private func handleLevelComplete() {
        // Stop timers immediately
        stopHintTimer()
        stopIdleHintTimer()
        

        if let timerNode = gameScene.childNode(withName: "//circularTimer") as? CircularTimer {
            timerNode.stopTimer()
        }
        
        SoundManager.shared.stopBackgroundMusic()
        SoundManager.shared.playSound(.levelComplete)

        // Disable interaction during victory sequence
        EffectManager.shared.temporarilyDisableInteraction(for: 5.5)  // Match total animation duration

        let timeBonus = Int(gameScene.context.gameInfo.timeRemaining)
        gameScene.context.gameInfo.score += timeBonus
        gameScene.context.gameInfo.level += 1

        // Play victory animation before transitioning to the next state
        if let backgroundNode = gameScene.childNode(withName: "backgroundNode")
            as? Background
        {
            
            if let snow = gameScene.childNode(withName: "snowEffect"),
               let overlay = gameScene.childNode(withName: "freezeOverlay") {
                snow.removeFromParent()
                overlay.removeFromParent()
            }
            
            backgroundNode.fadeOutWarningOverlay {
                backgroundNode.playVictoryAnimation { [weak self] in
                    guard let self = self else { return }
                    SoundManager.shared.resumeBackgroundMusic()
                    // Update board size if needed
                    if self.gameScene.context.gameInfo.level % 4 == 0
                        && self.gameScene.context.gameInfo.boardSize < 6
                    {
                        self.gameScene.context.gameInfo.boardSize += 1
                        print(
                            "board size is now: ",
                            self.gameScene.context.gameInfo.boardSize)
                    }
                    
                    // Transition to memorize state after animation completes
                    self.gameScene.context.stateMachine?.enter(MemorizeState.self)
                }
            }
        } else {
            // If no background node, directly transition to the next state
            gameScene.context.stateMachine?.enter(MemorizeState.self)
        }
    }
    
    private func handleGameOver() {

        EffectManager.shared.temporarilyDisableInteraction()
        EffectManager.shared.triggerGameOverVibrations()
        
        stopHintTimer()
        stopIdleHintTimer()
        gridManager.hideHint()
        self.bankManager.clearSelection()
        SoundManager.shared.stopBackgroundMusic()

        if let gridNode = gameScene.childNode(withName: "grid")
            as? SKSpriteNode,
            !gridNode.children.filter({
                $0.name?.starts(with: "piece_") ?? false
            }).isEmpty
        {
            // Only play animation if there are pieces
            self.powerUpManager.removeFlashImage()  // Add this line
            EffectManager.shared.playGameOverEffect { [weak self] in
                guard let self = self else { return }
                self.gameScene.context.stateMachine?.enter(GameOverState.self)
            }
        } else {
            // Go directly to game over if no pieces
            self.powerUpManager.removeFlashImage()  // Add this line
            self.gameScene.context.stateMachine?.enter(GameOverState.self)
            SoundManager.shared.playSound(.gameOverNoPieces)
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
            showWrongPlacementAnimation(for: selectedPiece)
        }
    }

    private func showWrongPlacementAnimation(for piece: SKSpriteNode) {
        EffectManager.shared.temporarilyDisableInteraction(for: GameConstants.GeneralGamePlay.wrongPlacementBufferTime)
        EffectManager.shared.cooldown(piece, duration: GameConstants.GeneralGamePlay.wrongPlacementBufferTime)
        EffectManager.shared.shakeNode(piece)
        
        let impactMedium = UIImpactFeedbackGenerator(style: .medium)
        impactMedium.prepare()
        impactMedium.impactOccurred()
    }

    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: gameScene)

        // Check for power-up touches
        if powerUpManager.handleTouch(at: location) {
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
    }

    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }


    // MARK: - Hint System
    private func startHintTimer() {
        hintTimer = Timer.scheduledTimer(
            withTimeInterval: GameConstants.GeneralGamePlay.hintWaitTime,
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
            withTimeInterval: GameConstants.GeneralGamePlay.idleHintWaitTime,
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

}

// MARK: - CircularTimerDelegate
extension PlayState: CircularTimerDelegate {
    func timerDidComplete() {
        handleGameOver()
    }

    func timerDidUpdate(currentTime: TimeInterval) {
        gameScene.context.gameInfo.timeRemaining = currentTime
        if let background = gameScene.childNode(withName: "backgroundNode") as? Background {
            background.updateWarningLevel(timeRemaining: currentTime)
        }
    }
}
