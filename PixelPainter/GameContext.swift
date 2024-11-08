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
        self.layoutInfo = LayoutInfo(gridDimension: 3) // Start with 3x3
        self.gameInfo = GameInfo()
        self.scene = GameScene(context: self, size: UIScreen.main.bounds.size)
        
        configureStates()
    }
    
    func updateGridDimension(_ dimension: Int) {
        layoutInfo = LayoutInfo(gridDimension: dimension)
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
        layoutInfo = LayoutInfo(gridDimension: 3)
        stateMachine?.enter(MemorizeState.self)
    }
}

struct LayoutInfo {
    var gridDimension: Int // Number of rows/columns (3 for 3x3, 4 for 4x4, etc.)
    let gridSize = CGSize(width: 300, height: 300)
    let bankHeight: CGFloat = 150
    
    init(gridDimension: Int = 3) { // Default to 3x3
        self.gridDimension = gridDimension
    }
    
    var pieceSize: CGSize {
        return CGSize(
            width: gridSize.width / CGFloat(gridDimension),
            height: gridSize.height / CGFloat(gridDimension)
        )
    }
}

struct GameInfo {
    var currentImage: UIImage?
    var pieces: [PuzzlePiece] = []
    var score: Int = 0
    var timeRemaining: TimeInterval = 10
    var level: Int = 1
    var powerUpUses: [PowerUpType: Int] = Dictionary(
        uniqueKeysWithValues: PowerUpType.all.map { ($0, $0.initialUses )}
    )
    var boardSize = 3 //3x3, 4 = 4x4, so on...
    
}

struct PuzzlePiece: Identifiable {
    let id = UUID()
    let image: UIImage
    var correctPosition: CGPoint
    var currentPosition: CGPoint
    var isPlaced: Bool = false
}
