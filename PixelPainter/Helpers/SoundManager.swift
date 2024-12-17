//
//  SoundManager.swift
//  PixelPainter
//
//  Created by Philip Lee on 11/6/24.
//

import AVFoundation
import SpriteKit

class SoundManager {
    static let shared = SoundManager()

    private var soundPlayers: [String: AVAudioPlayer] = [:]
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var isSoundEnabled = true
    private var isBgMusicEnabled = true

    private init() {
        preloadSounds()
    }

    private func preloadSounds() {
        let soundFiles = [
            "piece_placed": "piece_placed.wav",
            "incorrect_piece_placed": "incorrect-placement.mp3",
            "level_complete": "level_complete.wav",
            "game_over_incomplete_puzzle": "game-end-incomplete-puzzle.mp3",
            "game_over_no_puzzle": "game-over-no-puzzle.wav",
            "freeze": "freeze.mp3",
            "shutter-click": "shutter-click.mp3",
            "shuffle": "shuffle.mp3",
            "select": "select.mp3",
            "deselect": "deselect.mp3",
            "confirm": "confirm.mp3",
            "notify_hint": "hint-notification.mp3",
            "memorize_break": "memorize-break.mp3"
        ]

        for (key, filename) in soundFiles {
            if let url = Bundle.main.url(forResource: filename, withExtension: nil) {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    soundPlayers[key] = player
                } catch {
                    print("Failed to load sound \(filename): \(error.localizedDescription)")
                }
            }
        }
    }

    func playSound(_ sound: GameSound) {
        guard isSoundEnabled, let player = soundPlayers[sound.rawValue] else { return }
        player.currentTime = 0  // Rewind to the start for reuse
        player.play()
    }

    func playBackgroundMusic(_ fileName: String, loop: Bool = true) {
        guard isBgMusicEnabled else { return }

        if backgroundMusicPlayer?.isPlaying == true {
            return
        }

        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") {
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
                backgroundMusicPlayer?.numberOfLoops = loop ? -1 : 0
                backgroundMusicPlayer?.volume = 0.5
                backgroundMusicPlayer?.prepareToPlay()
                backgroundMusicPlayer?.play()
            } catch {
                print("Error loading background music: \(error.localizedDescription)")
            }
        } else {
            print("Background music file not found: \(fileName)")
        }
    }

    func stopBackgroundMusic(fadeOut: Bool = true, duration: TimeInterval = 1.0) {
        guard let player = backgroundMusicPlayer, player.isPlaying else { return }

        if fadeOut {
            var volume = player.volume
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                volume -= Float(0.1 / duration)
                if volume <= 0.0 {
                    player.stop()
                    timer.invalidate()
                } else {
                    player.volume = volume
                }
            }
        } else {
            player.stop()
        }
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
    case memorizeBreak = "memorize_break"
}

