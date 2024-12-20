//
//  PPGameScene.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/22/24.
//

import GameplayKit
import SpriteKit

class PPGameScene: SKScene {
    unowned let context: PPGameContext
    var gameInfo: GameInfo { context.gameInfo }
    var layoutInfo: LayoutInfo { context.layoutInfo }

    var playState: PPPlayState?
    let queueManager = PPQueueManager()
    let background = PPBackground()

    init(context: PPGameContext, size: CGSize) {
        self.context = context
        super.init(size: size)
        PPEffectManager.shared.setGameScene(self)
        
        // Use a short delay to ensure the scene is fully loaded before playing music
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            PPSoundManager.shared.ensureBackgroundMusic()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        background.setup(screenSize: self.size)
        addChild(background)

        context.stateMachine?.enter(PPMemorizeState.self)

        // Enable user interaction
        self.isUserInteractionEnabled = true
        view.isMultipleTouchEnabled = true

        // Print initial image queue
        queueManager.printCurrentQueue()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let currentState = context.stateMachine?.currentState {
            switch currentState {
            case let playState as PPPlayState:
                playState.touchesBegan(touches, with: event)

            case let gameOverState as PPGameOverState:
                gameOverState.handleTouches(touches, with: event)

            case let memorizeState as PPMemorizeState:
                if let touch = touches.first {
                    let location = touch.location(in: self)
                    memorizeState.handleTouch(at: location)
                }

            default:
                break
            }

        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let playState = context.stateMachine?.currentState as? PPPlayState {
            playState.touchesMoved(touches, with: event)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let playState = context.stateMachine?.currentState as? PPPlayState {
            playState.touchesEnded(touches, with: event)
        }
    }
}
