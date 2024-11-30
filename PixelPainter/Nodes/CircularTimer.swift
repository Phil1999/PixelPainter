//
//  CircularTimer.Swift
//  PixelPainter
//
//  Created by Philip Lee on 11/05/24.
//
import SpriteKit

class CircularTimer: SKNode {
    private var backgroundCircle: SKShapeNode
    private var timerCircle: SKShapeNode
    private var timeLabel: SKLabelNode
    private var radius: CGFloat

    weak var delegate: CircularTimerDelegate?
    private var displayLink: CADisplayLink?

    // Core timer states
    private var currentTime: TimeInterval = 0
    private var totalDuration: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var isRunning = false

    // Visual states
    private var isFrozen = false
    private var isWarningActive = false
    private var isOvertime = false
    private var glowNode: SKShapeNode?
    private var pulseAction: SKAction?

    // Colos
    private let frozenColor: SKColor = .cyan
    private let overtimeColor: SKColor = .orange
    private let warningColor: SKColor = .red
    private let normalColor: SKColor = .white

    init(radius: CGFloat, gameScene: GameScene) {
        self.radius = radius

        backgroundCircle = SKShapeNode(circleOfRadius: radius)
        backgroundCircle.fillColor = .black
        backgroundCircle.strokeColor = .darkGray
        backgroundCircle.lineWidth = 4
        backgroundCircle.alpha = 0.65

        timerCircle = SKShapeNode()
        timerCircle.strokeColor = normalColor
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
        if isFrozen {
            timerCircle.strokeColor = frozenColor
            timeLabel.fontColor = frozenColor
            return
        }

        if isOvertime {
            timerCircle.strokeColor = overtimeColor
            timeLabel.fontColor = overtimeColor
            setupOvertimeEffects()
        } else if currentTime
            <= GameConstants.GeneralGamePlay.timeWarningThreshold
        {
            timerCircle.strokeColor = warningColor
            timeLabel.fontColor = warningColor
            if !isWarningActive {
                triggerWarningAnimation()
            }
        } else {
            timerCircle.strokeColor = normalColor
            timeLabel.fontColor = normalColor
            removeOvertimeEffects()
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
        glowNode?.strokeColor = overtimeColor
        glowNode?.lineWidth = 2
        glowNode?.alpha = 0.5

        if let glowNode = glowNode {
            // insert behind timer circle
            insertChild(glowNode, at: 0)

            EffectManager.shared.applyPulseEffect(to: glowNode)
        }
        EffectManager.shared.applyPulseEffect(to: timeLabel)
    }

    private func removeOvertimeEffects() {
        glowNode?.removeFromParent()
        glowNode = nil
        timeLabel.removeAllActions()
    }

    func setFrozenState(active: Bool) {
        print("Setting frozen state: \(active)")
        isFrozen = active

        if active {
            // Change visuals
            timeLabel.fontColor = frozenColor
            timerCircle.strokeColor = .clear

            // Add frozen overlay animation
            let cooldownNode = SKShapeNode(circleOfRadius: radius)
            cooldownNode.strokeColor = frozenColor
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
                withDuration: GameConstants.PowerUpTimers.timeStopCooldown
            ) {
                node, elapsedTime in
                guard let cooldown = node as? SKShapeNode else { return }
                let progress =
                    elapsedTime / GameConstants.PowerUpTimers.timeStopCooldown
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
        guard !isWarningActive else { return }
        isWarningActive = true

        timerCircle.strokeColor = warningColor
        timeLabel.fontColor = warningColor

        let minDuration: Double = 0.05
        let maxDuration: Double = 0.6

        let scaleDuration =
            minDuration + (maxDuration - minDuration)
            * sin(Double(currentTime) / 5.0 * .pi / 2)

        let scaleUp = SKAction.scale(to: 1.5, duration: scaleDuration / 2)
        let scaleDown = SKAction.scale(to: 1.0, duration: scaleDuration / 2)
        let resetState = SKAction.run { [weak self] in
            self?.isWarningActive = false
        }
        timeLabel.run(SKAction.sequence([scaleUp, scaleDown, resetState]))
    }
}

// MARK: - Time Bonus
extension CircularTimer {
    func showTimeBonus(seconds: Double) {
        let bonusLabel = SKLabelNode(fontNamed: "PPNeueMontreal-Bold")
        bonusLabel.text = "+\(Int(seconds))s"
        bonusLabel.fontSize = 24
        bonusLabel.fontColor = .green
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

protocol CircularTimerDelegate: AnyObject {
    func timerDidComplete()
    func timerDidUpdate(currentTime: TimeInterval)
}
