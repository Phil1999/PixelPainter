//
//  GameScene.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/22/24.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    unowned let context: GameContext
    var gameInfo: GameInfo { context.gameInfo }
    var layoutInfo: LayoutInfo { context.layoutInfo }
    
    var playState: PlayState?
    let queueManager = QueueManager()
    let background = Background()
    
    init(context: GameContext, size: CGSize) {
        self.context = context
        super.init(size: size)
        SoundManager.shared.setGameScene(self)
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMove(to view: SKView) {
        background.setup(screenSize: self.size)
        addChild(background)
        
        context.stateMachine?.enter(MemorizeState.self)
        
        // Enable user interaction
        self.isUserInteractionEnabled = true
        view.isMultipleTouchEnabled = true
        
        // Print initial image queue
        queueManager.printCurrentQueue()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let currentState = context.stateMachine?.currentState {
            switch currentState {
            case let playState as PlayState:
                playState.touchesBegan(touches, with: event)
                
            case let gameOverState as GameOverState:
                gameOverState.handleTouches(touches, with: event)
                
            case is MemorizeState:
                break

            default:
                break
            }
            
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let playState = context.stateMachine?.currentState as? PlayState {
            playState.touchesMoved(touches, with: event)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let playState = context.stateMachine?.currentState as? PlayState {
            playState.touchesEnded(touches, with: event)
        }
    }
}
