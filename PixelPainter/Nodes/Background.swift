import SpriteKit

class Background: SKNode {
    private var mainBackground: SKSpriteNode!
    private var gradientLayer: SKSpriteNode!
    private var fogEffect: SKSpriteNode!
    private var victoryGlow: SKSpriteNode!
    private var screenSize: CGSize = .zero
    private var warningOverlay: SKSpriteNode!

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(screenSize: CGSize) {
        self.screenSize = screenSize
        setupLayers()
    }
}

extension Background {
    private func setupLayers() {
        setupGradient()
        setupWarningOverlay()
        setupMainBackground()
        setupVictoryGlow()
        setupFog()

    }
    
    func fadeOutWarningOverlay(completion: @escaping () -> Void) {
        let fadeOut = SKAction.fadeOut(withDuration: 0.6)
        warningOverlay.run(fadeOut, completion: completion)
    }
    
    private func setupWarningOverlay() {
        warningOverlay = SKSpriteNode(color: .clear, size: screenSize)
        warningOverlay.position = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        warningOverlay.zPosition = -1.5  // Between background and fog
        warningOverlay.alpha = 0
        addChild(warningOverlay)
    }

    func updateWarningLevel(timeRemaining: Double) {
       let warningThreshold = 8.0
       
       if timeRemaining <= warningThreshold {
           let intensity = 1 - (timeRemaining / warningThreshold)
           warningOverlay.removeAllActions()
           
           let gradientTexture = createWarningGradient(intensity: intensity)
           warningOverlay.texture = gradientTexture
           warningOverlay.alpha = 1
           
           // Fade out fog as warning increases
           if let fogEffect = self.fogEffect {
               fogEffect.alpha = timeRemaining <= 1.0 ? 0 : 0.8 * (timeRemaining / warningThreshold)
           }
       } else {
           warningOverlay.alpha = 0
           fogEffect?.alpha = 0.8 // Reset fog to original alpha
       }
    }
    
    private func createWarningGradient(intensity: CGFloat) -> SKTexture {
       let gradientLayer = CAGradientLayer()
       gradientLayer.frame = CGRect(origin: .zero, size: screenSize)
       
       // Create colors with smooth intensity transition
        let topColor = UIColor(hex: "FF2E32").withAlphaComponent(pow(intensity, 2) * 0.8)
        let midColor = UIColor(hex: "300001").withAlphaComponent(pow(intensity, 2) * 0.8)
        let bottomColor = UIColor(hex: "171717").withAlphaComponent(pow(intensity, 2) * 0.8)
       
       gradientLayer.colors = [topColor.cgColor, midColor.cgColor, bottomColor.cgColor]
       gradientLayer.locations = [0.0, 0.5, 1.0]
       
       let scale = UIScreen.main.scale
       UIGraphicsBeginImageContextWithOptions(screenSize, false, scale)
       if let context = UIGraphicsGetCurrentContext() {
           gradientLayer.render(in: context)
           let image = UIGraphicsGetImageFromCurrentImageContext()
           UIGraphicsEndImageContext()
           return SKTexture(image: image!)
       }
       UIGraphicsEndImageContext()
       return SKTexture()
    }

    private func setupGradient() {
        let gradientSize = CGSize(
            width: screenSize.width, height: screenSize.height)
        gradientLayer = SKSpriteNode(color: .white, size: gradientSize)

        let topColor = UIColor(hex: "4b4b4b") // Originially BAB3B9
        let bottomColor = UIColor(hex: "030303") // Originally 171717
        let gradientTexture = createGradientTexture(
            colors: [topColor, bottomColor], size: gradientSize)

        gradientLayer.texture = gradientTexture
        gradientLayer.position = CGPoint(
            x: screenSize.width / 2, y: screenSize.height / 2)
        gradientLayer.zPosition = -3
        addChild(gradientLayer)
    }

