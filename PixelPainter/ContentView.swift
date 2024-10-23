//
//  ContentView.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/22/24.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject private var gameContext = GameContext()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                SpriteView(scene: gameContext.scene)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    Color.clear
                        .frame(height: geometry.safeAreaInsets.bottom)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
