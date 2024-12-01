//
//  PowerUpIndicator.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/22/24.
//

import Foundation
import SpriteKit

enum PowerUpType: String, CaseIterable {
    case timeStop = "Time Stop"
    case place = "Place"
    case flash = "Flash"
    case shuffle = "Shuffle"
}

extension PowerUpType {
    static var all: [PowerUpType] = Self.allCases.map { $0 }


    var displayName: String {
        return self.rawValue
    }

    var shortName: String {
        return self.rawValue.prefix(1).uppercased()
    }

    var iconName: String {
        switch self {
        case .timeStop: return "time_stop"
        case .place: return "place"
        case .flash: return "flash"
        case .shuffle: return "shuffle"
        }
    }

    var videoFileName: String {
        switch self {
        case .timeStop: return "time_stop_demo"
        case .place: return "place_demo"
        case .flash: return "flash_demo"
        case .shuffle: return "shuffle_demo"

        }
    }

    var uses: Int {
        switch self {
        case .timeStop: return 3
        case .place: return 2
        case .flash: return 2	
        case .shuffle: return 4
        }
    }
}

class PowerUpIndicator: SKNode {

}
