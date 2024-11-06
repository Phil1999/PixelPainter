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
    
    // Track both the discrete and interpolated time
    // since we updating the time in intervals of 1s,
    // to keep the animation for the circle smooth we use interpolated time.
    private var discreteTimeRemaining: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var interpolatedTimeRemaining: TimeInterval = 0
    private var totalDuration: TimeInterval = 0
    
    private let frozenColor: SKColor = .cyan
    private let warningColor: SKColor = .red
    
    init(radius: CGFloat, gameScene: GameScene) {
        self.radius = radius
        self.gameScene = gameScene
        
        backgroundCircle = SKShapeNode(circleOfRadius: radius)
        backgroundCircle.fillColor = .darkGray
        backgroundCircle.strokeColor = .gray
        backgroundCircle.lineWidth = 2
        
        timerCircle = SKShapeNode()
        timerCircle.strokeColor = .white
        timerCircle.lineWidth = 4
        
        timeLabel = SKLabelNode(fontNamed: "PPNeueMontreal-Bold")
        timeLabel.fontSize = radius * 0.6
        timeLabel.verticalAlignmentMode = .center
        
        super.init()
        
        addChild(backgroundCircle)
        addChild(timerCircle)
        addChild(timeLabel)
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
        discreteTimeRemaining = newTimeRemaining
        lastUpdateTime = CACurrentMediaTime()
        
        // Check for warning state
        if newTimeRemaining <= 5 && !isWarningActive && !isFrozen {
            triggerWarningAnimation(timeRemaining: newTimeRemaining)
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
        
        // Update the visual circle based on interpolated time
        let progress = 1.0 - (interpolatedTimeRemaining / totalDuration)
        updateTimerCircle(progress: CGFloat(progress))
        
        // Continue updating
        let updateAction = SKAction.sequence([
            SKAction.wait(forDuration: 1.0 / 60.0),  // 60fps update
            SKAction.run { [weak self] in
                self?.updateTimer()
            }
        ])
        run(updateAction, withKey: "timerUpdate")
    }
    
    private func updateTimerCircle(progress: CGFloat) {
        let startAngle = CGFloat.pi / 2
        let endAngle = startAngle + (.pi * 2 * min(progress, 1.0))
        
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
        isFrozen = active
        
        if active {
            // remove the update action for our internal timer
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
            
            // Cooldown animation (should match with the actual cooldown for time freeze)
            let animate = SKAction.customAction(withDuration: 5.0) {
                node, elapsedTime in
                guard let cooldown = node as? SKShapeNode else { return }
                let progress = elapsedTime / 5.0
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
                    SKAction.removeFromParent()
                ]))
            
        } else {
            // restart the update action
            updateTimer()
            
            // Restore colors
            timerCircle.strokeColor = isWarningActive ? warningColor : .white
            timeLabel.fontColor = isWarningActive ? warningColor : .white
            
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
