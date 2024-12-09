import SpriteKit

class ScoreCounter: SKNode {
    private var container: SKShapeNode
    private var scoreLabel: SKLabelNode
    private var valueLabel: SKLabelNode
    private let minWidth: CGFloat

    init(
        text: String, fontSize: CGFloat = 20, minWidth: CGFloat = 70,
        height: CGFloat = 50 // Reduced box height
    ) {
        self.minWidth = minWidth

        // Container (rounded box) with 1px white border
        container = SKShapeNode()
        container.fillColor = UIColor(hex: "2C2C2C").withAlphaComponent(0.75)
        container.strokeColor = .white
        container.lineWidth = 0.75
        container.alpha = 0.8

        // "Score" label
        scoreLabel = SKLabelNode(text: "Score")
        scoreLabel.fontName = "PPNeueMontreal-Bold"
        scoreLabel.fontSize = fontSize * 0.8 // Smaller size for label
        scoreLabel.fontColor = .lightGray
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.zPosition = 1

        // Value label (displays score)
        valueLabel = SKLabelNode(text: text)
        valueLabel.fontName = "PPNeueMontreal-Bold"
        valueLabel.fontSize = fontSize
        valueLabel.fontColor = .white
        valueLabel.verticalAlignmentMode = .center
        valueLabel.horizontalAlignmentMode = .center
        valueLabel.zPosition = 1

        super.init()

        addChild(container)
        addChild(scoreLabel)
        addChild(valueLabel)

        updateLayout(for: height)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateText(_ newText: String) {
        valueLabel.text = newText
    }

    private func updateLayout(for height: CGFloat) {
        // Calculate box dimensions
        let spacing: CGFloat = 6 // Reduced spacing
        let totalHeight = height
        let labelHeight = (totalHeight - spacing) / 2

        // Position labels
        scoreLabel.position = CGPoint(x: 0, y: labelHeight / 2)
        valueLabel.position = CGPoint(x: 0, y: -labelHeight / 2)

        // Calculate container width dynamically
        let textWidth = max(scoreLabel.frame.width, valueLabel.frame.width)
        let width = max(minWidth, textWidth + 40)
        let cornerRadius: CGFloat = 8 // Slightly smaller corner radius

        // Create rounded box path
        let rect = CGRect(
            x: -width / 2, y: -totalHeight / 2, width: width, height: totalHeight
        )
        let path = CGPath(
            roundedRect: rect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        container.path = path
    }
}

// MARK: - Score bonus animation
extension ScoreCounter {
    func showScoreBonus(points: Int) {
        let bonusLabel = SKLabelNode(fontNamed: "PPNeueMontreal-Bold")
        bonusLabel.text = "+\(points)"
        bonusLabel.fontSize = 20
        bonusLabel.fontColor = .yellow
        bonusLabel.position = CGPoint(x: 35, y: 0)
        bonusLabel.alpha = 0
        addChild(bonusLabel)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 0.8)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let group = SKAction.group([
            moveUp,
            SKAction.sequence([fadeIn, SKAction.wait(forDuration: 0.5), fadeOut])
        ])
        
        bonusLabel.run(SKAction.sequence([
            group,
            SKAction.removeFromParent()
        ]))
    }
    
    func updateScore(_ newScore: Int, withAnimation: Bool = false) {
        if withAnimation {
            let oldScore = Int(valueLabel.text ?? "0") ?? 0
            let difference = newScore - oldScore
            if difference > 0 {
                showScoreBonus(points: difference)
            }
        }
        
        updateText("\(newScore)")
    }
}
