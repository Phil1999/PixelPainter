import SpriteKit

class Background: SKNode {
    
    private var mainBackground: SKSpriteNode!
    private var gradientLayer: SKShapeNode!
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

extension Background {
    private func setupMainBackground() {
        // Create gradient layer
        gradientLayer = SKShapeNode(rect: CGRect(origin: .zero, size: screenSize))
        
        // Create gradient with specified colors
        let bottomColor = UIColor(hex: "171717")
        let topColor = UIColor(hex: "BAB3B9")
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [bottomColor.cgColor, topColor.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.frame = CGRect(origin: .zero, size: screenSize)
        
        // Convert CAGradientLayer to UIImage
        UIGraphicsBeginImageContext(screenSize)
        if let context = UIGraphicsGetCurrentContext() {
            gradientLayer.render(in: context)
            if let image = UIGraphicsGetImageFromCurrentImageContext() {
                gradientLayer.removeFromSuperlayer()
                UIGraphicsEndImageContext()
                
                // Create sprite node with gradient
                let gradientNode = SKSpriteNode(texture: SKTexture(image: image))
                gradientNode.position = CGPoint(x: screenSize.width/2, y: screenSize.height/2)
                gradientNode.zPosition = -2
                addChild(gradientNode)
                
                // Create inner shadow based on Figma CSS values
                createInnerShadow()
            }
        }
        
        // Load background image with Figma positioning
        if let backgroundImage = UIImage(named: "background") {
            let texture = SKTexture(image: backgroundImage)
            mainBackground = SKSpriteNode(texture: texture)
            
            // Calculate the aspect ratio based on Figma dimensions (626x913)
            let figmaAspect = 626.0 / 913.0
            let targetHeight = screenSize.height
            let targetWidth = targetHeight * figmaAspect
            
            mainBackground.size = CGSize(width: targetWidth, height: targetHeight)
            
            // Position based on Figma CSS (left: -69px)
            // Convert the -69px to a relative position
            let xOffset = -69 * (screenSize.width / 626) // Scale offset based on screen width
            mainBackground.position = CGPoint(x: screenSize.width/2 + xOffset, y: screenSize.height/2)
            mainBackground.zPosition = -1
            mainBackground.alpha = 0.25
            addChild(mainBackground)
        }
    }
    
    private func createInnerShadow() {
        // Create inner shadow using Figma values (0px 4px 4px rgba(0, 0, 0, 0.25))
        let effectNode = SKEffectNode()
        effectNode.shouldRasterize = true
        
        let shadowNode = SKSpriteNode(color: .black, size: screenSize)
        shadowNode.alpha = 0.5 // Figma's 0.25 opacity
        effectNode.addChild(shadowNode)
        
        // Position shadow based on Figma values (4px down)
        effectNode.position = CGPoint(x: screenSize.width/2, y: screenSize.height/2 - 4)
        effectNode.zPosition = -1.5
        
        // Apply 4px blur
        let blur = CIFilter(name: "CIGaussianBlur")
        blur?.setValue(4, forKey: kCIInputRadiusKey)
        effectNode.filter = blur
        
        addChild(effectNode)
    }
}

// Helper extension to create UIColor from hex
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
