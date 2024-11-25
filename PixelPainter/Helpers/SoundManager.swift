//
//  SoundManager.swift
//  PixelPainter
//
//  Created by Philip Lee on 11/6/24.
//

import SpriteKit

class SoundManager {
    // Implement as a singleton, use this shared SoundManager
    static let shared = SoundManager()
    private var soundActions: [String: SKAction] = [:]
    private var isSoundEnabled = true
    private weak var gameScene: SKScene?
    
    
    private init() {
        preloadSounds()
    }
    
    func setGameScene(_ scene: SKScene) {
        self.gameScene = scene
    }
    
    private func preloadSounds() {
        // Sound file names and their key(filename)
        let soundFiles = [
            "piece_placed": "piece_placed.wav",
            "level_complete": "level_complete.wav",
            "game_over": "game_over.wav"
            
        ]
        
        // Preload each sound
        for (key, filename) in soundFiles {
            soundActions[key] = SKAction.playSoundFileNamed(filename, waitForCompletion: false)
        }
    }
    
    func playSound(_ sound: GameSound) {
        guard isSoundEnabled,
        let scene = gameScene else { return }
        
        if let action = soundActions[sound.rawValue] {
            scene.run(action)
            
        }
    }
    
    func toggleSound() {
        isSoundEnabled.toggle()
    }
    
    func setSoundEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
    }
}

// Enum for all available game sounds
enum GameSound: String {
    case piecePlaced = "piece_placed"
    case levelComplete = "level_complete"
    case gameOver = "game_over"
}


