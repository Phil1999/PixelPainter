//
//  SoundManager.swift
//  PixelPainter
//
//  Created by Philip Lee on 11/6/24.
//

import AVFoundation
import SpriteKit

class SoundManager {
    // Implement as a singleton, use this shared SoundManager
    static let shared = SoundManager()
    
    private var soundEffects: [String: AVAudioPlayer] = [:]
    private var isSoundEnabled = true
    
    
    private init() {
        preloadSounds()
    }
    
    private func preloadSounds() {
        // Sound file names and their key(filename)
        let soundFiles = [
            "piece_placed": "piece_placed.wav",
            "level_complete": "level_complete.wav"
            
        ]
        
        // Preload each sound
        for (key, filename) in soundFiles {
            if let soundURL = Bundle.main.url(forResource: filename, withExtension: nil) {
                do {
                    let player = try AVAudioPlayer(contentsOf: soundURL)
                    player.prepareToPlay()
                    soundEffects[key] = player
                } catch {
                    print("Error loading sound \(filename): \(error.localizedDescription)")
                }
            }
        }
    }
    
    func playSound(_ sound: GameSound) {
        guard isSoundEnabled else { return }
        
        if let player = soundEffects[sound.rawValue] {
            // create copy of player for simultaenous sound effects
            if player.isPlaying {
                do {
                    let newPlayer = try AVAudioPlayer(contentsOf: player.url!)
                    newPlayer.play()
                } catch {
                    print("Error when creating new player: \(error.localizedDescription)")
                }
            } else {
                player.currentTime = 0
                player.play();
            }
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
}
