//
//  CircularTimer.Swift
//  PixelPainter
//
//  Created by Philip Lee on 11/05/24.
//
import SpriteKit

enum PPTimerState {
    case normal
    case frozen
    case overtime
    case warning
    
    var color: SKColor {
        switch self {
        case .normal:
            return .white
        case .frozen:
            return .cyan
        case .overtime:
            return .green
        case.warning:
            return .red
        }
    }
    
    var bonusColor: SKColor {
        switch self {
        case .normal:
            return .green
        case .frozen:
            return .cyan
        case .overtime:
            return .green
        case .warning:
            return .green
        }
    }
}


class PPCircularTimer: SKNode {
    private var backgroundCircle: SKShapeNode
    private var timerCircle: SKShapeNode
    private var timeLabel: SKLabelNode
    private var radius: CGFloat

    weak var delegate: PPCircularTimerDelegate?
    private var displayLink: CADisplayLink?

    // Core timer states
    private var currentTime: TimeInterval = 0
    private var totalDuration: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var isRunning = false

    // Visual states
    private var currentState: PPTimerState = .normal
    private var isFrozen = false
    private var isOvertime = false
    private var glowNode: SKShapeNode?
    private var pulseAction: SKAction?


    init(radius: CGFloat, gameScene: PPGameScene) {
        self.radius = radius

        backgroundCircle = SKShapeNode(circleOfRadius: radius)
        backgroundCircle.fillColor = .black
        backgroundCircle.strokeColor = .darkGray
        backgroundCircle.lineWidth = 4
        backgroundCircle.alpha = 0.65

        timerCircle = SKShapeNode()
        timerCircle.strokeColor = PPTimerState.normal.color
        timerCircle.lineWidth = 4

        timeLabel = SKLabelNode(fontNamed: "PPNeueMontreal-Bold")
        timeLabel.fontSize = radius * 0.7
        timeLabel.verticalAlignmentMode = .center

        super.init()

        addChild(backgroundCircle)
        addChild(timerCircle)
        addChild(timeLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startTimer(duration: TimeInterval) {
        stopTimer()

        totalDuration = duration
        currentTime = duration
        lastUpdateTime = CACurrentMediaTime()
        isRunning = true

        displayLink = CADisplayLink(
            target: self, selector: #selector(updateTimer))
        displayLink?.add(to: .current, forMode: .common)

        updateVisuals()
    }

    func stopTimer() {
        isRunning = false
        displayLink?.invalidate()
        displayLink = nil
    }

    func modifyTime(by seconds: TimeInterval) {
        guard isRunning else { return }

        let newTime = currentTime + seconds
        currentTime = max(0, newTime)  // No cap for overtime
        lastUpdateTime = CACurrentMediaTime()

        timeLabel.text = "\(Int(ceil(currentTime)))"

        if !isFrozen {
            updateVisuals()
            delegate?.timerDidUpdate(currentTime: currentTime)
        }
    }

    @objc private func updateTimer() {
        guard isRunning && !isFrozen else { return }

        let currentTimeStamp = CACurrentMediaTime()
        let deltaTime = currentTimeStamp - lastUpdateTime
        lastUpdateTime = currentTimeStamp

        currentTime = max(0, currentTime - deltaTime)

        if currentTime <= 0 {
            stopTimer()
            delegate?.timerDidComplete()
        }

        updateVisuals()
        delegate?.timerDidUpdate(currentTime: currentTime)
    }

    private func updateVisuals() {
        timeLabel.text = "\(Int(ceil(currentTime)))"

        let progress: CGFloat
        isOvertime = currentTime > totalDuration

        if isOvertime {
            let overTimeProgress = (currentTime - totalDuration) / totalDuration
            progress = 1.0 + overTimeProgress
        } else {
            progress = 1.0 - (currentTime / totalDuration)
        }

        updateTimerArc(progress: CGFloat(progress))
        updateTimerState()
    }

    private func updateTimerArc(progress: CGFloat) {
        let startAngle = CGFloat.pi / 2
        let endAngle: CGFloat

        if isOvertime {
            endAngle = startAngle + (.pi * 2 * progress)
        } else {
            endAngle = startAngle + (.pi * 2 * min(progress, 1.0))
        }

        let path = CGMutablePath()
        path.addArc(
            center: .zero,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        timerCircle.path = path
    }

    private func updateTimerState() {
        let previousState = currentState
        
        // Determine the new state
        if isFrozen {
            currentState = .frozen
        } else if isOvertime {
            currentState = .overtime
        } else if currentTime <= PPGameConstants.PPGeneralGamePlay.timeWarningThreshold {
            currentState = .warning
        } else {
            currentState = .normal
        }

        // Update visuals based on current state
        timerCircle.strokeColor = currentState.color
        timeLabel.fontColor = currentState.color

        // Handle state-specific effects
        switch currentState {
        case .overtime:
            setupOvertimeEffects()
        case .warning:
            if !isFrozen && timeLabel.action(forKey: "warningAnimation") == nil {
                triggerWarningAnimation()
                triggerWarningHaptics()
            }
        case .frozen:
            stopWarningAnimation()
        case .normal:
            removeOvertimeEffects()
            stopWarningAnimation()
        }
        
        // Stop warning animation if we're exiting the warning state
        if previousState == .warning && currentState != .warning {
            stopWarningAnimation()
        }
    }

    func setFrozen(active: Bool) {
        isFrozen = active
        updateVisuals()
    }

    private func setupOvertimeEffects() {
        // Remove existing effects
        removeOvertimeEffects()

        // glow effect
        glowNode = SKShapeNode(circleOfRadius: radius + 2)
        glowNode?.strokeColor = currentState.color
        glowNode?.lineWidth = 2
        glowNode?.alpha = 0.5

        if let glowNode = glowNode {
            // insert behind timer circle
            insertChild(glowNode, at: 0)

            PPEffectManager.shared.applyPulseEffect(to: glowNode)
        }
        PPEffectManager.shared.applyPulseEffect(to: timeLabel)
    }

    private func removeOvertimeEffects() {
        glowNode?.removeFromParent()
        glowNode = nil
        timeLabel.removeAllActions()
        timeLabel.setScale(1.0)
    }

    func setFrozenState(active: Bool) {
        if active {
            stopWarningAnimation()
        } else {
            updateTimerState()
        }
        isFrozen = active

        if active {
            // Change visuals
            currentState = .frozen
            timeLabel.fontColor = currentState.color
            timerCircle.strokeColor = .clear

            // Add frozen overlay animation
            let cooldownNode = SKShapeNode(circleOfRadius: radius)
            cooldownNode.strokeColor = currentState.color
            cooldownNode.lineWidth = 3
            cooldownNode.name = "frozen"

            let startAngle = CGFloat.pi / 2
            let path = CGMutablePath()
            path.addArc(
                center: .zero,
                radius: radius,
                startAngle: startAngle,
                endAngle: startAngle + CGFloat.pi * 2,
                clockwise: false
            )
            cooldownNode.path = path
            addChild(cooldownNode)

            // Cooldown animation
            let animate = SKAction.customAction(
                withDuration: PPGameConstants.PPPowerUpTimers.timeStopCooldown
            ) {
                node, elapsedTime in
                guard let cooldown = node as? SKShapeNode else { return }
                let progress =
                    elapsedTime / PPGameConstants.PPPowerUpTimers.timeStopCooldown
                let endAngle = startAngle + (.pi * 2 * progress)

                let newPath = CGMutablePath()
                newPath.addArc(
                    center: .zero,
                    radius: self.radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
                cooldown.path = newPath
            }

            cooldownNode.run(
                SKAction.sequence([
                    animate,
                    SKAction.removeFromParent(),
                ]))

        } else {
            // When unfreezing, we update lastUpdateTime to now
            // This effectively ignores any time that passed while frozen
            lastUpdateTime = CACurrentMediaTime()

            updateVisuals()

            // Remove frozen overlay
            childNode(withName: "frozen")?.removeFromParent()
        }
    }

    private func triggerWarningAnimation() {
        guard !isFrozen else { return }
        
        timeLabel.removeAllActions()
        
        timerCircle.strokeColor = PPTimerState.warning.color
        timeLabel.fontColor = PPTimerState.warning.color

        let scaleUp = SKAction.scale(to: 1.8, duration: 0.3)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.3)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        let repeatForever = SKAction.repeatForever(sequence)
        
        timeLabel.run(repeatForever, withKey: "warningAnimation")
    }
    
    private func triggerWarningHaptics() {
        let vibrationPattern: [TimeInterval] = [0.1, 0.1, 0.1]
        var vibrationIndex = 0
        
        func vibrateNext() {
            if vibrationIndex < vibrationPattern.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + vibrationPattern[vibrationIndex]) {
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.prepare()
                    generator.impactOccurred()
                    vibrationIndex += 1
                    vibrateNext()
                }
            }
        }
        
        vibrateNext()
    }
    
    private func stopWarningAnimation() {
        timeLabel.removeAction(forKey: "warningAnimation")
        timeLabel.setScale(1.0)
    }
}

// MARK: - Time Bonus
extension PPCircularTimer {
    func showTimeBonus(seconds: Double) {
        if !isRunning { return }
        let bonusLabel = SKLabelNode(fontNamed: "PPNeueMontreal-Bold")
        bonusLabel.text = "+\(Int(seconds))s"
        bonusLabel.fontSize = 24
        bonusLabel.fontColor = currentState.bonusColor
        bonusLabel.position = CGPoint(x: 0, y: radius - 25)
        bonusLabel.alpha = 0
        addChild(bonusLabel)

        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 0.8)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let group = SKAction.group([
            moveUp,
            SKAction.sequence([
                fadeIn, SKAction.wait(forDuration: 0.5), fadeOut,
            ]),
        ])

        bonusLabel.run(
            SKAction.sequence([
                group,
                SKAction.removeFromParent(),
            ]))
    }
}

protocol PPCircularTimerDelegate: AnyObject {
    func timerDidComplete()
    func timerDidUpdate(currentTime: TimeInterval)
}

