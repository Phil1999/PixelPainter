//
//  PowerUpIndicator.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/22/24.
//

import Foundation
import SpriteKit

enum PPPowerUpType: String, CaseIterable {
    case timeStop = "Time Stop"
    case place = "Place"
    case flash = "Flash"
    case shuffle = "Shuffle"
}

extension PPPowerUpType {
    static var all: [PPPowerUpType] = Self.allCases.map { $0 }


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
        case .timeStop: return 1
        case .place: return 2
        case .flash: return 1
        case .shuffle: return 3
        }
    }
    
    var themeColor: UIColor {
        switch self {
        case .timeStop:
            return UIColor(hex: "06B6D4") // Cyan-500
        case .place:
            return UIColor(hex: "10B981") // Emerald-500
        case .flash:
            return UIColor(hex: "F59E0B") // Amber-500
        case .shuffle:
            return UIColor(hex: "8B5CF6") // Purple-500
            }
        }
}

class PowerUpIndicator: SKNode {

}
