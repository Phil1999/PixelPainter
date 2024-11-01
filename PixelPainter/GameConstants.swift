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
        static let maxUses = 3
        static let minUses = 0
        static let maxShufflePieces = 3
    }
}
