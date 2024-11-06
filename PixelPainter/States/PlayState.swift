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
        
        // Setup SoundManager
        SoundManager.shared.setGameScene(gameScene)
    }

    func notifyPiecePlaced() {
        didSuccessfullyPlacePiece()
    }

    private func didSuccessfullyPlacePiece() {
        SoundManager.shared.playSound(.piecePlaced)
        
        gameScene.context.gameInfo.timeRemaining += 2
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
        print("current score: ", gameScene.context.gameInfo.score)
        print("gaining a bonus of: ", bonus)
        gameScene.context.gameInfo.score += bonus
        print("new score: ", gameScene.context.gameInfo.score)
        gameScene.context.stateMachine?.enter(NextLevelState.self)
    }

    override func didEnter(from previousState: GKState?) {
        print("Entering Play State")
        setupPlayScene()
        startTimer()
    }

    override func willExit(to nextState: GKState) {
        gameScene.removeAllChildren()
        gameScene.removeAction(forKey: "updateTimer")
    }

    private func setupPlayScene() {
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

    func startTimer() {
        let updateTimerAction = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.hudManager.updateTimer()
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