    private func setupMainBackground() {
        guard let backgroundImage = UIImage(named: "background") else { return }

        let texture = SKTexture(image: backgroundImage)
        mainBackground = SKSpriteNode(texture: texture)

        let figmaAspect = 626.0 / 913.0
        let scale = 1.15
        let targetHeight = screenSize.height * scale
        let targetWidth = targetHeight * figmaAspect

        mainBackground.size = CGSize(width: targetWidth, height: targetHeight)
        let xOffset = -110 * (screenSize.width / 626)
        mainBackground.position = CGPoint(
            x: screenSize.width / 2 + xOffset, y: screenSize.height / 2)
        mainBackground.zPosition = -2
        
        mainBackground.alpha = 1
        
        addChild(mainBackground)
    }
    
    private func setupVictoryGlow() {
        guard let glowImage = UIImage(named: "VictoryGlow") else { return }
        
        // Resize the image if it's too large
        let maxSize: CGFloat = 2048 // Using a smaller max size for better performance
        let imageSize = glowImage.size
        let scaleFactor: CGFloat
        
        if imageSize.width > maxSize || imageSize.height > maxSize {
            scaleFactor = maxSize / max(imageSize.width, imageSize.height)
            let newSize = CGSize(
                width: imageSize.width * scaleFactor,
                height: imageSize.height * scaleFactor
            )
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            glowImage.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            guard let resizedImage = resizedImage else { return }
            victoryGlow = SKSpriteNode(texture: SKTexture(image: resizedImage))
        } else {
            victoryGlow = SKSpriteNode(texture: SKTexture(image: glowImage))
        }
        
        // Scale to screen size while maintaining aspect ratio but larger
        let scale = 2.75  // Increased from 1.15 to make it larger
        let targetHeight = screenSize.height * scale
        let targetWidth = targetHeight * (glowImage.size.width / glowImage.size.height)
        
        victoryGlow.size = CGSize(width: targetWidth, height: targetHeight)
        victoryGlow.position = CGPoint(
            x: screenSize.width / 2,
            y: screenSize.height / 2 + 75
        )
        victoryGlow.zPosition = -1.5
        victoryGlow.alpha = 0
        victoryGlow.name = "victoryGlow"
        addChild(victoryGlow)
    }

    private func setupFog() {
        let scale = 1.15
        if let fogImage = UIImage(named: "Fog") {
            let texture = SKTexture(image: fogImage)
            fogEffect = SKSpriteNode(texture: texture)

            // Calculate aspect ratio to maintain proportions
            let imageAspect = fogImage.size.width / fogImage.size.height
            let screenAspect = screenSize.width / screenSize.height

            if imageAspect > screenAspect {
                // Image is wider - fit to height
                let height = screenSize.height * scale
                let width = height * imageAspect
                fogEffect.size = CGSize(width: width, height: height)
            } else {
                // Image is taller - fit to width
                let width = screenSize.width
                let height = width / imageAspect
                fogEffect.size = CGSize(width: width, height: height)
            }

            fogEffect.position = CGPoint(
                x: screenSize.width / 3 + 20, y: screenSize.height / 3 + 30)
            fogEffect.zPosition = -1
            fogEffect.alpha = 0.8
            addChild(fogEffect)
        }
    }
    
    func playVictoryAnimation(completion: @escaping () -> Void) {
        guard let victoryGlow = self.childNode(withName: "victoryGlow"),
              let fogEffect = self.fogEffect else {
            completion()
            return
        }
        
        // Slower fade in for victory glow
        let fadeInGlow = SKAction.fadeIn(withDuration: 1.2)
        
        // Slower fade out for fog
        let fadeOutFog = SKAction.fadeOut(withDuration: 1.5)
        
        // Run the sequence with longer pauses
        victoryGlow.run(fadeInGlow)
        fogEffect.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.2),  // Wait for glow to fade in
            fadeOutFog,
            SKAction.wait(forDuration: 2.5),  // Much longer pause to appreciate the victory state
            SKAction.run(completion)
        ]))
    }

    private func createGradientTexture(colors: [UIColor], size: CGSize)
        -> SKTexture
    {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.frame = CGRect(origin: .zero, size: size)

        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        if let context = UIGraphicsGetCurrentContext() {
            gradientLayer.render(in: context)
            if let image = UIGraphicsGetImageFromCurrentImageContext() {
                UIGraphicsEndImageContext()
                return SKTexture(image: image)
            }
        }
        UIGraphicsEndImageContext()
        return SKTexture()
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
