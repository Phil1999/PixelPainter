//
//  BankManager.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/23/24.
//
import SpriteKit

class BankManager {
    weak var gameScene: GameScene?
    var bankNode: SKSpriteNode?
    var bankScrollNode: SKNode?
    
    init(gameScene: GameScene) {
        self.gameScene = gameScene
    }
    
    func createPictureBank() {
        guard let gameScene = gameScene,
              let image = UIImage(named: "sample_image") else { return }
        
        let bankHeight = gameScene.context.layoutInfo.bankHeight
        let bankWidth = gameScene.size.width
        
        let cropNode = SKCropNode()
        cropNode.position = CGPoint(x: gameScene.size.width / 2, y: bankHeight / 2)
        gameScene.addChild(cropNode)
        
        let maskNode = SKSpriteNode(color: .white, size: CGSize(width: bankWidth, height: bankHeight))
        cropNode.maskNode = maskNode
        
        bankNode = SKSpriteNode(color: .darkGray, size: CGSize(width: bankWidth, height: bankHeight))
        bankNode?.position = .zero
        bankNode?.name = "bank"
        cropNode.addChild(bankNode!)
        
        bankScrollNode = SKNode()
        bankNode?.addChild(bankScrollNode!)
        
        let gridSize = gameScene.context.layoutInfo.gridSize
        let pieceSize = CGSize(width: gridSize.width / 3, height: gridSize.height / 3)
        var pieces: [PuzzlePiece] = []
        
        let totalWidth = CGFloat(9) * (pieceSize.width + 10) - 250 // 9 pieces, 250 px spacing, subtract last spacing
        let startX = (bankWidth - totalWidth) / 2
        
        for row in 0..<3 {
            for col in 0..<3 {
                let pieceImage = cropImage(image, toRect: CGRect(x: CGFloat(col) / 3 * image.size.width,
                                                                 y: CGFloat(row) / 3 * image.size.height,
                                                                 width: image.size.width / 3,
                                                                 height: image.size.height / 3))
                let piece = PuzzlePiece(image: pieceImage,
                                        correctPosition: CGPoint(x: CGFloat(col), y: CGFloat(2 - row)),
                                        currentPosition: CGPoint(x: startX + CGFloat(pieces.count) * (pieceSize.width + 10) + pieceSize.width / 2,
                                                                 y: bankHeight / 2 - 75)) // Moved 75 pixels lower
                pieces.append(piece)
                
                let pieceNode = SKSpriteNode(texture: SKTexture(image: pieceImage))
                pieceNode.size = pieceSize
                pieceNode.position = piece.currentPosition
                pieceNode.name = "piece_\(row)_\(col)"
                bankScrollNode?.addChild(pieceNode)
                
                let border = SKShapeNode(rectOf: pieceSize)
                border.strokeColor = .white
                border.lineWidth = 2
                pieceNode.addChild(border)
            }
        }
        
        gameScene.context.gameInfo.pieces = pieces.shuffled()
        
        bankScrollNode?.position = CGPoint(x: 0, y: 0)
        
        // Set up constraints to allow horizontal scrolling
        bankScrollNode?.constraints = [
            SKConstraint.positionX(SKRange(lowerLimit: -totalWidth + bankWidth, upperLimit: 0))
        ]
        
        // Add pan gesture recognizer for scrolling
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        gameScene.view?.addGestureRecognizer(panGesture)
    }
    
    func returnToBank(piece: SKSpriteNode) {
        guard let bankScrollNode = self.bankScrollNode,
              let gameScene = self.gameScene else { return }
        
        piece.removeFromParent()
        bankScrollNode.addChild(piece)
        
        if let pieceName = piece.name,
           let pieceIndex = gameScene.context.gameInfo.pieces.firstIndex(where: { "piece_\(Int($0.correctPosition.y))_\(Int($0.correctPosition.x))" == pieceName }) {
            let originalPosition = gameScene.context.gameInfo.pieces[pieceIndex].currentPosition
            piece.position = originalPosition
            piece.zPosition = 0
        }
    }
    
    func shiftPiecesLeft() {
        guard let bankScrollNode = self.bankScrollNode else { return }
        
        let pieceSize = gameScene?.context.layoutInfo.gridSize.width ?? 0 / 3
        let spacing: CGFloat = 10
        
        for (index, child) in bankScrollNode.children.enumerated() {
            let newX = CGFloat(index) * (pieceSize + spacing) + pieceSize / 2
            child.run(SKAction.moveTo(x: newX, duration: 0.3))
        }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let bankScrollNode = bankScrollNode,
              let bankNode = bankNode else { return }
        
        let translation = gesture.translation(in: gameScene?.view)
        let newX = bankScrollNode.position.x + translation.x
        
        let scrollableWidth = CGFloat(gameScene?.context.gameInfo.pieces.count ?? 0) * (bankNode.size.width / 3 + 10)
        let minX = -scrollableWidth + bankNode.size.width
        let maxX: CGFloat = 0
        
        bankScrollNode.position.x = max(min(newX, maxX), minX)
        
        gesture.setTranslation(.zero, in: gameScene?.view)
    }
    
    private func cropImage(_ image: UIImage, toRect rect: CGRect) -> UIImage {
        let scale = image.scale
        let scaledRect = CGRect(x: rect.origin.x * scale, y: rect.origin.y * scale,
                                width: rect.size.width * scale, height: rect.size.height * scale)
        
        guard let cgImage = image.cgImage?.cropping(to: scaledRect) else {
            fatalError("Failed to crop image")
        }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
