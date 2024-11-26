//
//  GameConstants.swift
//  PixelPainter
//
//  Created by Philip Lee on 10/31/24.
//

import Foundation

enum GameConstants {
    enum PowerUp {
        // NOTE: minUses should be less than maxUses. But will work anyways if not (for testing).
        static let maxUses = 2000
        static let minUses = 1000
        static let maxShufflePieces = 3
    }
    enum PowerUpTimers {
        static let timeStopCooldown = 5.0
        static let flashCooldown = 5.0
    }
    enum GeneralGamePlay {
        static let timeWarningThreshold = 5.0
    }
}
