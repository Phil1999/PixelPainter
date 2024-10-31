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
        self.powerUpManager = PowerUpManager(gameScene: gameScene, playState: self)
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
        bankManager.createPictureBank()
        hudManager.createHUD()
        powerUpManager.setupPowerUps()
        gameScene.context.gameInfo.timeRemaining = 30
    }
    
    func handleGridPlacement(at location: CGPoint) {
        guard let gridNode = gameScene.childNode(withName: "grid") as? SKSpriteNode,
              let selectedPiece = bankManager.getSelectedPiece(),
              gridNode.contains(location) else { return }
        
        let gridLocation = gridNode.convert(location, from: gameScene)
        
        // exit early if cell not empty
        guard gridManager.isCellEmpty(at: gridLocation) else { return }
        
        if gridManager.tryPlacePiece(selectedPiece, at: gridLocation) {
            handleSuccessfulPlacement()
        } else {
            showWrongPlacementAnimation(for: selectedPiece)
        }
    }
    
    func handleSuccessfulPlacement() {
        hudManager.updateScore()
        bankManager.clearSelection()
        bankManager.refreshBankIfNeeded()
        
        if bankManager.isBankEmpty() {
            handleLevelComplete()
        }
    }
    
    private func handleLevelComplete() {
        // if time remaining is 10+ secs then add extra 10 pts
        if Int(gameScene.context.gameInfo.timeRemaining) >= 10 {
            gameScene.context.gameInfo.score += 10
        }
        gameScene.context.gameInfo.level += 1
        gameScene.context.stateMachine?.enter(NextLevelState.self)
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
            SKAction.wait(forDuration: 1.0)
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
           bankNode.contains(location) {
            let bankLocation = bankNode.convert(location, from: gameScene)
            if let touchedPiece = bankNode.nodes(at: bankLocation)
                .first(where: { $0.name?.starts(with: "piece_") == true }) as? SKSpriteNode {
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

class PowerUpManager {
    weak var gameScene: GameScene?
    weak var playState: PlayState?
    private var powerUps: [PowerUpType: SKNode] = [:]
    
    init(gameScene: GameScene, playState: PlayState) {
        self.gameScene = gameScene
        self.playState = playState
    }
    
    func setupPowerUps() {
        guard let gameScene = gameScene else { return }
        
        let powerUpTypes: [PowerUpType] = [.timeStop, .place, .flash]
        let powerUpSize: CGFloat = 40
        
        // constants for positioning
        let centerX = gameScene.size.width / 2
        
        // calculate total width
        let totalSpacing: CGFloat = powerUpSize * 2
        let totalWidth = CGFloat(powerUpTypes.count - 1) * totalSpacing
        
        // Center horizontally
        let startX = centerX - (totalWidth / 2)
        
        // Position right above the pixel bank (150 is rough estimate of bank height)
        let yPosition = 150 + powerUpSize
        
        for (index, type) in powerUpTypes.enumerated() {
            let powerUp = createPowerUpNode(type: type)
            powerUp.position = CGPoint(x: startX + CGFloat(index) * totalSpacing, y: yPosition)
            gameScene.addChild(powerUp)
            powerUps[type] = powerUp
        }
    }
    
    private func createPowerUpNode(type: PowerUpType) -> SKNode {
        let container = SKNode()
        
        let circle = SKShapeNode(circleOfRadius: 25)
        circle.fillColor = .blue
        circle.strokeColor = .white
        circle.lineWidth = 2
        container.addChild(circle)
        
        let label = SKLabelNode(text: type.rawValue.prefix(1).uppercased())
        label.fontName = "PPNeueMontreal-Bold"
        label.fontSize = 20
        label.verticalAlignmentMode = .center
        container.addChild(label)
        
        container.name = "powerup_\(type.rawValue)"
        return container
    }
    
    func handleTouch(at location: CGPoint) -> Bool {
        guard let gameScene = gameScene else { return false }
        
        let touchedNodes = gameScene.nodes(at: location)
        for node in touchedNodes {
            if let powerUpType = getPowerUpType(from: node.name) {
                activatePowerUp(powerUpType)
                return true
            }
        }
        return false
    }
    
    private func getPowerUpType(from nodeName: String?) -> PowerUpType? {
        guard let name = nodeName,
              name.starts(with: "powerup_"),
              let typeString = name.split(separator: "_").last,
              let type = PowerUpType(rawValue: String(typeString)) else {
            return nil
        }
        return type
    }
    
    private func activatePowerUp(_ type: PowerUpType) {
        switch type {
        case .timeStop:
            gameScene?.removeAction(forKey: "updateTimer")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.playState?.startTimer()
            }
        case .place:
            // Auto-place next piece correctly
            if let selectedPiece = gameScene?.context.gameInfo.pieces.first(where: { !$0.isPlaced }),
               let gridNode = gameScene?.childNode(withName: "grid") as? SKSpriteNode {
                let correctPosition = selectedPiece.correctPosition
                
                // Calculate the appropriate grid position
                let gridPosition = CGPoint(
                    x: CGFloat(Int(correctPosition.x)) * gridNode.size.width/3 - gridNode.size.width/2 + gridNode.size.width/6,
                    y: CGFloat(2 - Int(correctPosition.y)) * gridNode.size.height/3 - gridNode.size.height/2 + gridNode.size.height/6
                )
                
                if let bankNode = playState?.bankManager.bankNode,
                   let pieceInBank = bankNode.childNode(withName: "piece_\(Int(correctPosition.y))_\(Int(correctPosition.x))") as? SKSpriteNode {
                    if playState?.gridManager.tryPlacePiece(pieceInBank, at: gridPosition) == true {
                        // Handle successful placement same as manual placement
                        playState?.handleSuccessfulPlacement()
                        
                    }
                }
            }
        case .flash:
            // Show original image briefly
            if let image = gameScene?.context.gameInfo.currentImage {
                let imageNode = SKSpriteNode(texture: SKTexture(image: image))
                
                imageNode.position = CGPoint(x: (gameScene?.size.width ?? 0) / 2,
                                          y: (gameScene?.size.height ?? 0) / 2 + 50)
                gameScene?.addChild(imageNode)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    imageNode.removeFromParent()
                }
            }
        }
    }
}
