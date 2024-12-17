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
                    // Create the main container sprite node with grid cell size
                    let containerNode = SKSpriteNode(
                        color: .clear, size: pieceSize)
                    containerNode.position = targetPosition
                    containerNode.name = piece.name

                    // Create rounded rectangle path for the mask
                    let roundedRect = CGRect(
                        x: -pieceSize.width / 2, y: -pieceSize.height / 2,
                        width: pieceSize.width, height: pieceSize.height)
                    
                    // Get the corners that should be rounded based on position
                    var corners: UIRectCorner = []
                    if row == 0 && col == 0 {
                        corners.insert(.bottomLeft)
                    } else if row == 0 && col == gridDimension - 1 {
                        corners.insert(.bottomRight)
                    } else if row == gridDimension - 1 && col == 0 {
                        corners.insert(.topLeft)
                    } else if row == gridDimension - 1 && col == gridDimension - 1 {
                        corners.insert(.topRight)
                    }

                    // Create rounded path only for corner pieces
                    let cornerRadius: CGFloat = 30
                    let roundedRectPath =
                        !corners.isEmpty
                        ? UIBezierPath(
                            roundedRect: roundedRect, byRoundingCorners: corners,
                            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
                        ).cgPath : UIBezierPath(rect: roundedRect).cgPath

                    // Create crop node for the rounded corners
                    let newCropNode = SKCropNode()
                    let maskNode = SKShapeNode(path: roundedRectPath)
                    maskNode.fillColor = .white
                    newCropNode.maskNode = maskNode

                    // Create the piece sprite with the original texture at grid cell size
                    let pieceNode = SKSpriteNode(texture: pieceSprite.texture)
                    pieceNode.size = pieceSize

                    // Assemble the piece
                    newCropNode.addChild(pieceNode)
                    containerNode.addChild(newCropNode)

                    gridNode.addChild(containerNode)
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
        let gridDimension = gameScene.context.layoutInfo.gridDimension

        if let frameNode = gridNode.childNode(withName: "frame_\(row)_\(col)")
            as? SKSpriteNode
        {
            // Create the outline with proper corner rounding
            let outlineNode = SKShapeNode()
            let rect = CGRect(
                x: -frameNode.size.width / 2,
                y: -frameNode.size.height / 2,
                width: frameNode.size.width,
                height: frameNode.size.height
            )

            // Determine which corner should be rounded based on position
            var corners: UIRectCorner = []
            if row == 0 && col == 0 {
                corners.insert(.bottomLeft)
            } else if row == 0 && col == gridDimension - 1 {
                corners.insert(.bottomRight)
            } else if row == gridDimension - 1 && col == 0 {
                corners.insert(.topLeft)
            } else if row == gridDimension - 1 && col == gridDimension - 1 {
                corners.insert(.topRight)
            }

            // Create rounded path only for corner pieces
            let path =
                !corners.isEmpty
                ? UIBezierPath(
                    roundedRect: rect, byRoundingCorners: corners,
                    cornerRadii: CGSize(width: 30, height: 30)
                ).cgPath : UIBezierPath(rect: rect).cgPath

            outlineNode.path = path
            outlineNode.strokeColor = UIColor.white
            outlineNode.fillColor = .clear
            outlineNode.lineWidth = 0.2
            outlineNode.glowWidth = 4
            outlineNode.zPosition = 99999
            outlineNode.name = "hint_outline"

            frameNode.addChild(outlineNode)
            hintNode = frameNode

            // Hovering hand
            let handNode = SKSpriteNode(imageNamed: "hand-down")
            handNode.size = CGSize(width: 50, height: 50)
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

            let pieceShapeNode = SKShapeNode()
            pieceShapeNode.path = path
            pieceShapeNode.fillTexture = SKTexture(image: puzzlePiece.image)
            pieceShapeNode.fillColor = .white
            pieceShapeNode.strokeColor = .clear
            pieceShapeNode.alpha = 0.3
            pieceShapeNode.name = "hint_piece_image"
            pieceShapeNode.position = frameNode.position
            gridNode.addChild(pieceShapeNode)
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


