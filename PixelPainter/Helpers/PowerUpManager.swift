import SpriteKit

class PowerUpManager {
    weak var gameScene: GameScene?
    weak var playState: PlayState?
    private var powerUps: [PowerUpType: SKNode] = [:]
    private var powerUpsInCooldown: Set<PowerUpType> = []
    private var powerUpPool: [PowerUpType] = []

    // Refer to the uses from GameInfo
    private var powerUpUses: [PowerUpType: Int] {
        get { gameScene?.context.gameInfo.powerUpUses ?? [:] }
        set {
            gameScene?.context.gameInfo.powerUpUses = newValue
        }
    }

    init(gameScene: GameScene, playState: PlayState) {
        self.gameScene = gameScene
        self.playState = playState
        fillPool()
    }

    private func fillPool() {
        powerUpPool = []

        for type in PowerUpType.allCases {
            powerUpPool.append(
                contentsOf: Array(repeating: type, count: type.weight))
        }

        powerUpPool.shuffle()
    }

    func grantRandomPowerup() -> PowerUpType? {
        // Only look for valid power-ups
        let availablePowerUps = powerUpPool.filter { type in
            let currentUses = powerUpUses[type] ?? 0
            return currentUses < GameConstants.PowerUp.maxUses
        }

        guard !availablePowerUps.isEmpty else {
            // No available power-ups
            return nil
        }

        print("Current power-up pool: ", availablePowerUps)

        // Choose random powerup (weighted pool)
        let selectedPowerUp = availablePowerUps.randomElement()!
        powerUpUses[selectedPowerUp]! += 1

        return selectedPowerUp
    }

    func setupPowerUps() {
        guard let gameScene = gameScene else { return }

        let powerUpSize: CGFloat = 40

        // constants for positioning
        let centerX = gameScene.size.width / 2

        // calculate total width
        let totalSpacing: CGFloat = powerUpSize * 2
        let totalWidth = CGFloat(PowerUpType.all.count - 1) * totalSpacing

        // Center horizontally
        let startX = centerX - (totalWidth / 2)

        // Position right above the pixel bank (150 is rough estimate of bank height)
        let yPosition = 210 + powerUpSize

        for (index, type) in PowerUpType.all.enumerated() {
            let powerUp = createPowerUpNode(type: type)
            powerUp.position = CGPoint(
                x: startX + CGFloat(index) * totalSpacing, y: yPosition)
            gameScene.addChild(powerUp)
            powerUps[type] = powerUp
            updatePowerUpVisual(type: type)
        }
    }

    func resetPowerUps() {
        gameScene?.context.gameInfo.powerUpUses = Dictionary(
            uniqueKeysWithValues: PowerUpType.all.map { ($0, $0.initialUses) }
        )

        // Update visuals for all power-ups
        for type in PowerUpType.allCases {
            updatePowerUpVisual(type: type)
        }
    }

    private func createPowerUpNode(type: PowerUpType) -> SKNode {
        let container = SKNode()
        
        // Increased circle size
        let circle = SKShapeNode(circleOfRadius: 35)
        circle.fillColor = UIColor(hex: "252525").withAlphaComponent(0.9)
        circle.strokeColor = .white
        circle.lineWidth = 2
        container.addChild(circle)
        
        // Try loading the icon directly by name
        let iconName = getIconName(for: type)
        print("Attempting to load icon: \(iconName)")
        
        let iconTexture = SKTexture(imageNamed: iconName)
        let iconNode = SKSpriteNode(texture: iconTexture)
        
        // Increased icon size
        iconNode.size = CGSize(width: 40, height: 40)
        iconNode.position = CGPoint.zero
        container.addChild(iconNode)
        
        // Moved uses counter further down and made it bigger
        let usesLabel = SKLabelNode(text: "\(powerUpUses[type] ?? 0)")
        usesLabel.fontName = "PPNeueMontreal-Bold"
        usesLabel.fontSize = 20
        usesLabel.position = CGPoint(x: 0, y: -60)  // Moved further down
        usesLabel.name = "uses"
        container.addChild(usesLabel)
        
        container.name = "powerup_\(type.rawValue)"
        return container
    }
    
    private func getIconName(for type: PowerUpType) -> String {
        switch type {
        case .timeStop:
            return "snowflake"
        case .shuffle:
            return "shuffle"
        case .flash:
            return "flash"
        case .place:
            return "place"
        }
    }
    private func updatePowerUpVisual(type: PowerUpType) {
        guard let powerUpNode = powerUps[type] else { return }

        let uses = powerUpUses[type] ?? 0

        if let usesLabel = powerUpNode.childNode(withName: "uses")
            as? SKLabelNode
        {
            usesLabel.text = "\(uses)"
        }

        if let circle = powerUpNode.children.first as? SKShapeNode {
            if uses == 0 {
                // Grey out if either on cooldown or uses are 0
                circle.fillColor = .gray
                circle.strokeColor = .darkGray
                powerUpNode.alpha = 0.5
            }
        }
    }

