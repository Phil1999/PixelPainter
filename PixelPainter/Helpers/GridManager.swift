//
//  GridManager.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/23/24.
//

import SpriteKit

class GridManager {
    weak var gameScene: GameScene?

    private var hintNode: SKSpriteNode?

    init(gameScene: GameScene) {
        self.gameScene = gameScene
    }

    func createGrid() {
        guard let gameScene = gameScene else { return }

        let gridSize = gameScene.context.layoutInfo.gridSize
        let gridDimension = gameScene.context.layoutInfo.gridDimension
        let cornerRadius: CGFloat = 30

        // Create the background grid first
        let gridRect = CGRect(origin: .zero, size: gridSize)
        let path = UIBezierPath(
            roundedRect: gridRect, cornerRadius: cornerRadius)

        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = UIColor.clear.cgColor
        shape.lineWidth = 0

        UIGraphicsBeginImageContextWithOptions(
            gridSize, false, UIScreen.main.scale)
        if let context = UIGraphicsGetCurrentContext() {
            shape.render(in: context)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        let gridNode = SKSpriteNode(texture: SKTexture(image: image!))
        gridNode.position = CGPoint(
            x: gameScene.size.width / 2, y: gameScene.size.height / 2 + 15)
        gridNode.name = "grid"
        gameScene.addChild(gridNode)

        // Add the grid cells with consistent line width
        let pieceSize = gameScene.context.layoutInfo.pieceSize
        let cellColor = UIColor(
            red: 51 / 255, green: 51 / 255, blue: 51 / 255, alpha: 0.95)

        for row in 0..<gridDimension {
            for col in 0..<gridDimension {
                let frame = createRoundedCell(
                    size: pieceSize,
                    cornerRadius: cornerRadius,
                    corners: getRoundedCorners(
                        row: row, col: col, dimension: gridDimension),
                    cellColor: cellColor
                )

                frame.position = CGPoint(
                    x: CGFloat(col) * pieceSize.width - gridNode.size.width / 2
                        + pieceSize.width / 2,
                    y: CGFloat(gridDimension - 1 - row) * pieceSize.height
                        - gridNode.size.height / 2 + pieceSize.height / 2
                )
                frame.name = "frame_\(row)_\(col)"
                gridNode.addChild(frame)
            }
        }
    }

    private func getRoundedCorners(row: Int, col: Int, dimension: Int)
        -> UIRectCorner
    {
        var corners: UIRectCorner = []
        if row == 0 && col == 0 { corners.insert(.topLeft) }
        if row == 0 && col == dimension - 1 { corners.insert(.topRight) }
        if row == dimension - 1 && col == 0 { corners.insert(.bottomLeft) }
        if row == dimension - 1 && col == dimension - 1 {
            corners.insert(.bottomRight)
        }
        return corners
    }

    private func createRoundedCell(
        size: CGSize, cornerRadius: CGFloat, corners: UIRectCorner,
        cellColor: UIColor
    ) -> SKSpriteNode {
        let adjustedSize = CGSize(width: size.width, height: size.height)
        let rect = CGRect(origin: .zero, size: adjustedSize)

        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )

        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.fillColor = cellColor.cgColor
        shape.strokeColor = UIColor.gray.withAlphaComponent(0.3).cgColor
        shape.lineWidth = 1

        UIGraphicsBeginImageContextWithOptions(adjustedSize, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            shape.render(in: context)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return SKSpriteNode(texture: SKTexture(image: image!))
    }

    func tryPlacePiece(_ piece: SKSpriteNode, at point: CGPoint) -> Bool {
        // Check if game over animation is playing
        if EffectManager.shared.isPlayingGameOver {
            return false
        }

        guard let gameScene = gameScene,
            let gridNode = gameScene.childNode(withName: "grid")
                as? SKSpriteNode
        else { return false }

        let gridDimension = gameScene.context.layoutInfo.gridDimension
        let pieceSize = gameScene.context.layoutInfo.pieceSize
        let col = Int((point.x + gridNode.size.width / 2) / pieceSize.width)
        let row =
            gridDimension - 1
            - Int((point.y + gridNode.size.height / 2) / pieceSize.height)

        if row < 0 || row >= gridDimension || col < 0 || col >= gridDimension {
            return false
        }

        if let pieceName = piece.name,
            let pieceIndex = gameScene.context.gameInfo.pieces.firstIndex(
                where: {
                    "piece_\(Int($0.correctPosition.y))_\(Int($0.correctPosition.x))"
                        == pieceName
                })
        {

            let puzzlePiece = gameScene.context.gameInfo.pieces[pieceIndex]

            if puzzlePiece.correctPosition == CGPoint(x: col, y: row) {
                let targetPosition = CGPoint(
                    x: CGFloat(col) * pieceSize.width - gridNode.size.width / 2
                        + pieceSize.width / 2,
                    y: CGFloat(gridDimension - 1 - row) * pieceSize.height
                        - gridNode.size.height / 2 + pieceSize.height / 2
                )

                // Extract the original image texture from the piece's crop node structure
                if let cropNode = piece.children.first as? SKCropNode,
                    let pieceSprite = cropNode.children.first as? SKSpriteNode
                {
                    let placedPiece = SKSpriteNode(texture: pieceSprite.texture)
                    placedPiece.size = pieceSize  // This will make it larger to fit the grid
                    placedPiece.position = targetPosition
                    placedPiece.name = piece.name
                    gridNode.addChild(placedPiece)
                }

                piece.removeFromParent()

                gameScene.context.gameInfo.pieces[pieceIndex].isPlaced = true

                return true
            }
        }

        return false
    }

    func highlightGridSpace(at point: CGPoint) {
        guard let gameScene = gameScene,
            let gridNode = gameScene.childNode(withName: "grid")
                as? SKSpriteNode
        else { return }

        // Remove previous highlights
        gridNode.children.forEach { node in
            if node.name?.starts(with: "frame_") == true {
                (node as? SKSpriteNode)?.color = .darkGray
            }
        }

        let pieceSize = CGSize(
            width: gridNode.size.width / 3, height: gridNode.size.height / 3)
        let col = Int((point.x + gridNode.size.width / 2) / pieceSize.width)
        let row =
            2 - Int((point.y + gridNode.size.height / 2) / pieceSize.height)

        if row >= 0 && row <= 2 && col >= 0 && col <= 2 {
            if let frame = gridNode.childNode(withName: "frame_\(row)_\(col)")
                as? SKSpriteNode
            {
                frame.color = .blue.withAlphaComponent(0.5)
            }
        }
    }

    func isCellEmpty(at point: CGPoint) -> Bool {
        guard
            let gridNode = gameScene?.childNode(withName: "grid")
                as? SKSpriteNode
        else { return false }

        let pieceSize = CGSize(
            width: gridNode.size.width / 3, height: gridNode.size.height / 3)
        let col = Int((point.x + gridNode.size.width / 2) / pieceSize.width)
        let row =
            2 - Int((point.y + gridNode.size.height / 2) / pieceSize.height)

        // Check valid coords
        if row < 0 || row > 2 || col < 0 || col > 2 {
            return false
        }

        // Determine pos for this cell
        let cellPos = CGPoint(
            x: CGFloat(col) * pieceSize.width - gridNode.size.width / 2
                + pieceSize.width / 2,
            y: CGFloat(2 - row) * pieceSize.height - gridNode.size.height / 2
                + pieceSize.height / 2
        )

        // Check if there is already a piece in this position
        let piecesAtPosition = gridNode.children.filter { node in
            node.name?.starts(with: "piece_") == true
                && node.position == cellPos
        }

        return piecesAtPosition.isEmpty

    }

    func showHintForPiece(_ piece: SKSpriteNode) {
        guard let pieceName = piece.name,
            let gameScene = gameScene,
            let gridNode = gameScene.childNode(withName: "grid")
                as? SKSpriteNode,
            let pieceIndex = gameScene.context.gameInfo.pieces.firstIndex(
                where: {
                    "piece_\(Int($0.correctPosition.y))_\(Int($0.correctPosition.x))"
                        == pieceName
                })
        else { return }
        
        SoundManager.shared.playSound(.notifyHint)
        
        let puzzlePiece = gameScene.context.gameInfo.pieces[pieceIndex]
        let row = Int(puzzlePiece.correctPosition.y)
        let col = Int(puzzlePiece.correctPosition.x)

        if let frameNode = gridNode.childNode(withName: "frame_\(row)_\(col)")
            as? SKSpriteNode
        {

            // Create the outline for the grid piece
            let outlinePath = UIBezierPath(
                rect: CGRect(
                    x: -frameNode.size.width / 2,
                    y: -frameNode.size.height / 2,
                    width: frameNode.size.width,
                    height: frameNode.size.height
                ))

            let outlineNode = SKShapeNode(path: outlinePath.cgPath)
            outlineNode.position = .zero
            outlineNode.strokeColor = UIColor.white
            outlineNode.fillColor = .clear
            outlineNode.lineWidth = 0.2
            outlineNode.glowWidth = 4
            outlineNode.zPosition = 99999  // Above all elements
            outlineNode.name = "hint_outline"

            frameNode.addChild(outlineNode)

            hintNode = frameNode

            // Hovering hand
            let handNode = SKSpriteNode(imageNamed: "hand-down")
            handNode.size = CGSize(width: 70, height: 70)
            handNode.position = CGPoint(
                x: frameNode.position.x, y: frameNode.position.y + 20)
            handNode.zPosition = 99999
            handNode.name = "hint_hand"
            gridNode.addChild(handNode)

            // Bobbing animation
            let bobbingAction = SKAction.sequence([
                SKAction.moveBy(x: 0, y: -10, duration: 0.5),
                SKAction.moveBy(x: 0, y: 10, duration: 0.5),
            ])
            handNode.run(
                SKAction.repeatForever(bobbingAction),
                withKey: "bobbingAnimation")

            // Show the image on the grid.
            let pieceTexture = SKTexture(image: puzzlePiece.image)
            let pieceImageNode = SKSpriteNode(texture: pieceTexture)
            pieceImageNode.size = frameNode.size
            pieceImageNode.position = frameNode.position
            pieceImageNode.alpha = 0.5
            pieceImageNode.name = "hint_piece_image"
            gridNode.addChild(pieceImageNode)

        }
    }

    func hideHint() {
        guard let gameScene = gameScene,
            let gridNode = gameScene.childNode(withName: "grid")
                as? SKSpriteNode
        else { return }

        if let handNode = gridNode.childNode(withName: "hint_hand") {
            handNode.removeFromParent()
        }

        if let hintPieceNode = gridNode.childNode(withName: "hint_piece_image")
        {
            hintPieceNode.removeFromParent()
        }

        if let hintNode = hintNode,
            let hintOutline = hintNode.childNode(withName: "hint_outline")
        {
            hintOutline.removeFromParent()
        }

    }
}
