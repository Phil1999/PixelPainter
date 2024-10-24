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
                gridNode.addChild(frame)
            }
        }
    }
    
    func snapToGrid(piece: SKSpriteNode, at point: CGPoint) -> Bool {
        guard let gameScene = gameScene,
              let gridNode = gameScene.childNode(withName: "grid") as? SKSpriteNode else { return false }
        
        let pieceSize = CGSize(width: gridNode.size.width / 3, height: gridNode.size.height / 3)
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
                
                if gameScene.context.gameInfo.score == 9 {
                    gameScene.context.stateMachine?.enter(GameOverState.self)
                }
                
                return true
            }
        }
        
        return false
    }
}
