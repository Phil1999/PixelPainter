//
//  PlayState.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/22/24.
//

import GameplayKit
import SpriteKit
import UIKit

class PlayState: GKState {
    unowned let gameScene: GameScene
    var draggedPiece: SKSpriteNode?
    var bankNode: SKSpriteNode?
    var bankScrollNode: SKNode?

    init(gameScene: GameScene) {
        self.gameScene = gameScene
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
        createGrid()
        createPictureBank()
        createHUD()
        gameScene.context.gameInfo.timeRemaining = 60 // Set initial time
    }
    
    private func createGrid() {
        let gridNode = SKSpriteNode(color: .lightGray, size: gameScene.context.layoutInfo.gridSize)
        gridNode.position = CGPoint(x: gameScene.size.width / 2, y: gameScene.size.height / 2 + 50)
        gridNode.name = "grid"
        gameScene.addChild(gridNode)
        
        let pieceSize = gameScene.context.layoutInfo.pieceSize
        for row in 0..<3 {
            for col in 0..<3 {
                let frame = SKSpriteNode(color: .darkGray, size: CGSize(width: pieceSize.width - 2, height: pieceSize.height - 2))
                frame.position = CGPoint(x: CGFloat(col) * pieceSize.width - gridNode.size.width / 2 + pieceSize.width / 2,
                                         y: CGFloat(2 - row) * pieceSize.height - gridNode.size.height / 2 + pieceSize.height / 2)
                gridNode.addChild(frame)
            }
        }
    }
    
    private func createPictureBank() {
        guard let image = UIImage(named: "sample_image") else {
            print("Failed to load sample_image")
            return
        }
        
        let bankHeight = gameScene.context.layoutInfo.bankHeight
        let bankWidth = gameScene.size.width
        
        // Create a crop node to clip the bank contents
        let cropNode = SKCropNode()
        cropNode.position = CGPoint(x: gameScene.size.width / 2, y: bankHeight / 2)
        gameScene.addChild(cropNode)
        
        // Create a mask for the crop node
        let maskNode = SKSpriteNode(color: .white, size: CGSize(width: bankWidth, height: bankHeight))
        cropNode.maskNode = maskNode
        
        // Create the bank node
        bankNode = SKSpriteNode(color: .darkGray, size: CGSize(width: bankWidth, height: bankHeight))
        bankNode?.position = .zero
        bankNode?.name = "bank"
        cropNode.addChild(bankNode!)
        
        bankScrollNode = SKNode()
        bankNode?.addChild(bankScrollNode!)
        
        let pieceSize = gameScene.context.layoutInfo.pieceSize
        var pieces: [PuzzlePiece] = []
        
        for row in 0..<3 {
            for col in 0..<3 {
                let pieceImage = cropImage(image, toRect: CGRect(x: CGFloat(col) * pieceSize.width,
                                                                 y: CGFloat(row) * pieceSize.height,
                                                                 width: pieceSize.width,
                                                                 height: pieceSize.height))
                let piece = PuzzlePiece(image: pieceImage,
                                        correctPosition: CGPoint(x: CGFloat(col), y: CGFloat(2 - row)),
                                        currentPosition: CGPoint(x: CGFloat(pieces.count) * (pieceSize.width + 10),
                                                                 y: 0))
                pieces.append(piece)
                
                let pieceNode = SKSpriteNode(texture: SKTexture(image: pieceImage))
                pieceNode.size = pieceSize
                pieceNode.position = piece.currentPosition
                pieceNode.name = "piece_\(row)_\(col)"
                bankScrollNode?.addChild(pieceNode)
                
                // Add a border to make the pieces more visible
                let border = SKShapeNode(rectOf: pieceSize)
                border.strokeColor = .white
                border.lineWidth = 2
                pieceNode.addChild(border)
            }
        }
        
        gameScene.context.gameInfo.pieces = pieces.shuffled()
        
        let scrollableWidth = CGFloat(pieces.count) * (pieceSize.width + 10)
        bankScrollNode?.position = CGPoint(x: 0, y: 0)
        
        // Center the pieces vertically
        for child in bankScrollNode?.children ?? [] {
            child.position.y = bankHeight / 2
        }
        
        // Set up constraints to allow horizontal scrolling
        bankScrollNode?.constraints = [
            SKConstraint.positionX(SKRange(lowerLimit: -scrollableWidth + bankWidth, upperLimit: 0))
        ]
        
        // Add pan gesture recognizer for scrolling
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        gameScene.view?.addGestureRecognizer(panGesture)
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let bankScrollNode = bankScrollNode else { return }
        
        let translation = gesture.translation(in: gameScene.view)
        let newX = bankScrollNode.position.x + translation.x
        
        let scrollableWidth = CGFloat(gameScene.context.gameInfo.pieces.count) * (gameScene.context.layoutInfo.pieceSize.width + 10)
        let minX = -scrollableWidth + gameScene.size.width
        let maxX: CGFloat = 0
        
        bankScrollNode.position.x = max(min(newX, maxX), minX)
        
        gesture.setTranslation(.zero, in: gameScene.view)
    }
    
