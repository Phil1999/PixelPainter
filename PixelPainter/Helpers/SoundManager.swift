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
    private var soundActions: [String: SKAction] = [:]
    private var isSoundEnabled = true
    private weak var gameScene: SKScene?

    private var backgroundMusicPlayer: AVAudioPlayer?
    private var isBgMusicEnabled = true

    private init() {
        preloadSounds()
    }

    func setGameScene(_ scene: SKScene) {
        self.gameScene = scene
    }

    private func preloadSounds() {
        // Sound file names and their associated filename
        let soundFiles = [
            "piece_placed": "piece_placed.wav",
            "incorrect_piece_placed": "incorrect-placement.mp3",
            "level_complete": "level_complete.wav",
            "game_over_incomplete_puzzle": "game-end-incomplete-puzzle.mp3",
            "game_over_no_puzzle": "game-over-no-puzzle.wav",
            "freeze":"freeze.mp3",
            "shutter-click":"shutter-click.mp3",
            "shuffle":"shuffle.mp3",
            "select": "select.mp3",
            "deselect": "deselect.mp3",
            "confirm": "confirm.mp3",
            "notify_hint": "hint-notification.mp3"
        ]

        // Preload each sound
        for (key, filename) in soundFiles {
            soundActions[key] = SKAction.playSoundFileNamed(
                filename, waitForCompletion: false)
        }
    }

    func playSound(_ sound: GameSound) {
        guard isSoundEnabled,
            let scene = gameScene
        else { return }

        if let action = soundActions[sound.rawValue] {
            scene.run(action)

        }
    }

    func playBackgroundMusic(
        _ fileName: String, fileType: String = "mp3", loop: Bool = true
    ) {
        guard isBgMusicEnabled else { return }

        if backgroundMusicPlayer?.isPlaying == true {
            return  // Avoid reloading and restarting if already playing
        }

        if let url = Bundle.main.url(
            forResource: fileName, withExtension: fileType)
        {
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
                backgroundMusicPlayer?.numberOfLoops = loop ? -1 : 0  // Infinite loop if true
                backgroundMusicPlayer?.volume = 0.5
                backgroundMusicPlayer?.prepareToPlay()
                backgroundMusicPlayer?.play()
            } catch {
                print(
                    "Error loading background music: \(error.localizedDescription)"
                )
            }
        } else {
            print("Background music file not found: \(fileName).\(fileType)")
        }
    }

    func stopBackgroundMusic(
        fadeOut: Bool = false, duration: TimeInterval = 0
    ) {
        guard let player = backgroundMusicPlayer, player.isPlaying else {
            return
        }

        if fadeOut {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {
                timer in
                if player.volume > 0.0 {
                    player.volume -= Float(0.1 / duration)
                } else {
                    player.stop()
                    timer.invalidate()
                }
            }
        } else {
            player.stop()
        }
    }

    func resumeBackgroundMusic() {
        guard let player = backgroundMusicPlayer else { return }
        player.play()
    }

    func toggleSound() {
        isSoundEnabled.toggle()
    }

    func toggleBgMusic() {
        isBgMusicEnabled.toggle()
        if isBgMusicEnabled {
            backgroundMusicPlayer?.play()
        } else {
            backgroundMusicPlayer?.pause()
        }
    }

}

// Enum for all available game sounds
enum GameSound: String {
    case piecePlaced = "piece_placed"
    case incorrectPiecePlaced = "incorrect_piece_placed"
    case levelComplete = "level_complete"
    case gameOverWithPieces = "game_over_incomplete_puzzle"
    case gameOverNoPieces = "game_over_no_puzzle"
    case freeze = "freeze"
    case shutter = "shutter-click"
    case shuffle = "shuffle"
    case select = "select"
    case deselect = "deselect"
    case confirm = "confirm"
    case notifyHint = "notify_hint"
}

