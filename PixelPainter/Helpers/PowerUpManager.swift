import SpriteKit
import AVFoundation

class PowerUpManager {
    weak var gameScene: GameScene?
    weak var playState: PlayState?
    private var powerUps: [PowerUpType: PowerUpIcon] = [:]
    private var powerUpsInCooldown: Set<PowerUpType> = []

    private var powerUpUses: [PowerUpType: Int] = [:]

    init(gameScene: GameScene, playState: PlayState) {
        self.gameScene = gameScene
        self.playState = playState
    }


    func setupPowerUps() {
        guard let gameScene = gameScene else { return }

        let centerX = gameScene.size.width / 2
        let spacing: CGFloat = 40 * 2.3
        let powerUpTypes = Array(powerUpUses.keys)
        let totalWidth = CGFloat(powerUpTypes.count - 1) * spacing
        let startX = centerX - (totalWidth / 2)
        let yPosition: CGFloat = 210 + 5

        for (index, type) in powerUpTypes.enumerated() {
            let uses = powerUpUses[type] ?? 0
            let powerUpIcon = PowerUpIcon(type: type, uses: uses)
            let xPos = startX + CGFloat(index) * spacing
            powerUpIcon.position = CGPoint(x: xPos, y: yPosition)
            gameScene.addChild(powerUpIcon)
            powerUps[type] = powerUpIcon
        }
    }

    func setPowerUps(_ types: [PowerUpType]) {
        // Clear existing power-ups
        powerUps.values.forEach { $0.removeFromParent() }
        powerUps.removeAll()

        powerUpUses = Dictionary(
            uniqueKeysWithValues: types.map { ($0, $0.uses) })
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
    
    private func showPowerUpAnimation(_ type: PowerUpType) {
       guard let gameScene = gameScene else { return }
       
       let iconTexture = SKTexture(imageNamed: type.iconName)
       let iconNode = SKSpriteNode(texture: iconTexture, size: CGSize(width: 80, height: 80))
       iconNode.position = CGPoint(x: gameScene.size.width/2, y: gameScene.size.height/2)
       iconNode.alpha = 0
       iconNode.zPosition = 99999
       gameScene.addChild(iconNode)
       
       let fadeIn = SKAction.fadeIn(withDuration: 0.2)
       let fadeOut = SKAction.fadeOut(withDuration: 0.2)
       let remove = SKAction.removeFromParent()
       
       iconNode.run(SKAction.sequence([fadeIn, fadeOut, remove]))
    }

    private func activatePowerUp(_ type: PowerUpType) {
        // check if timer isn't 0 before letting player use power-up
        if gameScene?.context.gameInfo.timeRemaining ?? 0 <= 0 {
            return
        }
        // Check power-up has uses remaining
        guard let uses = powerUpUses[type], uses > 0,
            let powerUpIcon = powerUps[type],
            let gameScene = gameScene
        else { return }

        // check if power-up is in cooldown
        if powerUpsInCooldown.contains(type) { return }
        
        let impactLight = UIImpactFeedbackGenerator(style: .light)
        impactLight.prepare()
        impactLight.impactOccurred()

        switch type {
        case .timeStop:
            showPowerUpAnimation(type)
            SoundManager.shared.playSound(.freeze)
            if uses > 1 {
                powerUpsInCooldown.insert(type)
                EffectManager.shared.cooldown(
                    powerUpIcon,
                    duration: GameConstants.PowerUpTimers.timeStopCooldown)
            }

            if let timerNode = gameScene.childNode(withName: "//circularTimer")
                as? CircularTimer
            {
                timerNode.setFrozenState(active: true)

                EffectManager.shared.playFreezeEffect()
                
                DispatchQueue.main.asyncAfter(
                    deadline: .now()
                        + GameConstants.PowerUpTimers.timeStopCooldown
                ) { [weak self] in
                    timerNode.setFrozenState(active: false)
                    self?.powerUpsInCooldown.remove(type)
                    EffectManager.shared.removeFreezeEffect()
                }
            }

        case .place:
            showPowerUpAnimation(type)
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
            showPowerUpAnimation(type)
            SoundManager.shared.playSound(.shutter)
            if uses > 1 {
                powerUpsInCooldown.insert(type)
                EffectManager.shared.cooldown(
                    powerUpIcon,
                    duration: GameConstants.PowerUpTimers.flashCooldown)
            }

            if let image = gameScene.context.gameInfo.currentImage {
                let imageNode = SKSpriteNode(texture: SKTexture(image: image))
                imageNode.size = gameScene.context.layoutInfo.gridSize
                imageNode.position = CGPoint(
                    x: gameScene.size.width / 2,
                    y: gameScene.size.height / 2 + 15)
                imageNode.zPosition = 9999
                imageNode.alpha = 0.6
                imageNode.name = "flashImage"
                gameScene.addChild(imageNode)

                DispatchQueue.main.asyncAfter(
                    deadline: .now() + GameConstants.PowerUpTimers.flashCooldown
                ) { [weak self] in
                    self?.removeFlashImage()
                    self?.powerUpsInCooldown.remove(type)
                }
            }

        case .shuffle:
            showPowerUpAnimation(type)
            SoundManager.shared.playSound(.shuffle)
            if uses > 1 {
                powerUpsInCooldown.insert(type)
                EffectManager.shared.cooldown(powerUpIcon, duration: 0.5)
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

                playState?.startIdleHintTimer()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.powerUpsInCooldown.remove(type)
                }
            }
        }
        powerUpUses[type] = uses - 1
        updatePowerUpVisual(type: type)
    }
    
    func removeFlashImage() {
        gameScene?.enumerateChildNodes(withName: "flashImage") { node, _ in
            node.removeFromParent()
        }
    }
}