    private func createHUD() {
        let hudNode = SKNode()
        hudNode.position = CGPoint(x: 0, y: gameScene.size.height - 100)
        gameScene.addChild(hudNode)
        
        let timerLabel = SKLabelNode(text: "Time: \(Int(gameScene.context.gameInfo.timeRemaining))")
        timerLabel.fontName = "AvenirNext-Bold"
        timerLabel.fontSize = 24
        timerLabel.horizontalAlignmentMode = .left
        timerLabel.position = CGPoint(x: 20, y: 0)
        timerLabel.name = "timerLabel"
        hudNode.addChild(timerLabel)
        
        let scoreLabel = SKLabelNode(text: "Score: \(gameScene.context.gameInfo.score)")
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 24
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: gameScene.size.width - 20, y: 0)
        scoreLabel.name = "scoreLabel"
        hudNode.addChild(scoreLabel)
    }
    
    private func startTimer() {
        let updateTimerAction = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.updateTimer()
            },
            SKAction.wait(forDuration: 1.0)
        ])
        gameScene.run(SKAction.repeatForever(updateTimerAction), withKey: "updateTimer")
    }
    
    private func updateTimer() {
        gameScene.context.gameInfo.timeRemaining -= 1
        if let timerLabel = gameScene.childNode(withName: "//timerLabel") as? SKLabelNode {
            timerLabel.text = "Time: \(Int(gameScene.context.gameInfo.timeRemaining))"
        }
        
        if gameScene.context.gameInfo.timeRemaining <= 0 {
            gameScene.context.stateMachine?.enter(GameOverState.self)
        }
    }
    
    private func updateScore() {
        if let scoreLabel = gameScene.childNode(withName: "//scoreLabel") as? SKLabelNode {
            scoreLabel.text = "Score: \(gameScene.context.gameInfo.score)"
        }
    }
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: gameScene)
        let bankLocation = bankScrollNode?.convert(location, from: gameScene)
        let touchedNodes = bankScrollNode?.nodes(at: bankLocation ?? .zero) ?? []
        
        for node in touchedNodes {
            if node.name?.starts(with: "piece_") == true, let pieceNode = node as? SKSpriteNode {
                draggedPiece = pieceNode
                draggedPiece?.zPosition = 100
                draggedPiece?.position = gameScene.convert(pieceNode.position, from: bankScrollNode!)
                draggedPiece?.removeFromParent()
                gameScene.addChild(draggedPiece!)
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
                snapToGrid(piece: draggedPiece, in: gridNode, at: localPoint)
            } else {
                returnToBank(piece: draggedPiece)
            }
        }
        
        self.draggedPiece = nil
    }

    private func returnToBank(piece: SKSpriteNode) {
        if let bankScrollNode = self.bankScrollNode {
            piece.removeFromParent()
            bankScrollNode.addChild(piece)
            
            if let pieceName = piece.name,
               let pieceIndex = gameScene.context.gameInfo.pieces.firstIndex(where: { "piece_\(Int($0.correctPosition.y))_\(Int($0.correctPosition.x))" == pieceName }) {
                let originalPosition = gameScene.context.gameInfo.pieces[pieceIndex].currentPosition
                piece.position = CGPoint(x: originalPosition.x, y: bankScrollNode.frame.height / 2)
                piece.zPosition = 0
            }
        }
    }
    
    private func snapToGrid(piece: SKSpriteNode, in gridNode: SKSpriteNode, at point: CGPoint) {
        let pieceSize = gameScene.context.layoutInfo.pieceSize
        let col = Int((point.x + gridNode.size.width / 2) / pieceSize.width)
        let row = 2 - Int((point.y + gridNode.size.height / 2) / pieceSize.height)
        
        if let pieceName = piece.name,
           let pieceIndex = gameScene.context.gameInfo.pieces.firstIndex(where: { "piece_\(Int($0.correctPosition.y))_\(Int($0.correctPosition.x))" == pieceName }) {
            let puzzlePiece = gameScene.context.gameInfo.pieces[pieceIndex]
            
            if puzzlePiece.correctPosition == CGPoint(x: col, y: row) {
                let newPosition = CGPoint(x: CGFloat(col) * pieceSize.width - gridNode.size.width / 2 + pieceSize.width / 2,
                                          y: CGFloat(2 - row) * pieceSize.height - gridNode.size.height / 2 + pieceSize.height / 2)
                piece.run(SKAction.move(to: newPosition, duration: 0.2))
                piece.removeFromParent()
                gridNode.addChild(piece)
                gameScene.context.gameInfo.score += 1
                updateScore()
                
                if gameScene.context.gameInfo.score == 9 {
                    gameScene.context.stateMachine?.enter(GameOverState.self)
                }
            } else {
                returnToBank(piece: piece)
            }
        }
    }
    
    private func cropImage(_ image: UIImage, toRect rect: CGRect) -> UIImage {
        guard let cgImage = image.cgImage?.cropping(to: rect) else {
            fatalError("Failed to crop image")
        }
        return UIImage(cgImage: cgImage)
    }
}
