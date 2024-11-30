//
//  GameConstants.swift
//  PixelPainter
//
//  Created by Philip Lee on 10/31/24.
//

import Foundation

enum GameConstants {
    enum PowerUp {
        static let maxShufflePieces = 3
    }
    enum PowerUpTimers {
        static let timeStopCooldown = 5.0
        static let flashCooldown = 5.0
    }
    enum GeneralGamePlay {
        static let timeWarningThreshold = 5.0
        static let hintWaitTime = 3.0
        static let idleHintWaitTime = 4.0
    }
}
