import SpriteKit
import UIKit

/// Small helpers for drawing crisp textures in code with Core Graphics at the screen's scale.
enum Textures {
    static func image(_ size: CGSize, _ draw: (CGContext, CGSize) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { draw($0.cgContext, size) }
    }

    static func texture(_ size: CGSize, _ draw: (CGContext, CGSize) -> Void) -> SKTexture {
        let tex = SKTexture(image: image(size, draw))
        tex.filteringMode = .linear
        return tex
    }

    static func gradient(_ colors: [UIColor], locations: [CGFloat]? = nil) -> CGGradient {
        CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                   colors: colors.map(\.cgColor) as CFArray,
                   locations: locations)!
    }

    /// Soft round particle: white core fading to clear. Tinted by emitters.
    static let softDot: SKTexture = texture(CGSize(width: 32, height: 32)) { ctx, size in
        let c = CGPoint(x: size.width / 2, y: size.height / 2)
        let g = gradient([.white, UIColor.white.withAlphaComponent(0.55), UIColor.white.withAlphaComponent(0)],
                         locations: [0, 0.35, 1])
        ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: size.width / 2, options: [])
    }

    /// Small hard dot for sparks and road grit.
    static let spark: SKTexture = texture(CGSize(width: 8, height: 8)) { ctx, size in
        let c = CGPoint(x: size.width / 2, y: size.height / 2)
        let g = gradient([.white, UIColor.white.withAlphaComponent(0)], locations: [0.4, 1])
        ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: size.width / 2, options: [])
    }

    static func vertical(_ size: CGSize, colors: [UIColor]) -> SKTexture {
        texture(size) { ctx, s in
            ctx.drawLinearGradient(gradient(colors), start: .zero, end: CGPoint(x: 0, y: s.height), options: [])
        }
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xff) / 255,
                  green: CGFloat((hex >> 8) & 0xff) / 255,
                  blue: CGFloat(hex & 0xff) / 255,
                  alpha: alpha)
    }

    /// Shifts brightness by `amount` (-1...1) keeping hue, for paint shading.
    func shaded(_ amount: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let nb = min(1, max(0, b + amount))
        let ns = amount > 0 ? max(0, s - amount * 0.35) : s
        return UIColor(hue: h, saturation: ns, brightness: nb, alpha: a)
    }
}

enum Palette {
    static let paint = UIColor(hex: 0xeef1f5)
    static let mute = UIColor(hex: 0x9aa3b8)
    static let plume = UIColor(hex: 0x7fe3ff)
    static let ember = UIColor(hex: 0xff6a3d)
    static let night = UIColor(hex: 0x0e1222)
    static let gold = UIColor(hex: 0xffd27a)
}
