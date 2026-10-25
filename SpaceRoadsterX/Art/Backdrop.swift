import SpriteKit
import UIKit

/// Sunset highway: sky, sun, two parallax ridges, light posts, road and lane dashes.
final class Backdrop: SKNode {
    private let width: CGFloat
    private var ridges: [(nodes: [SKSpriteNode], factor: CGFloat)] = []
    private var posts: [SKSpriteNode] = []
    private var dashes: [SKSpriteNode] = []
    private let postGap: CGFloat
    private let dashGap: CGFloat

    init(size: CGSize, groundY gy: CGFloat, k: CGFloat) {
        width = size.width
        postGap = 220 * k
        dashGap = 70 * k
        super.init()

        let sky = SKSpriteNode(texture: Textures.vertical(CGSize(width: 8, height: 512),
                                                          colors: [UIColor(hex: 0x151a3a), UIColor(hex: 0x3b2d63),
                                                                   UIColor(hex: 0xa8507a), UIColor(hex: 0xff9a5a)]))
        sky.anchorPoint = .zero
        sky.size = CGSize(width: size.width, height: size.height - gy + 40 * k)
        sky.position = CGPoint(x: 0, y: gy - 40 * k)
        sky.zPosition = -100
        addChild(sky)

        let sunPos = CGPoint(x: size.width * 0.72, y: gy + 40 * k)
        let glow = SKSpriteNode(texture: Textures.softDot)
        glow.size = CGSize(width: 280 * k, height: 280 * k)
        glow.color = UIColor(hex: 0xffb070)
        glow.colorBlendFactor = 1
        glow.alpha = 0.55
        glow.blendMode = .add
        glow.position = sunPos
        glow.zPosition = -91
        addChild(glow)
        let sun = SKShapeNode(circleOfRadius: 46 * k)
        sun.fillColor = UIColor(red: 1, green: 0.84, blue: 0.59, alpha: 0.92)
        sun.strokeColor = .clear
        sun.position = sunPos
        sun.zPosition = -90
        addChild(sun)

        addRidge(base: gy, lift: 18 * k, amp: 90 * k, seed: 2, color: UIColor(hex: 0x3a2a55), factor: 0.08, z: -80)
        addRidge(base: gy, lift: 4 * k, amp: 60 * k, seed: 7, color: UIColor(hex: 0x251d3e), factor: 0.22, z: -70)

        let postTex = Textures.texture(CGSize(width: 18 * k, height: 130 * k)) { ctx, s in
            ctx.setFillColor(UIColor(red: 14 / 255, green: 18 / 255, blue: 34 / 255, alpha: 0.75).cgColor)
            ctx.fill(CGRect(x: s.width - 3 * k, y: 0, width: 3 * k, height: s.height))
            ctx.fill(CGRect(x: 0, y: 0, width: s.width, height: 3 * k))
            ctx.setFillColor(UIColor(hex: 0xffe2b0, alpha: 0.9).cgColor)
            ctx.fill(CGRect(x: 1 * k, y: 3 * k, width: 6 * k, height: 1.5 * k))
        }
        for _ in 0..<(Int(size.width / postGap) + 2) {
            let post = SKSpriteNode(texture: postTex)
            post.anchorPoint = CGPoint(x: 1, y: 0)
            post.position.y = gy
            post.zPosition = -60
            addChild(post)
            posts.append(post)
        }

        let road = SKSpriteNode(color: UIColor(hex: 0x1a1e30), size: CGSize(width: size.width, height: gy))
        road.anchorPoint = .zero
        road.zPosition = -50
        addChild(road)
        let shoulder = SKSpriteNode(color: UIColor(hex: 0x2a3048), size: CGSize(width: size.width, height: 4 * k))
        shoulder.anchorPoint = .zero
        shoulder.position = CGPoint(x: 0, y: gy - 4 * k)
        shoulder.zPosition = -49
        addChild(shoulder)
        // Sun reflecting on the asphalt.
        let sheen = SKSpriteNode(texture: Textures.softDot)
        sheen.size = CGSize(width: 260 * k, height: 60 * k)
        sheen.color = UIColor(hex: 0xff9a5a)
        sheen.colorBlendFactor = 1
        sheen.alpha = 0.18
        sheen.blendMode = .add
        sheen.position = CGPoint(x: sunPos.x, y: gy - 40 * k)
        sheen.zPosition = -49
        addChild(sheen)
        for _ in 0..<(Int(size.width / dashGap) + 2) {
            let dash = SKSpriteNode(color: UIColor(red: 238 / 255, green: 241 / 255, blue: 245 / 255, alpha: 0.55),
                                    size: CGSize(width: 34 * k, height: 4 * k))
            dash.anchorPoint = .zero
            dash.position.y = gy - 38 * k
            dash.zPosition = -48
            addChild(dash)
            dashes.append(dash)
        }
        update(scroll: 0)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// A ridge texture exactly one screen wide whose ends match, laid twice and slid with parallax.
    private func addRidge(base: CGFloat, lift: CGFloat, amp: CGFloat, seed: CGFloat, color: UIColor, factor: CGFloat, z: CGFloat) {
        let size = CGSize(width: width, height: lift + amp)
        let tex = Textures.texture(size) { ctx, s in
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: s.height))
            var x: CGFloat = 0
            while x <= s.width {
                let u = x / s.width * .pi * 2
                let h = 0.5 + 0.3 * sin(u * 2 + seed) + 0.15 * sin(u * 5 + seed * 1.7) + 0.05 * sin(u * 11 + seed * 0.3)
                path.addLine(to: CGPoint(x: x, y: amp * (1 - h)))
                x += 2
            }
            path.addLine(to: CGPoint(x: s.width, y: s.height))
            path.closeSubpath()
            ctx.addPath(path)
            ctx.setFillColor(color.cgColor)
            ctx.fillPath()
        }
        var nodes: [SKSpriteNode] = []
        for _ in 0..<2 {
            let n = SKSpriteNode(texture: tex)
            n.anchorPoint = .zero
            n.position.y = base
            n.zPosition = z
            addChild(n)
            nodes.append(n)
        }
        ridges.append((nodes, factor))
    }

    func update(scroll: CGFloat) {
        for ridge in ridges {
            let off = (scroll * ridge.factor).truncatingRemainder(dividingBy: width)
            for (i, n) in ridge.nodes.enumerated() { n.position.x = CGFloat(i) * width - off }
        }
        let po = (scroll * 0.6).truncatingRemainder(dividingBy: postGap)
        for (i, p) in posts.enumerated() { p.position.x = CGFloat(i) * postGap - po + postGap * 0.5 }
        let d0 = scroll.truncatingRemainder(dividingBy: dashGap)
        for (i, d) in dashes.enumerated() { d.position.x = CGFloat(i) * dashGap - d0 }
    }
}
