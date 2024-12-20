import AVFoundation
import SpriteKit

class PPPowerUpManager {
    weak var gameScene: PPGameScene?
    weak var playState: PPPlayState?
    private var powerUps: [PPPowerUpType: PPPowerUpIcon] = [:]
    private var powerUpsInCooldown: Set<PPPowerUpType> = []

    private var powerUpUses: [PPPowerUpType: Int] = [:]

    init(gameScene: PPGameScene, playState: PPPlayState) {
        self.gameScene = gameScene
        self.playState = playState
    }

    func setupPowerUps(yPosition: CGFloat? = nil) {
        guard let gameScene = gameScene else { return }

        let centerX = gameScene.size.width / 2
        let spacing: CGFloat = 40 * 2.3

        // Get selected powerups and their fixed positions
        let selectedPowerUpPositions = powerUpUses.keys.map {
            type -> (PPPowerUpType, Int) in
            return (type, PPPowerUpType.all.firstIndex(of: type) ?? 0)
        }.sorted { $0.1 < $1.1 }

        // Calculate layout
        let totalWidth = spacing
        let startX = centerX - (totalWidth / 2)

        // Display powerups
        for (index, (type, _)) in selectedPowerUpPositions.enumerated() {
            let uses = powerUpUses[type] ?? 0
            let powerUpIcon = PPPowerUpIcon(type: type, uses: uses)
            let xPos = startX + CGFloat(index) * spacing
            let yPos = yPosition ?? 210  // Use provided Y position or default
            powerUpIcon.position = CGPoint(x: xPos, y: yPos)
            gameScene.addChild(powerUpIcon)
            powerUps[type] = powerUpIcon

            if uses > 0 {
                startSmoothPulsatingAnimation(for: powerUpIcon)
            }
        }
    }

    private func startSmoothPulsatingAnimation(for node: SKNode) {
        // Remove any existing actions
        node.removeAllActions()

        // Create a single pulse action
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.15)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
        let singlePulse = SKAction.sequence([scaleUp, scaleDown])

        // Create a sequence of 3 pulses
        let threePulses = SKAction.repeat(singlePulse, count: 3)

        // Add a wait action for the remaining time to make it 4 seconds total
        let waitDuration = 4.0 - (0.3 * 3)  // 4 seconds minus the time for 3 pulses
        let wait = SKAction.wait(forDuration: waitDuration)

        // Combine the three pulses and the wait into a single sequence
        let pulseSequence = SKAction.sequence([threePulses, wait])

        // Repeat the entire sequence forever
        let repeatForever = SKAction.repeatForever(pulseSequence)

