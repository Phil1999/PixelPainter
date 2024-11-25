import SpriteKit

class Background: SKNode {
    private var mainBackground: SKSpriteNode!
    private var gradientLayer: SKSpriteNode!
    private var fogEffect: SKSpriteNode!
    private var screenSize: CGSize = .zero
    
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
        setupMainBackground()
        setupFog()
    }
    
    private func setupGradient() {
        let gradientSize = CGSize(width: screenSize.width, height: screenSize.height)
        gradientLayer = SKSpriteNode(color: .white, size: gradientSize)
        
        let topColor = UIColor(hex: "BAB3B9")
        let bottomColor = UIColor(hex: "171717")
        let gradientTexture = createGradientTexture(colors: [topColor, bottomColor], size: gradientSize)
        
        gradientLayer.texture = gradientTexture
        gradientLayer.position = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
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
        mainBackground.position = CGPoint(x: screenSize.width / 2 + xOffset, y: screenSize.height / 2)
        mainBackground.zPosition = -2
        addChild(mainBackground)
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
           
            fogEffect.position = CGPoint(x: screenSize.width / 3 + 20, y: screenSize.height / 3 + 30)
            fogEffect.zPosition = -1
            fogEffect.alpha = 0.8
            addChild(fogEffect)
       }
    }
    
    private func createGradientTexture(colors: [UIColor], size: CGSize) -> SKTexture {
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
