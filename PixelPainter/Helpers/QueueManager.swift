import UIKit

class QueueManager {
    private var imageQueue: [String] = []
    private var currentIndex = 0
    private var currentGridSize: Int = 3
    private var imagesByGridSize: [Int: [String]] = [:]
    
    init() {
        scanAvailableImages()
        refreshImageQueue(forGridSize: 3)
    }
    
    private func scanAvailableImages() {
        // Initialize empty arrays for each grid size
        imagesByGridSize = [3: [], 4: [], 5: [], 6: []]
        
        // For each grid size, check for assets in its range
        for gridSize in 3...6 {
            let startIndex = gridSize * 100  // e.g., 300 for 3x3
            let endIndex = startIndex + 99   // e.g., 399 for 3x3
            
            for index in startIndex...endIndex {
                let imageName = "asset\(index)"
                if UIImage(named: imageName) != nil {
                    imagesByGridSize[gridSize]?.append(imageName)
                }
            }
        }
        
        // Print found images for debugging
        for (gridSize, images) in imagesByGridSize {
            print("\(gridSize)x\(gridSize) grid has \(images.count) images: \(images)")
        }
    }
    
    func refreshImageQueue(forGridSize gridSize: Int) {
        self.currentGridSize = gridSize
        
        // Clear the current queue
        imageQueue.removeAll()
        
        // Get images for the current grid size
        if let gridImages = imagesByGridSize[gridSize] {
            imageQueue = gridImages
            
            // Save the last image before shuffling
            let lastImage = imageQueue.last
            
            // Shuffle the queue and ensure the last image is not the first
            if !imageQueue.isEmpty {
                repeat {
                    imageQueue.shuffle()
                } while imageQueue.first == lastImage && imageQueue.count > 1
            }
        }
        
        currentIndex = 0
        
        print("Image Queue refreshed for \(gridSize)x\(gridSize) grid: \(imageQueue)")
    }
    
    func getCurrentImage() -> UIImage? {
        guard !imageQueue.isEmpty else {
            print("Queue is empty for \(currentGridSize)x\(currentGridSize) grid")
            return nil
        }
        return UIImage(named: imageQueue[currentIndex])
    }
    
    func moveToNextImage() {
        currentIndex += 1
        if currentIndex >= imageQueue.count {
            refreshImageQueue(forGridSize: currentGridSize)
        } else {
            print("Moved to next image. Current index: \(currentIndex)")
        }
    }
    
    func printCurrentQueue() {
        print("Current Image Queue for \(currentGridSize)x\(currentGridSize) grid:")
        for (index, imageName) in imageQueue.enumerated() {
            print("\(index): \(imageName)\(index == currentIndex ? " (Current)" : "")")
        }
    }
}