        node.run(repeatForever, withKey: "smoothPulsate")
    }

    func setPowerUps(_ types: [PPPowerUpType]) {
        // Clear existing power-ups
        powerUps.values.forEach { $0.removeFromParent() }
        powerUps.removeAll()

        powerUpUses = Dictionary(
            uniqueKeysWithValues: types.map { ($0, $0.uses) })
    }

    private func updatePowerUpVisual(type: PPPowerUpType) {
        guard let powerUpIcon = powerUps[type] else { return }

        let uses = powerUpUses[type] ?? 0

        powerUpIcon.updateUses(uses)

        if uses > 0 {
            if powerUpIcon.action(forKey: "smoothPulsate") == nil {
                startSmoothPulsatingAnimation(for: powerUpIcon)
            }
        } else {
            powerUpIcon.removeAction(forKey: "smoothPulsate")
            powerUpIcon.setScale(1.0)  // Reset to default size
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

    private func getPowerUpType(from nodeName: String?) -> PPPowerUpType? {
        guard let name = nodeName,
            name.starts(with: "powerup_"),
            let typeString = name.split(separator: "_").last,
            let type = PPPowerUpType(rawValue: String(typeString))
        else {
            return nil
        }
        return type
    }

    private func showPowerUpAnimation(_ type: PPPowerUpType) {
        guard let gameScene = gameScene else { return }

        let iconTexture = SKTexture(imageNamed: type.iconName)
        let iconNode = SKSpriteNode(
            texture: iconTexture, size: CGSize(width: 80, height: 80))
        iconNode.position = CGPoint(
            x: gameScene.size.width / 2, y: gameScene.size.height / 2)
        iconNode.alpha = 0
        iconNode.zPosition = 99999
        gameScene.addChild(iconNode)

        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()

        iconNode.run(SKAction.sequence([fadeIn, fadeOut, remove]))
    }

    private func activatePowerUp(_ type: PPPowerUpType) {
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

        let shouldApplyCooldown = uses > 1
        let impactLight = UIImpactFeedbackGenerator(style: .light)
        impactLight.prepare()
        impactLight.impactOccurred()

        switch type {
        case .timeStop:
            showPowerUpAnimation(type)
            PPSoundManager.shared.playSound(.freeze)

            if shouldApplyCooldown {
                powerUpsInCooldown.insert(type)
                PPEffectManager.shared.cooldown(
                    powerUpIcon,
                    duration: PPGameConstants.PPPowerUpTimers.timeStopCooldown)
            }

            if let timerNode = gameScene.childNode(withName: "//circularTimer")
                as? PPCircularTimer
            {
                timerNode.setFrozenState(active: true)
                PPEffectManager.shared.playFreezeEffect()

                // Always schedule the effect removal
                DispatchQueue.main.asyncAfter(
                    deadline: .now()
                        + PPGameConstants.PPPowerUpTimers.timeStopCooldown
                ) { [weak self] in
                    timerNode.setFrozenState(active: false)
                    PPEffectManager.shared.removeFreezeEffect()
                    if shouldApplyCooldown {
                        self?.powerUpsInCooldown.remove(type)
                    }
                }
            }

        case .place:
            showPowerUpAnimation(type)
            if shouldApplyCooldown {
                powerUpsInCooldown.insert(type)
                PPEffectManager.shared.cooldown(powerUpIcon, duration: 0.5)
            }

            guard
                let gridNode = gameScene.childNode(withName: "grid")
                    as? SKSpriteNode,
                let bankManager = playState?.bankManager
            else { return }

            let pieces = gameScene.context.gameInfo.pieces
            let selectedPieceName = bankManager.getSelectedPiece()?.name
            let visibleUnplacedPieces = bankManager.getVisiblePieces().filter {
                node in
                guard let pieceName = node.name else { return false }
                return pieces.contains {
                    !$0.isPlaced
                        && "piece_\(Int($0.correctPosition.y))_\(Int($0.correctPosition.x))"
                            == pieceName
                }
            }

            guard !visibleUnplacedPieces.isEmpty else { return }

            // Handle piece placement
            if visibleUnplacedPieces.count == 1,
                let pieceNode = visibleUnplacedPieces.first
            {
                if let puzzlePiece = nodeToPuzzlePiece(pieceNode, from: pieces)
                {
                    placePieceAtCorrectPosition(
                        puzzlePiece,
                        gridNode: gridNode,
                        bankNode: bankManager.bankNode)
                }
            } else {
                if let pieceNodeToPlace = visibleUnplacedPieces.first(where: {
                    $0.name != selectedPieceName
                }) {
                    if let puzzlePiece = nodeToPuzzlePiece(
                        pieceNodeToPlace, from: pieces)
                    {
                        placePieceAtCorrectPosition(
                            puzzlePiece,
                            gridNode: gridNode,
                            bankNode: bankManager.bankNode)
                    }
                }
            }

            // Always schedule cooldown removal if needed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                [weak self] in
                if shouldApplyCooldown {
                    self?.powerUpsInCooldown.remove(type)
                }
            }

        case .flash:
            showPowerUpAnimation(type)
            PPSoundManager.shared.playSound(.shutter)

            if shouldApplyCooldown {
                powerUpsInCooldown.insert(type)
                PPEffectManager.shared.cooldown(
                    powerUpIcon,
                    duration: PPGameConstants.PPPowerUpTimers.flashCooldown)
            }

            if let image = gameScene.context.gameInfo.currentImage {
                let shapeNode = SKShapeNode()
                let size = gameScene.context.layoutInfo.gridSize
                let rect = CGRect(
                    x: -size.width / 2, y: -size.height / 2,
                    width: size.width, height: size.height)
                shapeNode.path =
                    UIBezierPath(roundedRect: rect, cornerRadius: 30).cgPath
                shapeNode.fillTexture = SKTexture(image: image)
                shapeNode.fillColor = .white
                shapeNode.strokeColor = .white
                shapeNode.lineWidth = 2
                shapeNode.position = CGPoint(
                    x: gameScene.size.width / 2,
                    y: gameScene.size.height / 2 + 15)
                shapeNode.zPosition = 9999
                shapeNode.alpha = 0.6
                shapeNode.name = "flashImage"
                gameScene.addChild(shapeNode)

                // Always schedule removal of flash effect
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + PPGameConstants.PPPowerUpTimers.flashCooldown
                ) { [weak self] in
                    self?.removeFlashImage()
                    if shouldApplyCooldown {
                        self?.powerUpsInCooldown.remove(type)
                    }
                }
            }

        case .shuffle:
            showPowerUpAnimation(type)
            PPSoundManager.shared.playSound(.shuffle)

            if shouldApplyCooldown {
                powerUpsInCooldown.insert(type)
                PPEffectManager.shared.cooldown(powerUpIcon, duration: 0.5)
            }

            if let bankManager = playState?.bankManager {
                bankManager.clearSelection()
                playState?.stopHintTimer()
                playState?.gridManager.hideHint()

                let pieces = gameScene.context.gameInfo.pieces
                let placedPieces = pieces.filter { $0.isPlaced }
                var unplacedPieces = pieces.filter { !$0.isPlaced }
                unplacedPieces.shuffle()

                gameScene.context.gameInfo.pieces =
                    placedPieces + unplacedPieces
                bankManager.showNextThreePieces()
                playState?.startIdleHintTimer()

                // Always schedule cooldown removal if needed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    [weak self] in
                    if shouldApplyCooldown {
                        self?.powerUpsInCooldown.remove(type)
                    }
                }
            }
        }

        powerUpUses[type] = uses - 1
        updatePowerUpVisual(type: type)
    }

    private func placePieceAtCorrectPosition(
        _ piece: PuzzlePiece, gridNode: SKSpriteNode, bankNode: SKSpriteNode?
    ) {
        let correctPosition = piece.correctPosition
        let gridDimension = CGFloat(
            gameScene?.context.layoutInfo.gridDimension ?? 3)

        // Calculate correct position based on grid dimension
        let gridPosition = CGPoint(
            x: CGFloat(Int(correctPosition.x)) * gridNode.size.width
                / gridDimension
                - gridNode.size.width / 2 + gridNode.size.width
                / (2 * gridDimension),
            y: CGFloat(Int(gridDimension - 1 - correctPosition.y))
                * gridNode.size.height / gridDimension
                - gridNode.size.height / 2 + gridNode.size.height
                / (2 * gridDimension)
        )

        // Find and try to place the piece from the bank
        if let bankNode = bankNode,
            let pieceInBank = bankNode.childNode(
                withName:
                    "piece_\(Int(correctPosition.y))_\(Int(correctPosition.x))"
            ) as? SKSpriteNode,
            let gameScene = self.gameScene
        {
            // Store the initial position of the piece in the bank
            let initialPosition = pieceInBank.position

            // Calculate the final position in the scene's coordinate system
            let finalPosition = gameScene.convert(gridPosition, from: gridNode)

            let moveToGridPosition = SKAction.move(
                to: finalPosition, duration: 0.5)
            let sequence = SKAction.sequence([moveToGridPosition])
            sequence.timingMode = .easeInEaseOut

            // Temporarily reparent the piece to the scene for the animation
            let pieceStartPosition = bankNode.convert(
                pieceInBank.position, to: gameScene)
            pieceInBank.removeFromParent()
            gameScene.addChild(pieceInBank)
            pieceInBank.position = pieceStartPosition

            // Run the animation
            pieceInBank.run(sequence) { [weak self] in
                // After the animation completes, try to place the piece
                if self?.playState?.gridManager.tryPlacePiece(
                    pieceInBank, at: gridPosition) == true
                {
                    self?.playState?.notifyPiecePlaced(from: true)
                } else {
                    // If placement fails, move the piece back to its original position in the bank
                    pieceInBank.removeFromParent()
                    bankNode.addChild(pieceInBank)
                    pieceInBank.position = initialPosition
                }
            }
        }
    }

    private func nodeToPuzzlePiece(
        _ node: SKSpriteNode, from pieces: [PuzzlePiece]
    ) -> PuzzlePiece? {
        guard let name = node.name else { return nil }
        let components = name.split(separator: "_").compactMap { Int($0) }
        guard components.count == 2 else { return nil }

        // Match the coordinates in the name to the correct position of the puzzle piece
        return pieces.first(where: {
            Int($0.correctPosition.y) == components[0]
                && Int($0.correctPosition.x) == components[1]
        })
    }

    func removeFlashImage() {
        gameScene?.enumerateChildNodes(withName: "flashImage") { node, _ in
            node.removeFromParent()
        }
    }
}

extension PPPowerUpManager {
    func adjustPowerUpsForIPhoneSE() {
        guard let gameScene = gameScene else { return }

        let isIPhoneSE =
            !PPGameConstants.PPDeviceSizes.isIPad
            && gameScene.size.height <= PPGameConstants.PPDeviceSizes.SE_HEIGHT
        guard isIPhoneSE else { return }

        // Adjust Y-position for all power-ups
        for (_, powerUpIcon) in powerUps {
            powerUpIcon.position.y -= 30
        }
    }

    func adjustLayoutForIPad(yPosition: CGFloat) {
        guard PPGameConstants.PPDeviceSizes.isIPad else { return }

        for (_, powerUpIcon) in powerUps {
            // Keep X position the same, update only Y
            powerUpIcon.position.y = yPosition
        }
    }
}

