//
//  GameContext.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/22/24.
//

import GameplayKit
import SwiftUI

class GameContext: ObservableObject {
    @Published private(set) var scene: GameScene!
    @Published private(set) var stateMachine: GKStateMachine?
    @Published var layoutInfo: LayoutInfo
    @Published var gameInfo: GameInfo

    init() {
        self.layoutInfo = LayoutInfo()
        self.gameInfo = GameInfo()
        self.scene = GameScene(context: self, size: UIScreen.main.bounds.size)
        
        configureStates()
    }
    
    func configureStates() {
        stateMachine = GKStateMachine(states: [
            MemorizeState(gameScene: scene),
            PlayState(gameScene: scene),
            GameOverState(gameScene: scene),
            NextLevelState(gameScene: scene)
        ])
    }
    
    func resetGame() {
        gameInfo = GameInfo()
        stateMachine?.enter(MemorizeState.self)
    }
}

struct LayoutInfo {
    let gridSize = CGSize(width: 300, height: 300)
    let pieceSize = CGSize(width: 100, height: 100)
    let bankHeight: CGFloat = 150
}

struct GameInfo {
    var currentImage: UIImage?
    var pieces: [PuzzlePiece] = []
    var score: Int = 0
    var timeRemaining: TimeInterval = 30
    var level: Int = 1
    var powerUpUses: [PowerUpType: Int] = Dictionary(
        uniqueKeysWithValues: PowerUpType.all.map { ($0, $0.initialUses )}
    )
    
}

struct PuzzlePiece: Identifiable {
    let id = UUID()
    let image: UIImage
    var correctPosition: CGPoint
    var currentPosition: CGPoint
    var isPlaced: Bool = false
}
