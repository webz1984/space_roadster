import SpriteKit
import UIKit

/// Rural Texas at sundown: a big sky, flat-topped mesas, prairie with cowboys and longhorns on
/// the skyline, a barbed-wire fence along the road, windmills and prickly pear on the shoulder,
/// the odd tumbleweed, and a two-lane blacktop with a yellow center line.
final class Backdrop: SKNode {
    private let width: CGFloat
    private let k: CGFloat
    private let gy: CGFloat
    private var ridges: [(nodes: [SKSpriteNode], factor: CGFloat)] = []
    private var fence: [SKSpriteNode] = []
    private var props: [SKSpriteNode] = []
    private var dashes: [SKSpriteNode] = []
    private let tumbleweed: SKSpriteNode
    private let fenceGap: CGFloat
    private let propGap: CGFloat
    private let dashGap: CGFloat

    private static let fenceFactor: CGFloat = 0.6

    init(size: CGSize, groundY gy: CGFloat, k: CGFloat) {
        width = size.width
        self.k = k
        self.gy = gy
        fenceGap = 90 * k
        propGap = max(size.width * 0.75, 300 * k)
        dashGap = 70 * k
        tumbleweed = SKSpriteNode(texture: Backdrop.tumbleweedTexture(k: k))
        super.init()

        let sky = SKSpriteNode(texture: Textures.vertical(CGSize(width: 8, height: 512),
                                                          colors: [UIColor(hex: 0x1b2447), UIColor(hex: 0x56406b),
                                                                   UIColor(hex: 0xd9694a), UIColor(hex: 0xf7a24b),
                                                                   UIColor(hex: 0xffd88a)]))
        sky.anchorPoint = .zero
        sky.size = CGSize(width: size.width, height: size.height - gy + 40 * k)
        sky.position = CGPoint(x: 0, y: gy - 40 * k)
        sky.zPosition = -100
        addChild(sky)

        let sunPos = CGPoint(x: size.width * 0.70, y: gy + 70 * k)
        let glow = SKSpriteNode(texture: Textures.softDot)
        glow.size = CGSize(width: 360 * k, height: 360 * k)
        glow.color = UIColor(hex: 0xffb35a)
        glow.colorBlendFactor = 1
        glow.alpha = 0.6
        glow.blendMode = .add
        glow.position = sunPos
        glow.zPosition = -91
        addChild(glow)
        let sun = SKShapeNode(circleOfRadius: 58 * k)
        sun.fillColor = UIColor(hex: 0xffe1a1, alpha: 0.95)
        sun.strokeColor = .clear
        sun.position = sunPos
        sun.zPosition = -90
        addChild(sun)

        addLayer(texture: mesas(size: size), factor: 0.05, z: -82)
        addLayer(texture: prairie(size: size), factor: 0.18, z: -72)

        let fenceTex = Backdrop.fenceTexture(width: fenceGap, k: k)
        for _ in 0..<(Int(size.width / fenceGap) + 2) {
            let f = SKSpriteNode(texture: fenceTex)
            f.anchorPoint = .zero
            f.position.y = gy - 2 * k
            f.zPosition = -60
            addChild(f)
            fence.append(f)
        }
        // Roadside props, a little in front of the fence.
        for tex in [Backdrop.windmillTexture(k: k), Backdrop.cactusTexture(k: k), Backdrop.yuccaTexture(k: k)] {
            let p = SKSpriteNode(texture: tex)
            p.anchorPoint = CGPoint(x: 0.5, y: 0)
            p.position.y = gy - 3 * k
            p.zPosition = -58
            addChild(p)
            props.append(p)
        }

        let road = SKSpriteNode(color: UIColor(hex: 0x2a2a31), size: CGSize(width: size.width, height: gy))
        road.anchorPoint = .zero
        road.zPosition = -50
        addChild(road)
        let shoulder = SKSpriteNode(color: UIColor(hex: 0xa06c45), size: CGSize(width: size.width, height: 6 * k))
        shoulder.anchorPoint = .zero
        shoulder.position = CGPoint(x: 0, y: gy - 6 * k)
        shoulder.zPosition = -49
        addChild(shoulder)
        let edge = SKSpriteNode(color: UIColor(hex: 0xd8d4cc, alpha: 0.6), size: CGSize(width: size.width, height: 2 * k))
        edge.anchorPoint = .zero
        edge.position = CGPoint(x: 0, y: gy - 9 * k)
        edge.zPosition = -49
        addChild(edge)
        let sheen = SKSpriteNode(texture: Textures.softDot)
        sheen.size = CGSize(width: 300 * k, height: 60 * k)
        sheen.color = UIColor(hex: 0xffa24b)
        sheen.colorBlendFactor = 1
        sheen.alpha = 0.16
        sheen.blendMode = .add
        sheen.position = CGPoint(x: sunPos.x, y: gy - 40 * k)
        sheen.zPosition = -49
        addChild(sheen)
        for _ in 0..<(Int(size.width / dashGap) + 2) {
            let dash = SKSpriteNode(color: UIColor(hex: 0xf2c14e, alpha: 0.85), size: CGSize(width: 34 * k, height: 4 * k))
            dash.anchorPoint = .zero
            dash.position.y = gy - 38 * k
            dash.zPosition = -48
            addChild(dash)
            dashes.append(dash)
        }

        tumbleweed.zPosition = -47
        addChild(tumbleweed)
        update(scroll: 0)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func update(scroll: CGFloat) {
        for ridge in ridges {
            let off = (scroll * ridge.factor).truncatingRemainder(dividingBy: width)
            for (i, n) in ridge.nodes.enumerated() { n.position.x = CGFloat(i) * width - off }
        }
        let fo = (scroll * Backdrop.fenceFactor).truncatingRemainder(dividingBy: fenceGap)
        for (i, f) in fence.enumerated() { f.position.x = CGFloat(i) * fenceGap - fo }
        let period = propGap * CGFloat(props.count)
        let po = (scroll * Backdrop.fenceFactor * 1.08).truncatingRemainder(dividingBy: period)
        for (i, p) in props.enumerated() {
            var x = CGFloat(i) * propGap - po + propGap * 0.6
            if x < -80 * k { x += period }
            p.position.x = x
        }
        let d0 = scroll.truncatingRemainder(dividingBy: dashGap)
        for (i, d) in dashes.enumerated() { d.position.x = CGFloat(i) * dashGap - d0 }

        // A tumbleweed blows across now and then, a touch faster than the road.
        let span = width * 3
        let tx = width + 60 * k - (scroll * 1.15 + width).truncatingRemainder(dividingBy: span)
        let r = 11 * k
        tumbleweed.position = CGPoint(x: tx, y: gy - 14 * k + r + abs(sin(tx / (38 * k))) * 16 * k)
        tumbleweed.zRotation = tx / r
    }

    private func addLayer(texture: SKTexture, factor: CGFloat, z: CGFloat) {
        var nodes: [SKSpriteNode] = []
        for _ in 0..<2 {
            let n = SKSpriteNode(texture: texture)
            n.anchorPoint = .zero
            n.position.y = gy
            n.zPosition = z
            addChild(n)
            nodes.append(n)
        }
        ridges.append((nodes, factor))
    }

    // MARK: Far layers (one screen wide, ends match so they tile)

    /// Flat-topped mesas and buttes, hazy purple in the distance.
    private func mesas(size: CGSize) -> SKTexture {
        let h = 150 * k
        let w = size.width
        let k = self.k
        return Textures.texture(CGSize(width: w, height: h)) { ctx, s in
            // (center as a fraction of width, top width, base width, height) in points at k = 1.
            let shapes: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                (0.08, 70, 130, 70), (0.34, 26, 60, 96), (0.55, 120, 190, 58), (0.86, 44, 96, 84),
            ]
            ctx.setFillColor(UIColor(hex: 0x7a4a5e).cgColor)
            for (cx, top, base, height) in shapes {
                for shift in [-w, 0, w] {
                    let x = cx * w + shift
                    let path = CGMutablePath()
                    path.move(to: CGPoint(x: x - base * k / 2, y: s.height))
                    path.addLine(to: CGPoint(x: x - top * k / 2 - 6 * k, y: s.height - height * k * 0.82))
                    path.addLine(to: CGPoint(x: x - top * k / 2, y: s.height - height * k))
                    path.addLine(to: CGPoint(x: x + top * k / 2, y: s.height - height * k))
                    path.addLine(to: CGPoint(x: x + top * k / 2 + 5 * k, y: s.height - height * k * 0.8))
                    path.addLine(to: CGPoint(x: x + base * k / 2, y: s.height))
                    path.closeSubpath()
                    ctx.addPath(path)
                }
            }
            ctx.fillPath()
            // Low haze over the base.
            ctx.drawLinearGradient(Textures.gradient([UIColor(hex: 0xf3a15a, alpha: 0), UIColor(hex: 0xf3a15a, alpha: 0.45)]),
                                   start: CGPoint(x: 0, y: s.height * 0.4), end: CGPoint(x: 0, y: s.height), options: [])
        }
    }

