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
    var effectManager: EffectManager!
    
    init(gameScene: GameScene) {
        self.gameScene = gameScene
        self.gridManager = GridManager(gameScene: gameScene)
        self.bankManager = BankManager(gameScene: gameScene)
        self.hudManager = HUDManager(gameScene: gameScene)
        self.effectManager = EffectManager(gameScene: gameScene)
        super.init()
        self.powerUpManager = PowerUpManager(
            gameScene: gameScene, playState: self)
    }

    func notifyPiecePlaced() {
        didSuccessfullyPlacePiece()
    }
    
    private func notifyTimerUpdate() {
        guard let timerNode = gameScene.childNode(withName: "//circularTimer") as? CircularTimer else { return }
        timerNode.updateDiscreteTime(newTimeRemaining: gameScene.context.gameInfo.timeRemaining)
    }
    
    func updateTime(by seconds: Double) {
        gameScene.context.gameInfo.timeRemaining = min(100, max(0, gameScene.context.gameInfo.timeRemaining + seconds))
        
        notifyTimerUpdate()
    }

    private func didSuccessfullyPlacePiece() {
        SoundManager.shared.playSound(.piecePlaced)
        
        updateTime(by: 2)

        hudManager.updateScore()
        bankManager.clearSelection()
        bankManager.refreshBankIfNeeded()

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
        if gameScene.context.gameInfo.level % 4 == 0 && gameScene.context.gameInfo.boardSize < 6{
            gameScene.context.gameInfo.boardSize += 1
            print("board size is now: ", gameScene.context.gameInfo.boardSize)
        }
        gameScene.context.stateMachine?.enter(NextLevelState.self)
    }

    override func didEnter(from previousState: GKState?) {
        print("Entering Play State")
        setupPlayScene()
        startGame()
    }

    override func willExit(to nextState: GKState) {
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
        gameScene.context.gameInfo.timeRemaining = 10 // adjust according to board size
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
        effectManager.disableInteraction()
        effectManager.shakeNode(piece)
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
    }

    func startTimer() {
        let updateTimerAction = SKAction.sequence([
            SKAction.run { [weak self] in
                guard let self = self else { return }
                 
                // Update the circular timer with new discrete time
                if let timerNode = self.gameScene.childNode(withName: "//circularTimer") as? CircularTimer {
                    timerNode.updateDiscreteTime(newTimeRemaining: self.gameScene.context.gameInfo.timeRemaining)
                }
                
                // Game over check
                if self.gameScene.context.gameInfo.timeRemaining <= 0 {
                    self.gameScene.context.stateMachine?.enter(GameOverState.self)
                    SoundManager.shared.playSound(.gameOver)
                }
                
                self.gameScene.context.gameInfo.timeRemaining -= 1
            },
            SKAction.wait(forDuration: 1.0),
        ])
        gameScene.run(SKAction.repeatForever(updateTimerAction), withKey: "updateTimer")
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
                bankManager.selectPiece(touchedPiece)
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
}
