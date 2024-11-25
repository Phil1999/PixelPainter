//
//  ScoreCounter.swift
//  PixelPainter
//
//  Created by Philip Lee on 11/23/24.
//

import SpriteKit

class ScoreCounter: SKNode {
    private var container: SKShapeNode
    private var label: SKLabelNode
    private let minWidth: CGFloat

    init(
        text: String, fontSize: CGFloat = 24, minWidth: CGFloat = 100,
        height: CGFloat = 40
    ) {
        self.minWidth = minWidth

        // Container (pill shape)
        container = SKShapeNode()
        // only container background should be transparent
        container.fillColor = UIColor(hex: "2C2C2C").withAlphaComponent(0.75)
        container.lineWidth = 0

        // Label
        label = SKLabelNode(text: text)
        label.fontName = "PPNeueMontreal-Bold"
        label.fontSize = fontSize
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1

        super.init()

        addChild(container)
        container.addChild(label)

        updateContainer(for: text, height: height)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateText(_ newText: String) {
        label.text = newText
        updateContainer(for: newText)
    }

    private func updateContainer(for text: String, height: CGFloat = 40) {

        // Width should be based on text and includes some padding
        let textWidth = label.frame.width
        let width = max(minWidth, textWidth + 40)
        let cornerRadius = height / 2

        let rect = CGRect(
            x: -width / 2, y: -height / 2, width: width, height: height)
        let path = CGPath(
            roundedRect: rect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil)

        container.path = path
    }
}
