//
//  Background.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/22/24.
//

import SpriteKit

class Background: SKNode {
    
    private var mainBackground: SKSpriteNode!
    private var screenSize: CGSize = .zero
    
    override init() {
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(screenSize: CGSize) {
        self.screenSize = screenSize
        setupMainBackground()
        
    }
}

// MARK: Helpers
extension Background {
    
    private func setupMainBackground() {
        
    }
}