    /// Rolling prairie with riders, longhorns and a far windmill on the skyline.
    private func prairie(size: CGSize) -> SKTexture {
        let k = self.k
        let amp = 34 * k, lift = 10 * k
        let w = size.width
        let h = lift + amp + 52 * k
        func ridgeY(_ x: CGFloat) -> CGFloat {
            let u = x / w * .pi * 2
            let v = 0.5 + 0.3 * sin(u * 2 + 1.3) + 0.2 * sin(u * 3 + 0.4)
            return h - lift - amp * v
        }
        return Textures.texture(CGSize(width: w, height: h)) { ctx, s in
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: s.height))
            var x: CGFloat = 0
            while x <= s.width {
                path.addLine(to: CGPoint(x: x, y: ridgeY(x)))
                x += 2
            }
            path.addLine(to: CGPoint(x: s.width, y: s.height))
            path.closeSubpath()
            ctx.addPath(path)
            ctx.setFillColor(UIColor(hex: 0x4a2c2a).cgColor)
            ctx.fillPath()

            let ink = UIColor(hex: 0x2a1a1c).cgColor
            ctx.setFillColor(ink)
            ctx.setStrokeColor(ink)
            Backdrop.rider(ctx, at: CGPoint(x: w * 0.22, y: ridgeY(w * 0.22) + 2 * k), k: k * 0.9)
            Backdrop.rider(ctx, at: CGPoint(x: w * 0.29, y: ridgeY(w * 0.29) + 2 * k), k: k * 0.8)
            Backdrop.longhorn(ctx, at: CGPoint(x: w * 0.47, y: ridgeY(w * 0.47) + 2 * k), k: k * 0.8)
            Backdrop.longhorn(ctx, at: CGPoint(x: w * 0.53, y: ridgeY(w * 0.53) + 2 * k), k: k * 0.7)
            Backdrop.drawWindmill(ctx, base: CGPoint(x: w * 0.78, y: ridgeY(w * 0.78) + 2 * k), k: k * 0.45, ink: ink)
        }
    }

    // MARK: Silhouettes

    /// Cowboy on horseback, facing right.
    private static func rider(_ ctx: CGContext, at p: CGPoint, k: CGFloat) {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: p.x + x * k, y: p.y - y * k) }
        ctx.fillEllipse(in: CGRect(x: p.x - 11 * k, y: p.y - 19 * k, width: 22 * k, height: 9 * k))    // barrel
        ctx.setLineWidth(2.2 * k)
        ctx.setLineCap(.round)
        for (x0, x1) in [(-8, -10), (-5, -4), (6, 5), (9, 11)] as [(CGFloat, CGFloat)] {               // legs
            ctx.move(to: pt(x0, 12)); ctx.addLine(to: pt(x1, 0))
        }
        ctx.move(to: pt(9, 16)); ctx.addLine(to: pt(14, 25))                                          // neck
        ctx.strokePath()
        ctx.fillEllipse(in: CGRect(x: p.x + 12 * k, y: p.y - 28 * k, width: 9 * k, height: 5 * k))    // head
        ctx.setLineWidth(1.4 * k)
        ctx.move(to: pt(-11, 16)); ctx.addLine(to: pt(-16, 9))                                         // tail
        ctx.strokePath()
        ctx.fill(CGRect(x: p.x - 2.5 * k, y: p.y - 31 * k, width: 5 * k, height: 12 * k))              // rider
        ctx.fillEllipse(in: CGRect(x: p.x - 2.5 * k, y: p.y - 36 * k, width: 5 * k, height: 5 * k))    // head
        ctx.fill(CGRect(x: p.x - 6 * k, y: p.y - 36.5 * k, width: 12 * k, height: 1.6 * k))            // hat brim
        ctx.fill(CGRect(x: p.x - 2.5 * k, y: p.y - 39.5 * k, width: 5 * k, height: 3.2 * k))           // hat crown
    }

    private static func longhorn(_ ctx: CGContext, at p: CGPoint, k: CGFloat) {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: p.x + x * k, y: p.y - y * k) }
        ctx.fillEllipse(in: CGRect(x: p.x - 11 * k, y: p.y - 15 * k, width: 21 * k, height: 9 * k))
        ctx.setLineWidth(2.2 * k)
        for x in [-8, -4, 4, 7] as [CGFloat] { ctx.move(to: pt(x, 8)); ctx.addLine(to: pt(x, 0)) }
        ctx.strokePath()
        ctx.fillEllipse(in: CGRect(x: p.x + 8 * k, y: p.y - 15 * k, width: 6 * k, height: 5 * k))
        ctx.setLineWidth(1.2 * k)
        ctx.move(to: pt(4, 16)); ctx.addQuadCurve(to: pt(18, 16), control: pt(11, 12))                 // horns
        ctx.strokePath()
    }

    private static func drawWindmill(_ ctx: CGContext, base p: CGPoint, k: CGFloat, ink: CGColor) {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: p.x + x * k, y: p.y - y * k) }
        ctx.setStrokeColor(ink)
        ctx.setFillColor(ink)
        ctx.setLineWidth(2 * k)
        // Lattice tower.
        ctx.move(to: pt(-12, 0)); ctx.addLine(to: pt(-2, 80))
        ctx.move(to: pt(12, 0)); ctx.addLine(to: pt(2, 80))
        for i in 0..<5 {
            let y0 = CGFloat(i) * 16, y1 = y0 + 16
            let w0 = 12 - y0 / 8, w1 = 12 - y1 / 8
            ctx.move(to: pt(-w0, y0)); ctx.addLine(to: pt(w1, y1))
            ctx.move(to: pt(w0, y0)); ctx.addLine(to: pt(-w1, y1))
        }
        ctx.strokePath()
        // Fan of blades and the tail vane.
        let hub = pt(0, 86)
        ctx.setLineWidth(1.6 * k)
        for i in 0..<18 {
            let a = CGFloat(i) / 18 * .pi * 2
            ctx.move(to: CGPoint(x: hub.x + cos(a) * 4 * k, y: hub.y + sin(a) * 4 * k))
            ctx.addLine(to: CGPoint(x: hub.x + cos(a) * 18 * k, y: hub.y + sin(a) * 18 * k))
        }
        ctx.strokePath()
        ctx.fill(CGRect(x: hub.x - 26 * k, y: hub.y - 1.5 * k, width: 26 * k, height: 3 * k))
        ctx.fill(CGRect(x: hub.x - 32 * k, y: hub.y - 7 * k, width: 9 * k, height: 14 * k))
    }

    // MARK: Roadside textures

    private static func fenceTexture(width: CGFloat, k: CGFloat) -> SKTexture {
        Textures.texture(CGSize(width: width, height: 36 * k)) { ctx, s in
            ctx.setFillColor(UIColor(hex: 0x3b2a22).cgColor)
            ctx.fill(CGRect(x: s.width - 4 * k, y: 0, width: 4 * k, height: s.height))
            ctx.setStrokeColor(UIColor(hex: 0x2b211d, alpha: 0.8).cgColor)
            ctx.setLineWidth(max(0.6, 0.8 * k))
            for y in [7, 16, 25] as [CGFloat] {
                ctx.move(to: CGPoint(x: 0, y: y * k + 1 * k))
                ctx.addQuadCurve(to: CGPoint(x: s.width, y: y * k + 1 * k), control: CGPoint(x: s.width / 2, y: y * k + 3 * k))
            }
            ctx.strokePath()
        }
    }

    private static func windmillTexture(k: CGFloat) -> SKTexture {
        Textures.texture(CGSize(width: 70 * k, height: 112 * k)) { ctx, s in
            drawWindmill(ctx, base: CGPoint(x: s.width * 0.55, y: s.height), k: k, ink: UIColor(hex: 0x2b1d1e).cgColor)
        }
    }

    /// Prickly pear: a cluster of flat paddles.
    private static func cactusTexture(k: CGFloat) -> SKTexture {
        Textures.texture(CGSize(width: 46 * k, height: 44 * k)) { ctx, s in
            let pads: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [
                (23, 30, 12, 16, 0), (13, 20, 10, 13, -0.4), (33, 18, 10, 13, 0.4), (19, 9, 9, 12, -0.2), (29, 6, 8, 11, 0.3),
            ]
            for (x, y, rw, rh, a) in pads {
                ctx.saveGState()
                ctx.translateBy(x: x * k, y: s.height - y * k)
                ctx.rotate(by: a)
                let rect = CGRect(x: -rw * k / 2, y: -rh * k / 2, width: rw * k, height: rh * k)
                ctx.addEllipse(in: rect)
                ctx.clip()
                ctx.drawLinearGradient(Textures.gradient([UIColor(hex: 0x6f8f4a), UIColor(hex: 0x3a5530)]),
                                       start: CGPoint(x: rect.minX, y: rect.minY), end: CGPoint(x: rect.maxX, y: rect.maxY), options: [])
                ctx.restoreGState()
            }
            ctx.setFillColor(UIColor(hex: 0xe0446a).cgColor)
            ctx.fillEllipse(in: CGRect(x: 20 * k, y: s.height - 40 * k, width: 4 * k, height: 4 * k))
            ctx.fillEllipse(in: CGRect(x: 10 * k, y: s.height - 28 * k, width: 3.5 * k, height: 3.5 * k))
        }
    }

    private static func yuccaTexture(k: CGFloat) -> SKTexture {
        Textures.texture(CGSize(width: 40 * k, height: 60 * k)) { ctx, s in
            let base = CGPoint(x: s.width / 2, y: s.height - 2 * k)
            ctx.setStrokeColor(UIColor(hex: 0x4d6a3a).cgColor)
            ctx.setLineWidth(1.8 * k)
            ctx.setLineCap(.round)
            for i in 0..<15 {
                let a = -CGFloat.pi / 2 + (CGFloat(i) / 14 - 0.5) * 2.4
                let len = (18 + CGFloat((i * 5) % 7)) * k
                ctx.move(to: base)
                ctx.addLine(to: CGPoint(x: base.x + cos(a) * len, y: base.y + sin(a) * len))
            }
            ctx.strokePath()
            // Flower stalk.
            ctx.setStrokeColor(UIColor(hex: 0x6b5a3a).cgColor)
            ctx.move(to: base)
            ctx.addLine(to: CGPoint(x: base.x + 2 * k, y: 4 * k))
            ctx.strokePath()
            ctx.setFillColor(UIColor(hex: 0xf3ead2).cgColor)
            for j in 0..<5 {
                ctx.fillEllipse(in: CGRect(x: base.x - 1 * k + CGFloat(j % 2) * 3 * k, y: (4 + CGFloat(j) * 3) * k, width: 3 * k, height: 3 * k))
            }
        }
    }

    private static func tumbleweedTexture(k: CGFloat) -> SKTexture {
        Textures.texture(CGSize(width: 24 * k, height: 24 * k)) { ctx, s in
            let c = CGPoint(x: s.width / 2, y: s.height / 2)
            ctx.setStrokeColor(UIColor(hex: 0x9a7a4e).cgColor)
            ctx.setLineWidth(max(0.6, 0.9 * k))
            for i in 0..<14 {
                let a = CGFloat(i) * 0.9
                let r1 = 10 * k, r0 = CGFloat(i % 3) * 2 * k
                ctx.move(to: CGPoint(x: c.x + cos(a) * r0, y: c.y + sin(a) * r0))
                ctx.addQuadCurve(to: CGPoint(x: c.x + cos(a + 2.2) * r1, y: c.y + sin(a + 2.2) * r1),
                                 control: CGPoint(x: c.x + cos(a + 1) * r1 * 1.2, y: c.y + sin(a + 1) * r1 * 1.2))
            }
            ctx.strokePath()
            ctx.strokeEllipse(in: CGRect(x: c.x - 10 * k, y: c.y - 10 * k, width: 20 * k, height: 20 * k))
        }
    }
}
