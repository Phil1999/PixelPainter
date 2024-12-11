import SpriteKit

class BankManager {
    weak var gameScene: GameScene?
    var bankNode: SKSpriteNode?
    private var selectedPiece: SKSpriteNode?
    private var visiblePieces: [SKSpriteNode] = []
    private var currentBatchStartIndex = 0
    private var remainingPiecesIndices: [Int] = []
    
    init(gameScene: GameScene?) {
        self.gameScene = gameScene
    }
    
    func createPictureBank() {
        guard let gameScene = gameScene,
              let image = gameScene.queueManager.getCurrentImage() else { return }
        
        let bankHeight = gameScene.context.layoutInfo.bankHeight + 100
        let bankWidth = gameScene.size.width
        
        let bankColor = UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 0)
        bankNode = SKSpriteNode(color: bankColor, size: CGSize(width: bankWidth, height: bankHeight))
        
        // Moved the bank position up by increasing the y value
        bankNode?.position = CGPoint(x: gameScene.size.width / 2, y: bankHeight/2 - 35)
        bankNode?.name = "bank"
        gameScene.addChild(bankNode!)
        
        let gridDimension = gameScene.context.layoutInfo.gridDimension
        var pieces: [PuzzlePiece] = []
        
        for row in 0..<gridDimension {
            for col in 0..<gridDimension {
                let pieceImage = cropImage(image, toRect: CGRect(
                    x: CGFloat(col) / CGFloat(gridDimension) * image.size.width,
                    y: CGFloat(row) / CGFloat(gridDimension) * image.size.height,
                    width: image.size.width / CGFloat(gridDimension),
                    height: image.size.height / CGFloat(gridDimension)
                ))
                let piece = PuzzlePiece(image: pieceImage,
                                      correctPosition: CGPoint(x: CGFloat(col), y: CGFloat(row)),
                                      currentPosition: .zero,
                                      isPlaced: false)
                pieces.append(piece)
            }
        }
        
        gameScene.context.gameInfo.pieces = pieces.shuffled()
        
        remainingPiecesIndices = Array(0..<pieces.count)
        currentBatchStartIndex = 0
        showNextThreePieces()
    }
    
    func isBankEmpty() -> Bool {
        if remainingPiecesIndices.isEmpty {
            return true
        }
        return false
    }
    
    func showNextThreePieces() {
        guard let bankNode = bankNode,
              let gameScene = gameScene else { return }
        
        visiblePieces.forEach { $0.removeFromParent() }
        visiblePieces.removeAll()
        
        let unplacedPieces = gameScene.context.gameInfo.pieces.enumerated().filter { !$0.element.isPlaced }
        remainingPiecesIndices = unplacedPieces.map { $0.offset }
        
        print("Remaining pieces indices: \(remainingPiecesIndices)")
        
        if remainingPiecesIndices.isEmpty {
            return
        }
        
        // Use a smaller size for bank pieces (300 instead of the grid's 350)
        let bankPieceSize = gameScene.context.layoutInfo.gridSize.width * (300/350) / 3
        let spacing: CGFloat = 20
        let totalWidth = (bankPieceSize + spacing) * 2
        let startX = -totalWidth / 2
        
        let piecesToShow = min(3, remainingPiecesIndices.count)
        
        print("Showing \(piecesToShow) pieces")
        
        for i in 0..<piecesToShow {
            let pieceIndex = remainingPiecesIndices[i]
            let piece = gameScene.context.gameInfo.pieces[pieceIndex]
            
            // Create the main container sprite node with smaller size
            let containerNode = SKSpriteNode(color: .clear, size: CGSize(width: bankPieceSize, height: bankPieceSize))
            containerNode.position = CGPoint(x: startX + CGFloat(i) * (bankPieceSize + spacing), y: 10)
            containerNode.name = "piece_\(Int(piece.correctPosition.y))_\(Int(piece.correctPosition.x))"
            
            // Create rounded rectangle shape for clipping
            let roundedRect = CGRect(x: -bankPieceSize/2, y: -bankPieceSize/2,
                                   width: bankPieceSize, height: bankPieceSize)
            let roundedRectPath = UIBezierPath(roundedRect: roundedRect, cornerRadius: 12)
            
            // Create a shape node for the border
            let shapeNode = SKShapeNode(path: roundedRectPath.cgPath)
            shapeNode.strokeColor = .white
            shapeNode.lineWidth = 2
            
            let glowNode = SKShapeNode(path: roundedRectPath.cgPath)
            glowNode.strokeColor = .white.withAlphaComponent(0.5)
            glowNode.lineWidth = 0.2
            glowNode.fillColor = .clear
            glowNode.glowWidth = 4
            glowNode.zPosition = -1
            
            // Create the piece sprite with the texture
            let pieceNode = SKSpriteNode(texture: SKTexture(image: piece.image))
            pieceNode.size = CGSize(width: bankPieceSize, height: bankPieceSize)
            
            // Create crop node for rounded corners
            let cropNode = SKCropNode()
            let maskNode = SKShapeNode(path: roundedRectPath.cgPath)
            maskNode.fillColor = .white
            cropNode.maskNode = maskNode
            cropNode.addChild(pieceNode)
            
            containerNode.addChild(cropNode)
            containerNode.addChild(shapeNode)
            containerNode.addChild(glowNode)
            
            bankNode.addChild(containerNode)
            visiblePieces.append(containerNode)
        }
    }
    
    func selectPiece(_ piece: SKSpriteNode) {
        clearSelection()
        
        selectedPiece = piece
        piece.alpha = 0.7
        
        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        piece.run(SKAction.repeatForever(pulseAction))
    }
    
    func getSelectedPiece() -> SKSpriteNode? {
        return selectedPiece
    }
    
    func clearSelection() {
        if let selectedPiece = selectedPiece {
            selectedPiece.alpha = 1.0
            selectedPiece.removeAllActions()
            selectedPiece.setScale(1.0)
        }
        selectedPiece = nil
    }
    
    func refreshBankIfNeeded() {
        // we should remove the pieces that are not in the bank.
        visiblePieces = visiblePieces.filter { $0.parent != nil }
        
        let visiblePiecesPlaced = visiblePieces.isEmpty
        
        if visiblePiecesPlaced {
            remainingPiecesIndices = gameScene?.context.gameInfo.pieces.enumerated()
                .filter { !$0.element.isPlaced }
                .map { $0.offset } ?? []
            
            print("Refreshing bank. Remaining pieces: \(remainingPiecesIndices.count)")
            
            if !isBankEmpty() {
                showNextThreePieces()
            }
        }
    }
    
    func getRandomVisibleUnplacedPiece() -> SKSpriteNode? {
        return visiblePieces.randomElement()
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
