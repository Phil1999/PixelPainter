import SpriteKit

class BankManager {
    weak var gameScene: GameScene?
    var bankNode: SKSpriteNode?
    private var selectedPiece: SKSpriteNode?
    private var visiblePieces: [SKSpriteNode] = []
    private var currentBatchStartIndex = 0
    private var remainingPiecesIndices: [Int] = []
    
    init(gameScene: GameScene) {
        self.gameScene = gameScene
    }
    
    func createPictureBank() {
        guard let gameScene = gameScene,
              let image = UIImage(named: "sample_image") else { return }
        
        let bankHeight = gameScene.context.layoutInfo.bankHeight
        let bankWidth = gameScene.size.width
        
        // Create bank container
        bankNode = SKSpriteNode(color: .darkGray, size: CGSize(width: bankWidth, height: bankHeight))
        bankNode?.position = CGPoint(x: gameScene.size.width / 2, y: bankHeight / 2)
        bankNode?.name = "bank"
        gameScene.addChild(bankNode!)
        
        // Setup pieces array
        let gridSize = gameScene.context.layoutInfo.gridSize
        let rows = 3 // This can be made dynamic later
        let cols = 3 // This can be made dynamic later
        let pieceSize = CGSize(width: gridSize.width / CGFloat(cols), 
                             height: gridSize.height / CGFloat(rows))
        var pieces: [PuzzlePiece] = []
        
        // Create all pieces
        for row in 0..<rows {
            for col in 0..<cols {
                let pieceImage = cropImage(image, toRect: CGRect(
                    x: CGFloat(col) / CGFloat(cols) * image.size.width,
                    y: CGFloat(row) / CGFloat(rows) * image.size.height,
                    width: image.size.width / CGFloat(cols),
                    height: image.size.height / CGFloat(rows)
                ))
                let piece = PuzzlePiece(image: pieceImage,
                                      correctPosition: CGPoint(x: CGFloat(col), y: CGFloat(row)),
                                      currentPosition: .zero,
                                      isPlaced: false)
                pieces.append(piece)
            }
        }
        
        gameScene.context.gameInfo.pieces = pieces.shuffled()
        
        // Initialize remaining pieces indices
        remainingPiecesIndices = Array(0..<pieces.count)
        currentBatchStartIndex = 0
        showNextThreePieces()
    }
    
    func showNextThreePieces() {
        guard let bankNode = bankNode,
              let gameScene = gameScene else { return }
        
        // Clear current pieces
        visiblePieces.forEach { $0.removeFromParent() }
        visiblePieces.removeAll()
        
        // Update remaining pieces indices
        remainingPiecesIndices = gameScene.context.gameInfo.pieces.enumerated()
            .filter { !$0.element.isPlaced }
            .map { $0.offset }
        
        print("Remaining pieces indices: \(remainingPiecesIndices)")
        
        if remainingPiecesIndices.isEmpty {
            return
        }
        
        let pieceSize = gameScene.context.layoutInfo.gridSize.width / 3 // This will be updated when grid size is dynamic
        let spacing: CGFloat = 20
        let totalWidth = (pieceSize + spacing) * 2
        let startX = -totalWidth / 2
        
        // Show up to 3 pieces from remaining pieces
        let piecesToShow = min(3, remainingPiecesIndices.count)
        
        print("Showing \(piecesToShow) pieces")
        
        for i in 0..<piecesToShow {
            let pieceIndex = remainingPiecesIndices[i]
            let piece = gameScene.context.gameInfo.pieces[pieceIndex]
            
            let pieceNode = SKSpriteNode(texture: SKTexture(image: piece.image))
            pieceNode.size = CGSize(width: pieceSize, height: pieceSize)
            pieceNode.position = CGPoint(x: startX + CGFloat(i) * (pieceSize + spacing),
                                       y: 0)
            pieceNode.name = "piece_\(Int(piece.correctPosition.y))_\(Int(piece.correctPosition.x))"
            pieceNode.setScale(1.0)
            
            let border = SKShapeNode(rectOf: pieceNode.size)
            border.strokeColor = .white
            border.lineWidth = 2
            pieceNode.addChild(border)
            
            bankNode.addChild(pieceNode)
            visiblePieces.append(pieceNode)
        }
    }
    
    func selectPiece(_ piece: SKSpriteNode) {
        clearSelection()
        
        selectedPiece = piece
        piece.alpha = 0.7
        
        // Add pulsing animation
        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
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
            selectedPiece.setScale(1.0)  // Reset scale explicitly
        }
        selectedPiece = nil
    }
    
    func refreshBankIfNeeded() {
        // Check if all visible pieces have been placed
        let visiblePiecesPlaced = visiblePieces.allSatisfy { $0.parent == nil }
        
        if visiblePiecesPlaced {
            // Update remaining pieces indices before showing next batch
            remainingPiecesIndices = gameScene?.context.gameInfo.pieces.enumerated()
                .filter { !$0.element.isPlaced }
                .map { $0.offset } ?? []
            
            print("Refreshing bank. Remaining pieces: \(remainingPiecesIndices.count)")
            
            if !remainingPiecesIndices.isEmpty {
                showNextThreePieces()
            }
        }
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