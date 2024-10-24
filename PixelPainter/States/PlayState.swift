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
    var draggedPiece: SKSpriteNode?
    
    let gridManager: GridManager
    let bankManager: BankManager
    let hudManager: HUDManager
    
    init(gameScene: GameScene) {
        self.gameScene = gameScene
        self.gridManager = GridManager(gameScene: gameScene)
        self.bankManager = BankManager(gameScene: gameScene)
        self.hudManager = HUDManager(gameScene: gameScene)
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        setupPlayScene()
        startTimer()
    }
    
    override func willExit(to nextState: GKState) {
        gameScene.removeAllChildren()
        gameScene.removeAction(forKey: "updateTimer")
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is GameOverState.Type
    }
    
    private func setupPlayScene() {
        gridManager.createGrid()
        bankManager.createPictureBank()
        hudManager.createHUD()
        gameScene.context.gameInfo.timeRemaining = 60 // Set initial time
    }
    
    private func startTimer() {
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
        let bankLocation = bankManager.bankScrollNode?.convert(location, from: gameScene)
        let touchedNodes = bankManager.bankScrollNode?.nodes(at: bankLocation ?? .zero) ?? []
        
        for node in touchedNodes {
            if node.name?.starts(with: "piece_") == true, let pieceNode = node as? SKSpriteNode {
                if touch.tapCount == 2 {
                    handleDoubleTap(pieceNode: pieceNode)
                } else {
                    draggedPiece = pieceNode
                    draggedPiece?.zPosition = 100
                    draggedPiece?.position = gameScene.convert(pieceNode.position, from: bankManager.bankScrollNode!)
                    draggedPiece?.removeFromParent()
                    gameScene.addChild(draggedPiece!)
                }
                break
            }
        }
    }
    
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let draggedPiece = draggedPiece else { return }
        let location = touch.location(in: gameScene)
        draggedPiece.position = location
    }
    
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let draggedPiece = draggedPiece else { return }
        let dropLocation = draggedPiece.position
        
        if let gridNode = gameScene.childNode(withName: "grid") as? SKSpriteNode {
            let localPoint = gridNode.convert(dropLocation, from: gameScene)
            if gridNode.contains(localPoint) {
                if gridManager.snapToGrid(piece: draggedPiece, at: localPoint) {
                    hudManager.updateScore()
                    bankManager.shiftPiecesLeft()
                } else {
                    bankManager.returnToBank(piece: draggedPiece)
                }
            } else {
                bankManager.returnToBank(piece: draggedPiece)
            }
        }
        
        self.draggedPiece = nil
    }
    
    private func handleDoubleTap(pieceNode: SKSpriteNode) {
        if let gridNode = gameScene.childNode(withName: "grid") as? SKSpriteNode,
           let pieceName = pieceNode.name,
           let pieceIndex = gameScene.context.gameInfo.pieces.firstIndex(where: { "piece_\(Int($0.correctPosition.y))_\(Int($0.correctPosition.x))" == pieceName }) {
            let puzzlePiece = gameScene.context.gameInfo.pieces[pieceIndex]
            let correctPosition = puzzlePiece.correctPosition
            
            let pieceSize = CGSize(width: gridNode.size.width / 3, height: gridNode.size.height / 3)
            let newPosition = CGPoint(x: correctPosition.x * pieceSize.width - gridNode.size.width / 2 + pieceSize.width / 2,
                                      y: (2 - correctPosition.y) * pieceSize.height - gridNode.size.height / 2 + pieceSize.height / 2)
            
            pieceNode.removeFromParent()
            gridNode.addChild(pieceNode)
            pieceNode.run(SKAction.move(to: newPosition, duration: 0.2))
            
            gameScene.context.gameInfo.score += 1
            hudManager.updateScore()
            
            bankManager.shiftPiecesLeft()
            
            if gameScene.context.gameInfo.score == 9 {
                gameScene.context.stateMachine?.enter(GameOverState.self)
            }
        }
    }
}
