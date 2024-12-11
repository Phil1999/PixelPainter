//
//  PowerUpIcon.swift
//  PixelPainter
//
//  Created by Philip Lee on 11/23/24.
//

import SpriteKit

class PowerUpIcon: SKNode {
    private var mainCircle: SKShapeNode
    private var iconNode: SKSpriteNode
    private var usesBubble: SKShapeNode
    private var usesLabel: SKLabelNode

    private let mainRadius: CGFloat = 28
    private let bubbleRadius: CGFloat = 12
    private let iconSize = CGSize(width: 40, height: 40)

    init(type: PowerUpType, uses: Int, minimal: Bool = false) {
        let iconName = type.iconName
        
        let glowNode = SKShapeNode(circleOfRadius: mainRadius)
        glowNode.fillColor = .clear
        glowNode.strokeColor = type.themeColor
        glowNode.glowWidth = 10
        glowNode.alpha = 0.3 // Adjust transparency as needed

        // Main circle
        mainCircle = SKShapeNode(circleOfRadius: mainRadius)
        mainCircle.fillColor = UIColor(hex: "252525").withAlphaComponent(0.95)
        mainCircle.strokeColor = type.themeColor
        mainCircle.lineWidth = 1
        mainCircle.glowWidth = 0.2

        // Icon
        iconNode = SKSpriteNode(texture: SKTexture(imageNamed: iconName))
        iconNode.size = iconSize

        // usesBubble
        usesBubble = SKShapeNode(circleOfRadius: bubbleRadius)
        usesBubble.fillColor = UIColor(hex: "1A1A1A")
        usesBubble.strokeColor = UIColor(hex: "404040")
        usesBubble.lineWidth = 1
        usesBubble.position = CGPoint(
            x: mainRadius * 0.7,  // bottom right
            y: -mainRadius * 0.7
        )

        // usesLabel
        usesLabel = SKLabelNode(text: "\(uses)")
        usesLabel.fontName = "PPNeueMontreal-Bold"
        usesLabel.fontSize = 14
        usesLabel.fontColor = .white
        usesLabel.verticalAlignmentMode = .center
        usesLabel.horizontalAlignmentMode = .center
        usesLabel.position = usesBubble.position
        usesLabel.name = "uses"

        super.init()
        
        // Incase we'd like a minimal version of the icon with just the icon and circle
        if minimal {
            addChild(glowNode)
            addChild(mainCircle)
            addChild(iconNode)
        } else {
            addChild(glowNode)
            addChild(mainCircle)
            addChild(iconNode)
            addChild(usesBubble)
            addChild(usesLabel)
        }

        self.name = "powerup_\(type.rawValue)"
        
        // set initial state
        updateUses(uses)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateUses(_ uses: Int) {
        usesLabel.text = "\(uses)"

        if uses == 0 {
            // Grey out state
            mainCircle.fillColor = .gray
            usesBubble.fillColor = UIColor.gray.withAlphaComponent(0.8)
            usesBubble.strokeColor = UIColor.gray.withAlphaComponent(0.4)
            alpha = 0.5
        } else {
            // Normal state
            mainCircle.fillColor = UIColor(hex: "252525").withAlphaComponent(
                0.9)
            usesBubble.fillColor = UIColor(hex: "1A1A1A")
            usesBubble.strokeColor = UIColor(hex: "404040")
            alpha = 1.0
        }

        // animation when the uses change
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        usesBubble.run(SKAction.sequence([scaleUp, scaleDown]))
        usesLabel.run(SKAction.sequence([scaleUp, scaleDown]))
    }

}
