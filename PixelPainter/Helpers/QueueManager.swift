//
//  QueueManager.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/30/24.
//

import UIKit

class QueueManager {
    private var imageQueue: [String] = []
    private var currentIndex = 0
    
    init() {
        refreshImageQueue()
    }
    
    func refreshImageQueue() {
        let assetNames = (1...100).compactMap { index -> String? in
            let name = "sample_image\(index)"
            return UIImage(named: name) != nil ? name : nil
        }
        
        imageQueue = assetNames.shuffled()
        currentIndex = 0
        
        print("Image Queue refreshed: \(imageQueue)")
    }
    
    func getCurrentImage() -> UIImage? {
        guard !imageQueue.isEmpty else { return nil }
        return UIImage(named: imageQueue[currentIndex])
    }
    
    func moveToNextImage() {
        currentIndex += 1
        if currentIndex >= imageQueue.count {
            refreshImageQueue()
        } else {
            print("Moved to next image. Current index: \(currentIndex)")
        }
    }
    
    func printCurrentQueue() {
        print("Current Image Queue:")
        for (index, imageName) in imageQueue.enumerated() {
            print("\(index): \(imageName)\(index == currentIndex ? " (Current)" : "")")
        }
    }
}
