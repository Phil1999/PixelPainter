//
//  GridManager.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/23/24.
//

import SpriteKit

class GridManager {
    weak var gameScene: GameScene?
    
    init(gameScene: GameScene) {
        self.gameScene = gameScene
    }
    
    func createGrid() {
        guard let gameScene = gameScene else { return }
        
        let gridNode = SKSpriteNode(color: .lightGray, size: gameScene.context.layoutInfo.gridSize)
        gridNode.position = CGPoint(x: gameScene.size.width / 2, y: gameScene.size.height / 2 + 50)
        gridNode.name = "grid"
        gameScene.addChild(gridNode)
        
        let pieceSize = CGSize(width: gridNode.size.width / 3, height: gridNode.size.height / 3)
        for row in 0..<3 {
            for col in 0..<3 {
                let frame = SKSpriteNode(color: .darkGray, size: CGSize(width: pieceSize.width - 2, height: pieceSize.height - 2))
                frame.position = CGPoint(x: CGFloat(col) * pieceSize.width - gridNode.size.width / 2 + pieceSize.width / 2,
                                       y: CGFloat(2 - row) * pieceSize.height - gridNode.size.height / 2 + pieceSize.height / 2)
                frame.name = "frame_\(row)_\(col)"
                gridNode.addChild(frame)
            }
        }
    }
    
    func tryPlacePiece(_ piece: SKSpriteNode, at point: CGPoint) -> Bool {
        guard let gameScene = gameScene,
              let gridNode = gameScene.childNode(withName: "grid") as? SKSpriteNode else { return false }
        
        let pieceSize = CGSize(width: gridNode.size.width / 3, height: gridNode.size.height / 3)
        let col = Int((point.x + gridNode.size.width / 2) / pieceSize.width)
        let row = 2 - Int((point.y + gridNode.size.height / 2) / pieceSize.height)
        
        if row < 0 || row > 2 || col < 0 || col > 2 {
            return false
        }
        
        if let pieceName = piece.name,
           let pieceIndex = gameScene.context.gameInfo.pieces.firstIndex(where: { "piece_\(Int($0.correctPosition.y))_\(Int($0.correctPosition.x))" == pieceName }) {
            
            let puzzlePiece = gameScene.context.gameInfo.pieces[pieceIndex]
            
            if puzzlePiece.correctPosition == CGPoint(x: col, y: row) {
                let targetPosition = CGPoint(x: CGFloat(col) * pieceSize.width - gridNode.size.width / 2 + pieceSize.width / 2,
                                           y: CGFloat(2 - row) * pieceSize.height - gridNode.size.height / 2 + pieceSize.height / 2)
                
                // Create a copy of the piece for the grid with exact size
                let placedPiece = SKSpriteNode(texture: piece.texture)
                placedPiece.size = pieceSize
                placedPiece.name = piece.name
                placedPiece.setScale(1.0) // Ensure proper scale
                
                // Add the piece to the grid at the correct position
                gridNode.addChild(placedPiece)
                placedPiece.position = targetPosition
                
                // Remove the original piece from the bank
                piece.removeFromParent()
                
                // Update the piece's status to placed
                gameScene.context.gameInfo.pieces[pieceIndex].isPlaced = true
                gameScene.context.gameInfo.score += 15
                
                return true
            }
        }
        
        return false
    }
    
    func highlightGridSpace(at point: CGPoint) {
        guard let gameScene = gameScene,
              let gridNode = gameScene.childNode(withName: "grid") as? SKSpriteNode else { return }
        
        // Remove previous highlights
        gridNode.children.forEach { node in
            if node.name?.starts(with: "frame_") == true {
                (node as? SKSpriteNode)?.color = .darkGray
            }
        }
        
        let pieceSize = CGSize(width: gridNode.size.width / 3, height: gridNode.size.height / 3)
        let col = Int((point.x + gridNode.size.width / 2) / pieceSize.width)
        let row = 2 - Int((point.y + gridNode.size.height / 2) / pieceSize.height)
        
        if row >= 0 && row <= 2 && col >= 0 && col <= 2 {
            if let frame = gridNode.childNode(withName: "frame_\(row)_\(col)") as? SKSpriteNode {
                frame.color = .blue.withAlphaComponent(0.5)
            }
        }
    }
    
    func isCellEmpty(at point: CGPoint) -> Bool {
        guard let gridNode = gameScene?.childNode(withName: "grid") as? SKSpriteNode else { return false }
        
        let pieceSize = CGSize(width: gridNode.size.width / 3, height: gridNode.size.height / 3)
        let col = Int((point.x + gridNode.size.width / 2) / pieceSize.width)
        let row = 2 - Int((point.y + gridNode.size.height / 2) / pieceSize.height)
        
        // Check valid coords
        if row < 0 || row > 2 || col < 0 || col > 2 {
            return false
        }
        
        // Determine pos for this cell
        let cellPos = CGPoint(
            x: CGFloat(col) * pieceSize.width - gridNode.size.width / 2 + pieceSize.width / 2,
            y: CGFloat(2 - row) * pieceSize.height - gridNode.size.height / 2 + pieceSize.height / 2
        )
        
        // Check if there is already a piece in this position
        let piecesAtPosition = gridNode.children.filter { node in
            node.name?.starts(with: "piece_") == true &&
            node.position == cellPos
        }
        
        return piecesAtPosition.isEmpty
    
        
    }
}
