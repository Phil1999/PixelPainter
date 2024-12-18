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

    private var audioEngine: AVAudioEngine
    private var audioPlayers: [String: AVAudioPlayerNode]
    private var audioFiles: [String: AVAudioFile]
    private var backgroundMusicNode: AVAudioPlayerNode?
    private var isSoundEnabled = true
    private var isBgMusicEnabled = true
    private var isBackgroundMusicPlaying = false
    
    private var normalBackgroundVolume: Float = 0.5

    private init() {
        audioEngine = AVAudioEngine()
        audioPlayers = [:]
        audioFiles = [:]
        setupAudioEngine()
        preloadSounds()
    }

    private func setupAudioEngine() {
        let mainMixer = audioEngine.mainMixerNode
        mainMixer.outputVolume = 1.0

        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
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
            "memorize_break": "memorize-break.mp3",
        ]

        for (key, filename) in soundFiles {
            if let url = Bundle.main.url(
                forResource: filename, withExtension: nil)
            {
                do {
                    let file = try AVAudioFile(forReading: url)
                    audioFiles[key] = file

                    let player = AVAudioPlayerNode()
                    audioEngine.attach(player)
                    audioEngine.connect(
                        player, to: audioEngine.mainMixerNode,
                        format: file.processingFormat)
                    audioPlayers[key] = player
                } catch {
                    print(
                        "Failed to load sound \(filename): \(error.localizedDescription)"
                    )
                }
            }
        }

        backgroundMusicNode = AVAudioPlayerNode()
        if let bgNode = backgroundMusicNode {
            audioEngine.attach(bgNode)
            audioEngine.connect(
                bgNode, to: audioEngine.mainMixerNode,
                format: audioEngine.mainMixerNode.inputFormat(forBus: 0))
        }
    }

    func playSound(_ sound: GameSound) {
        guard isSoundEnabled,
            let player = audioPlayers[sound.rawValue],
            let file = audioFiles[sound.rawValue]
        else { return }

        // Stop any current playback
        player.stop()

        // Clear any scheduled buffers
        player.reset()
        
        switch sound {
                case .freeze:
                    player.rate = 0.9
                    player.volume = 1.2
                    dimBackgroundMusic()
                default:
                    player.rate = 1.0   // Normal pitch for all other sounds
                    player.volume = 1.0
                }

        // Schedule and play immediately
        player.scheduleFile(file, at: nil)
        player.play()
    }
    
    
    private var volumeTransitionTimer: Timer?
    
    func dimBackgroundMusic() {
        guard let bgNode = backgroundMusicNode,
              bgNode.engine != nil else { return }
        
        // Cancel any existing transition
        volumeTransitionTimer?.invalidate()
        
        let startVolume = bgNode.volume
        let targetVolume = normalBackgroundVolume * 0.3
        let steps = 10
        let stepDuration = 0.03  // Total duration will be 0.3s
        var currentStep = 0
        
        volumeTransitionTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self, weak bgNode] timer in
            guard let bgNode = bgNode else {
                timer.invalidate()
                return
            }
            
            currentStep += 1
            let progress = Float(currentStep) / Float(steps)
            bgNode.volume = startVolume + (targetVolume - startVolume) * progress
            
            if currentStep >= steps {
                timer.invalidate()
                self?.volumeTransitionTimer = nil
            }
        }
    }
    
    func restoreBackgroundMusicVolume() {
        guard let bgNode = backgroundMusicNode,
              bgNode.engine != nil else { return }
        
        // Cancel any existing transition
        volumeTransitionTimer?.invalidate()
        
        let startVolume = bgNode.volume
        let steps = 10
        let stepDuration = 0.03  // Total duration will be 0.3s
        var currentStep = 0
        
        volumeTransitionTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self, weak bgNode] timer in
            guard let bgNode = bgNode else {
                timer.invalidate()
                return
            }
            
            currentStep += 1
            let progress = Float(currentStep) / Float(steps)
            bgNode.volume = startVolume + (self?.normalBackgroundVolume ?? 0.5 - startVolume) * progress
            
            if currentStep >= steps {
                timer.invalidate()
                self?.volumeTransitionTimer = nil
            }
        }
    }
    
    // single source of truth for bg music.
    func ensureBackgroundMusic() {
        guard !isBackgroundMusicPlaying, isBgMusicEnabled else { return }

        startBackgroundMusic()
    }

    private func startBackgroundMusic() {
        guard let bgNode = backgroundMusicNode,
            bgNode.engine != nil,
            let url = Bundle.main.url(
                forResource: "game-bg", withExtension: "mp3")
        else { return }

        do {
            let file = try AVAudioFile(forReading: url)

            if bgNode.isPlaying {
                bgNode.stop()
                bgNode.reset()
            }

            bgNode.volume = 0.5

            // Set the looping point to the start
            let sampleTime = AVAudioTime(
                sampleTime: 0, atRate: file.processingFormat.sampleRate)

            // Schedule the file and immediately schedule it again when it finishes
            func scheduleNextLoop() {
                bgNode.scheduleFile(file, at: nil) { [weak bgNode] in
                    guard let bgNode = bgNode, bgNode.isPlaying else { return }
                    bgNode.scheduleFile(file, at: sampleTime) {
                        scheduleNextLoop()
                    }
                }
            }

            // Start the initial loop
            scheduleNextLoop()
            bgNode.play()
            isBackgroundMusicPlaying = true

        } catch {
            print("Error loading background music: \(error)")
            isBackgroundMusicPlaying = false
        }
    }

    func pauseBackgroundMusic() {
        backgroundMusicNode?.pause()
        isBackgroundMusicPlaying = false
    }

    func resumeBackgroundMusic() {
        guard isBgMusicEnabled else { return }
        backgroundMusicNode?.play()
        isBackgroundMusicPlaying = true
    }

    func stopBackgroundMusic(fadeOut: Bool = true, duration: TimeInterval = 1.0)
    {
        guard let bgNode = backgroundMusicNode,
            isBackgroundMusicPlaying
        else { return }

        // Immediately mark as not playing to prevent rescheduling
        isBackgroundMusicPlaying = false

        if fadeOut {
            let currentVolume = bgNode.volume
            let steps = 10
            let volumeStep = currentVolume / Float(steps)
            let stepDuration = duration / TimeInterval(steps)

            for i in 0..<steps {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + TimeInterval(i) * stepDuration
                ) {
                    if bgNode.engine != nil {
                        bgNode.volume =
                            currentVolume - (volumeStep * Float(i + 1))
                    }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                if bgNode.engine != nil {
                    bgNode.stop()
                    bgNode.reset()
                    bgNode.volume = currentVolume
                }
            }
        } else {
            if bgNode.engine != nil {
                bgNode.stop()
                bgNode.reset()
            }
        }
    }

    func toggleSound() {
        isSoundEnabled.toggle()
    }

    func toggleBgMusic() {
        isBgMusicEnabled.toggle()
        if isBgMusicEnabled {
            ensureBackgroundMusic()
        } else {
            stopBackgroundMusic(fadeOut: false)
        }
    }
}

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
