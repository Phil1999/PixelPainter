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

    func notifyPiecePlaced() {
        didSuccessfullyPlacePiece()
    }

    private func notifyTimerUpdate() {
        guard
            let timerNode = gameScene.childNode(withName: "//circularTimer")
                as? CircularTimer
        else { return }
        timerNode.updateDiscreteTime(
            newTimeRemaining: gameScene.context.gameInfo.timeRemaining)
    }

    func updateTime(by seconds: Double) {
        
        if gameScene.context.gameInfo.timeRemaining <= 0 {
            gameScene.context.gameInfo.timeRemaining = 0
            return
        }
        
        gameScene.context.gameInfo.timeRemaining = max(0, gameScene.context.gameInfo.timeRemaining + seconds)

        notifyTimerUpdate()
    }

    private func didSuccessfullyPlacePiece() {
        SoundManager.shared.playSound(.piecePlaced)

        updateTime(by: 2)

        // Clear hint effects on successful placement
        stopHintTimer()
        stopIdleHintTimer()
        gridManager.hideHint()

        hudManager.updateScore()
        bankManager.clearSelection()
        bankManager.refreshBankIfNeeded()
        
        startIdleHintTimer()

        if bankManager.isBankEmpty() {
            handleLevelComplete()
        }
    }

    private func handleLevelComplete() {
        SoundManager.shared.playSound(.levelComplete)

        let bonus = Int(gameScene.context.gameInfo.timeRemaining)
        //        print("current score: ", gameScene.context.gameInfo.score)
        //        print("gaining a bonus of: ", bonus)
        gameScene.context.gameInfo.score += bonus
        //        print("new score: ", gameScene.context.gameInfo.score)
        gameScene.context.gameInfo.level += 1
        if gameScene.context.gameInfo.level % 4 == 0
            && gameScene.context.gameInfo.boardSize < 6
        {
            gameScene.context.gameInfo.boardSize += 1
            print("board size is now: ", gameScene.context.gameInfo.boardSize)
        }
        
        gameScene.context.stateMachine?.enter(MemorizeState.self)
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
        
        gameScene.removeAllChildren()
        gameScene.removeAction(forKey: "updateTimer")
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
    }

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
        EffectManager.shared.shakeNode(piece)
    }

    private func startGame() {
        // Start game timer here
        if let timerNode = gameScene.childNode(withName: "//circularTimer")
            as? CircularTimer
        {
            timerNode.startGameTimer(
                duration: gameScene.context.gameInfo.timeRemaining)
        }
        // start update timer
        startTimer()
        startIdleHintTimer()
    }
    
    private func handleGameOver() {
        EffectManager.shared.disableInteraction()
        stopHintTimer()
        stopIdleHintTimer()
        gridManager.hideHint()
        
        if let gridNode = gameScene.childNode(withName: "grid") as? SKSpriteNode,
           !gridNode.children.filter({ $0.name?.starts(with: "piece_") ?? false }).isEmpty {
            // Only play animation if there are pieces
            EffectManager.shared.playGameOverEffect { [weak self] in
                guard let self = self else { return }
                self.gameScene.context.stateMachine?.enter(GameOverState.self)
                SoundManager.shared.playSound(.gameOver)
            }
        } else {
            // Go directly to game over if no pieces
            self.gameScene.context.stateMachine?.enter(GameOverState.self)
            SoundManager.shared.playSound(.gameOver)
        }
    }

    func startTimer() {
        let updateTimerAction = SKAction.sequence([
            SKAction.run { [weak self] in
                guard let self = self else { return }

                // Update the circular timer with new discrete time
                if let timerNode = self.gameScene.childNode(
                    withName: "//circularTimer") as? CircularTimer
                {
                    timerNode.updateDiscreteTime(
                        newTimeRemaining: self.gameScene.context.gameInfo
                            .timeRemaining)
                }

                // Game over check
                if self.gameScene.context.gameInfo.timeRemaining <= 0 {
                    handleGameOver()
                    return
                }

                self.gameScene.context.gameInfo.timeRemaining -= 1
            },
            SKAction.wait(forDuration: 1.0),
        ])
        gameScene.run(
            SKAction.repeatForever(updateTimerAction), withKey: "updateTimer")
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
        
        idleHintTimer = Timer.scheduledTimer(withTimeInterval: GameConstants.GeneralGamePlay.idleHintWaitTime, repeats: false) { [weak self] _ in
            guard let self = self,
                  self.bankManager.getSelectedPiece() == nil else { return }
                  
            // Only show hint if no piece is currently selected
            if let randomPiece = self.bankManager.getRandomVisibleUnplacedPiece() {
                self.bankManager.selectPiece(randomPiece)
                self.gridManager.showHintForPiece(randomPiece)
            }
        }
    }

    private func stopIdleHintTimer() {
        idleHintTimer?.invalidate()
        idleHintTimer = nil
    }

    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
}
