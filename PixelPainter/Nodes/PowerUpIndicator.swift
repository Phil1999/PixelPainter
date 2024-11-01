//
//  PowerUpIndicator.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/22/24.
//

import SpriteKit
import Foundation

enum PowerUpType: String, CaseIterable {
    case timeStop = "Time Stop"
    case place = "Place"
    case flash = "Flash"
    case shuffle = "Shuffle"
}

extension PowerUpType {
    static var all: [PowerUpType] = Self.allCases.map { $0 }
    
    var initialUses: Int {
        return GameConstants.PowerUp.minUses
    }
    
    var weight: Int {
        switch self {
        case .timeStop: return 2
        case .place: return 1
        case .flash: return 3
        case .shuffle: return 4
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
    
    var shortName: String {
        return self.rawValue.prefix(1).uppercased()
    }
}

class PowerUpIndicator: SKNode {
    
}