    func handleTouch(at location: CGPoint) -> Bool {
        guard let gameScene = gameScene else { return false }

        let touchedNodes = gameScene.nodes(at: location)
        for node in touchedNodes {
            if let powerUpType = getPowerUpType(from: node.name) {
                if powerUpsInCooldown.contains(powerUpType) {
                    // Power-up is in cooldown, don't activate
                    return true
                }
                activatePowerUp(powerUpType)
                return true
            }
        }
        return false
    }

    private func getPowerUpType(from nodeName: String?) -> PowerUpType? {
        guard let name = nodeName,
            name.starts(with: "powerup_"),
            let typeString = name.split(separator: "_").last,
            let type = PowerUpType(rawValue: String(typeString))
        else {
            return nil
        }
        return type
    }

    private func activatePowerUp(_ type: PowerUpType) {
        // Check power-up has uses remaining
        guard let uses = powerUpUses[type], uses > 0 else { return }
        guard let powerUpNode = powerUps[type] else { return }
        guard let gameScene = gameScene else { return }

        // check if power-up is in cooldown
        if powerUpsInCooldown.contains(type) { return }

        switch type {
        case .timeStop:
            if uses > 1 {
                powerUpsInCooldown.insert(type)
                playState?.effectManager.cooldown(powerUpNode, duration: GameConstants.PowerUpTimers.timeStopCooldown)
            }
            
            if let timerNode = gameScene.childNode(withName: "//circularTimer") as? CircularTimer {
                timerNode.setFrozenState(active: true)
                gameScene.removeAction(forKey: "updateTimer")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.PowerUpTimers.timeStopCooldown) { [weak self] in
                    timerNode.setFrozenState(active: false)
                    self?.powerUpsInCooldown.remove(type)
                    self?.playState?.startTimer()
                }
            }
            
        case .place:
            if let selectedPiece = gameScene.context.gameInfo.pieces.first(where: { !$0.isPlaced }),
               let gridNode = gameScene.childNode(withName: "grid") as? SKSpriteNode {
                
                let correctPosition = selectedPiece.correctPosition
                let gridDimension = CGFloat(gameScene.context.layoutInfo.gridDimension)
                
                // Calculate correct position based on grid dimension
                let gridPosition = CGPoint(
                    x: CGFloat(Int(correctPosition.x)) * gridNode.size.width / gridDimension
                    - gridNode.size.width / 2 + gridNode.size.width / (2 * gridDimension),
                    y: CGFloat(Int(gridDimension - 1 - correctPosition.y))
                    * gridNode.size.height / gridDimension - gridNode.size.height / 2
                    + gridNode.size.height / (2 * gridDimension)
                )
                
                if let bankNode = playState?.bankManager.bankNode,
                   let pieceInBank = bankNode.childNode(
                    withName: "piece_\(Int(correctPosition.y))_\(Int(correctPosition.x))"
                   ) as? SKSpriteNode {
                    if playState?.gridManager.tryPlacePiece(pieceInBank, at: gridPosition) == true {
                        playState?.notifyPiecePlaced()
                    }
                }
            }
            
        case .flash:
            if uses > 1 {
                powerUpsInCooldown.insert(type)
                playState?.effectManager.cooldown(powerUpNode, duration: GameConstants.PowerUpTimers.flashCooldown)
            }
            
            if let image = gameScene.context.gameInfo.currentImage {
                let imageNode = SKSpriteNode(texture: SKTexture(image: image))
                
                let gridTopY = (gameScene.size.height / 2 + 50) +
                (gameScene.context.layoutInfo.gridSize.height / 2)
                
                // Calculate scale based on grid size
                let gridDimension = gameScene.context.layoutInfo.gridDimension
                let baseScale: CGFloat = 0.6
                let scaleAdjustment: CGFloat = baseScale * (3.0 / CGFloat(gridDimension))
                
                imageNode.setScale(scaleAdjustment)
                
                // Adjust vertical spacing based on grid size
                let verticalSpacing: CGFloat = 75 * (3.0 / CGFloat(gridDimension))
                imageNode.position = CGPoint(
                    x: gameScene.size.width / 2,
                    y: gridTopY + verticalSpacing
                )
                
                imageNode.zPosition = 9999
                gameScene.addChild(imageNode)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.PowerUpTimers.flashCooldown) {
                    imageNode.removeFromParent()
                    self.powerUpsInCooldown.remove(type)
                }
            }
            
        case .shuffle:
            if uses > 1 {
                powerUpsInCooldown.insert(type)
                playState?.effectManager.cooldown(powerUpNode, duration: 0.5)
            }
            
            if let bankManager = playState?.bankManager {
                bankManager.clearSelection()
                
                // Safely access the pieces array
                let pieces = gameScene.context.gameInfo.pieces
                let placedPieces = pieces.filter { $0.isPlaced }
                var unplacedPieces = pieces.filter { !$0.isPlaced }
                unplacedPieces.shuffle()
                
                // Combine and update
                gameScene.context.gameInfo.pieces = placedPieces + unplacedPieces
                bankManager.showNextThreePieces()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.powerUpsInCooldown.remove(type)
                }
            }
        }
        powerUpUses[type] = uses - 1
        updatePowerUpVisual(type: type)
    }
}
