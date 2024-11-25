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
    private weak var gameScene: GameScene?

    private var isFrozen = false
    private var isWarningActive = false
    private var isRunning = false
    private var isOvertime = false

    // Track both the discrete and interpolated time
    // since we updating the time in intervals of 1s,
    // to keep the animation for the circle smooth we use interpolated time.
    private var discreteTimeRemaining: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var interpolatedTimeRemaining: TimeInterval = 0
    private var totalDuration: TimeInterval = 0

    private let frozenColor: SKColor = .cyan
    private let overtimeColor: SKColor = .orange
    private let warningColor: SKColor = .red

    private var pulseAction: SKAction?
    private var glowNode: SKShapeNode?

    init(radius: CGFloat, gameScene: GameScene) {
        self.radius = radius
        self.gameScene = gameScene

        backgroundCircle = SKShapeNode(circleOfRadius: radius)
        backgroundCircle.fillColor = .black
        backgroundCircle.strokeColor = .darkGray
        backgroundCircle.lineWidth = 4
        backgroundCircle.alpha = 0.65

        timerCircle = SKShapeNode()
        timerCircle.strokeColor = .white
        timerCircle.lineWidth = 4

        timeLabel = SKLabelNode(fontNamed: "PPNeueMontreal-Bold")
        timeLabel.fontSize = radius * 0.7
        timeLabel.verticalAlignmentMode = .center

        super.init()

        addChild(backgroundCircle)
        addChild(timerCircle)
        addChild(timeLabel)
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
        }

        // pulsing animation
        let pulseOut = SKAction.scale(to: 1.2, duration: 0.5)
        let pulseIn = SKAction.scale(by: 1.0, duration: 0.5)

        pulseAction = SKAction.repeatForever(
            SKAction.sequence([pulseOut, pulseIn]))
        glowNode?.run(pulseAction!)

        // Animate the text
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.15)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
        let wait = SKAction.wait(forDuration: 0.7)
        timeLabel.run(
            SKAction.repeatForever(
                SKAction.sequence([scaleUp, scaleDown, wait])))

    }

    private func removeOvertimeEffects() {
        glowNode?.removeFromParent()
        glowNode = nil
        timeLabel.removeAllActions()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startGameTimer(duration: TimeInterval) {
        guard !isRunning else { return }
        isRunning = true

        totalDuration = duration
        discreteTimeRemaining = duration
        interpolatedTimeRemaining = duration
        lastUpdateTime = CACurrentMediaTime()

        updateTimer()
    }

    // Call this when the game controller updates the time
    func updateDiscreteTime(newTimeRemaining: TimeInterval) {
        let wasOvertime = isOvertime
        isOvertime = newTimeRemaining > totalDuration
        discreteTimeRemaining = newTimeRemaining
        lastUpdateTime = CACurrentMediaTime()

        // Update colors and effects based on state
        if !isFrozen {
            if isOvertime {
                timerCircle.strokeColor = overtimeColor
                timeLabel.fontColor = overtimeColor
                if !wasOvertime {
                    // Just entered overtime
                    setupOvertimeEffects()
                }
            } else {
                if wasOvertime {
                    // Just exited overtime
                    removeOvertimeEffects()
                }
                if newTimeRemaining <= GameConstants.GeneralGamePlay.timeWarningThreshold && !isWarningActive {
                    triggerWarningAnimation(timeRemaining: newTimeRemaining)
                } else {
                    timerCircle.strokeColor = .white
                    timeLabel.fontColor = .white
                }
            }
        }

        // Update the label with the discrete time
        timeLabel.text = "\(Int(ceil(discreteTimeRemaining)))"
    }

    private func updateTimer() {
        guard isRunning, !isFrozen else { return }
        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - lastUpdateTime

        // Smoothly interpolate between the last discrete time and the next expected time
        interpolatedTimeRemaining = max(
            discreteTimeRemaining - deltaTime,
            discreteTimeRemaining - 1.0
        )

        // Calculate progress differently for overtime
        let progress: CGFloat
        if isOvertime {
            let overtimeProgress =
                (interpolatedTimeRemaining - totalDuration) / totalDuration
            progress = 1.0 + overtimeProgress
        } else {
            progress = 1.0 - (interpolatedTimeRemaining / totalDuration)
        }
        updateTimerCircle(progress: CGFloat(progress))

        scheduleNextUpdate()
    }

    private func scheduleNextUpdate() {
        let updateAction = SKAction.sequence([
            SKAction.wait(forDuration: 1.0 / 60.0),  // 60 fps
            SKAction.run { [weak self] in
                self?.updateTimer()
            },
        ])
        run(updateAction, withKey: "timerUpdate")
    }

    private func updateTimerCircle(progress: CGFloat) {
        let startAngle = CGFloat.pi / 2
        let endAngle: CGFloat

        if isOvertime {
            // For overtime, do multiple laps around the circle
            endAngle = startAngle + (.pi * 2 * progress)
        } else {
            endAngle = startAngle + (.pi * 2 * min(progress, 1.0))
        }

        let newPath = CGMutablePath()
        newPath.addArc(
            center: .zero,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        timerCircle.path = newPath
    }

    func stopGameTimer() {
        isRunning = false
        removeAction(forKey: "timerUpdate")
        timerCircle.path = nil
    }

    func setFrozenState(active: Bool) {
        print("Setting frozen state: \(active)")
        isFrozen = active

        if active {
            // Pause the timer update
            removeAction(forKey: "timerUpdate")
            
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
            let animate = SKAction.customAction(withDuration: GameConstants.PowerUpTimers.timeStopCooldown) {
                node, elapsedTime in
                guard let cooldown = node as? SKShapeNode else { return }
                let progress = elapsedTime / GameConstants.PowerUpTimers.timeStopCooldown
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
            // Resume the timer
            updateTimer()

            if isOvertime {
                // restart the overtime animations
                setupOvertimeEffects()
            } else {
                timerCircle.strokeColor = isWarningActive ? warningColor : .white
                timeLabel.fontColor = isWarningActive ? warningColor : .white
            }

            // Remove frozen overlay
            childNode(withName: "frozen")?.removeFromParent()
        }
    }

    private func triggerWarningAnimation(timeRemaining: TimeInterval) {
        guard !isWarningActive else { return }
        isWarningActive = true

        timerCircle.strokeColor = warningColor
        timeLabel.fontColor = warningColor

        let minDuration: Double = 0.05
        let maxDuration: Double = 0.6

        let scaleDuration =
            minDuration + (maxDuration - minDuration)
            * sin(Double(timeRemaining) / 5.0 * .pi / 2)

        let scaleUp = SKAction.scale(to: 1.5, duration: scaleDuration / 2)
        let scaleDown = SKAction.scale(to: 1.0, duration: scaleDuration / 2)
        let resetState = SKAction.run { [weak self] in
            self?.isWarningActive = false
        }
        timeLabel.run(SKAction.sequence([scaleUp, scaleDown, resetState]))
    }
}
