import SpriteKit

class PowerUpManager {
    weak var gameScene: GameScene?
    weak var playState: PlayState?
    private var powerUps: [PowerUpType: PowerUpIcon] = [:]
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
        guard let selectedPowerUp = availablePowerUps.randomElement() else {
            print("No power-ups available")
            return nil
        }
        powerUpUses[selectedPowerUp, default: 0] += 1

        return selectedPowerUp
    }

    func setupPowerUps() {
        guard let gameScene = gameScene else { return }

        let centerX = gameScene.size.width / 2
        let spacing: CGFloat = 40 * 2.3
        let totalWidth = CGFloat(PowerUpType.all.count - 1) * spacing
        let startX = centerX - (totalWidth / 2)
        let yPosition: CGFloat = 210 + 40

        for (index, type) in PowerUpType.all.enumerated() {
            let uses = powerUpUses[type] ?? 0
            let powerUpIcon = PowerUpIcon(type: type, uses: uses)
            let xPos = startX + CGFloat(index) * spacing
            powerUpIcon.position = CGPoint(x: xPos, y: yPosition)
            gameScene.addChild(powerUpIcon)
            powerUps[type] = powerUpIcon
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

    
    private func updatePowerUpVisual(type: PowerUpType) {
        guard let powerUpIcon = powerUps[type] else { return }

        let uses = powerUpUses[type] ?? 0

        powerUpIcon.updateUses(uses)
        
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
        guard let uses = powerUpUses[type], uses > 0,
              let powerUpIcon = powerUps[type],
              let gameScene = gameScene else { return }

        // check if power-up is in cooldown
        if powerUpsInCooldown.contains(type) { return }

        switch type {
        case .timeStop:
            if uses > 1 {
                powerUpsInCooldown.insert(type)
                playState?.effectManager.cooldown(
                    powerUpIcon,
                    duration: GameConstants.PowerUpTimers.timeStopCooldown)
            }

            if let timerNode = gameScene.childNode(withName: "//circularTimer")
                as? CircularTimer
            {
                timerNode.setFrozenState(active: true)
                gameScene.removeAction(forKey: "updateTimer")

                DispatchQueue.main.asyncAfter(
                    deadline: .now()
                        + GameConstants.PowerUpTimers.timeStopCooldown
                ) { [weak self] in
                    timerNode.setFrozenState(active: false)
                    self?.powerUpsInCooldown.remove(type)
                    self?.playState?.startTimer()
                }
            }

        case .place:
            if let selectedPiece = gameScene.context.gameInfo.pieces.first(
                where: { !$0.isPlaced }),
                let gridNode = gameScene.childNode(withName: "grid")
                    as? SKSpriteNode
            {

                let correctPosition = selectedPiece.correctPosition
                let gridDimension = CGFloat(
                    gameScene.context.layoutInfo.gridDimension)

                // Calculate correct position based on grid dimension
                let gridPosition = CGPoint(
                    x: CGFloat(Int(correctPosition.x)) * gridNode.size.width
                        / gridDimension
                        - gridNode.size.width / 2 + gridNode.size.width
                        / (2 * gridDimension),
                    y: CGFloat(Int(gridDimension - 1 - correctPosition.y))
                        * gridNode.size.height / gridDimension - gridNode.size
                        .height / 2
                        + gridNode.size.height / (2 * gridDimension)
                )

                if let bankNode = playState?.bankManager.bankNode,
                    let pieceInBank = bankNode.childNode(
                        withName:
                            "piece_\(Int(correctPosition.y))_\(Int(correctPosition.x))"
                    ) as? SKSpriteNode
                {
                    if playState?.gridManager.tryPlacePiece(
                        pieceInBank, at: gridPosition) == true
                    {
                        playState?.notifyPiecePlaced()
                    }
                }
            }

        case .flash:
            if uses > 1 {
                powerUpsInCooldown.insert(type)
                playState?.effectManager.cooldown(
                    powerUpIcon,
                    duration: GameConstants.PowerUpTimers.flashCooldown)
            }

            if let image = gameScene.context.gameInfo.currentImage {
                let imageNode = SKSpriteNode(texture: SKTexture(image: image))
                imageNode.size = gameScene.context.layoutInfo.gridSize
                imageNode.position = CGPoint(
                    x: gameScene.size.width / 2,
                    y: gameScene.size.height / 2 + 50)
                imageNode.zPosition = 9999
                imageNode.alpha = 0.6
                gameScene.addChild(imageNode)

                DispatchQueue.main.asyncAfter(
                    deadline: .now() + GameConstants.PowerUpTimers.flashCooldown
                ) {
                    imageNode.removeFromParent()
                    self.powerUpsInCooldown.remove(type)
                }
            }

        case .shuffle:
            if uses > 1 {
                powerUpsInCooldown.insert(type)
                playState?.effectManager.cooldown(powerUpIcon, duration: 0.5)
            }

            if let bankManager = playState?.bankManager {
                bankManager.clearSelection()
                playState?.stopHintTimer()
                playState?.gridManager.hideHint()

                // Safely access the pieces array
                let pieces = gameScene.context.gameInfo.pieces
                let placedPieces = pieces.filter { $0.isPlaced }
                var unplacedPieces = pieces.filter { !$0.isPlaced }
                unplacedPieces.shuffle()

                // Combine and update
                gameScene.context.gameInfo.pieces =
                    placedPieces + unplacedPieces
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
