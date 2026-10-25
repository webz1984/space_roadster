import SpriteKit

enum ObstacleKind {
    case car(CarModel)
    case hauler
    case barrier

    var crashReason: String {
        switch self {
        case .car(.wedgeTruck): return "You hit the Wedge Truck."
        case .car(let model): return "You rear-ended a \(model.displayName)."
        case .hauler: return "You hit the Hauler."
        case .barrier: return "You hit a barrier."
        }
    }
}

/// Anything on the road. Its node sits with its bottom-left corner on the road at `x`.
final class Obstacle {
    let kind: ObstacleKind
    let node = SKNode()
    let w: CGFloat
    let h: CGFloat
    var x: CGFloat = 0 { didSet { node.position.x = x } }
    var top: CGFloat = 0

    /// Smallest clearance seen while the car was airborne above it, for near-miss scoring.
    var minGap: CGFloat = .infinity
    var passed = false

    /// The Window Test: a bystander throws a steel ball at this truck as it rolls in.
    var thrower: SKSpriteNode?
    var thrown = false
    private(set) var sprite: SKSpriteNode

    init(kind: ObstacleKind, k: CGFloat, groundY: CGFloat) {
        self.kind = kind
        let tex: SKTexture
        switch kind {
        case .car(let model):
            tex = CarArt.texture(model, paint: Int.random(in: 0..<model.paints.count), k: k)
        case .hauler:
            tex = CarArt.hauler(k: k)
        case .barrier:
            tex = CarArt.barrier(k: k)
        }
        let body = SKSpriteNode(texture: tex)
        body.anchorPoint = .zero
        sprite = body
        w = tex.size().width
        h = tex.size().height
        top = groundY + h
        node.position.y = groundY
        node.addChild(sprite)
    }

    func addThrower(k: CGFloat) {
        let man = SKSpriteNode(texture: CarArt.thrower(k: k, throwing: false))
        man.anchorPoint = CGPoint(x: 0.5, y: 0)
        // Standing on the far shoulder just ahead of the truck's nose, a little behind it in depth.
        man.position = CGPoint(x: w + 14 * k, y: 4 * k)
        man.zPosition = -1
        man.alpha = 0.9
        node.addChild(man)
        thrower = man
    }

    /// Cracks the truck's window and swaps the thrower to his follow-through pose.
    func crackWindow(k: CGFloat) {
        thrown = true
        thrower?.texture = CarArt.thrower(k: k, throwing: true)
        let crack = SKSpriteNode(texture: CarArt.crack(k: k))
        crack.position = CGPoint(x: w * 0.56, y: h * 0.80)
        crack.zPosition = 1
        crack.setScale(0.2)
        node.addChild(crack)
        crack.run(.scale(to: 1, duration: 0.08))
    }
}

final class Canister {
    let node: SKNode
    var x: CGFloat { didSet { node.position.x = x } }
    let y: CGFloat
    var got = false

    init(x: CGFloat, y: CGFloat, k: CGFloat) {
        self.x = x
        self.y = y
        node = SKNode()
        node.position = CGPoint(x: x, y: y)
        let glow = SKSpriteNode(texture: Textures.softDot)
        glow.size = CGSize(width: 52 * k, height: 52 * k)
        glow.color = Palette.plume
        glow.colorBlendFactor = 1
        glow.alpha = 0.35
        glow.blendMode = .add
        node.addChild(glow)
        let can = SKSpriteNode(texture: CarArt.canister(k: k))
        can.zPosition = 1
        node.addChild(can)
        can.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 4 * k, duration: 0.5),
            .moveBy(x: 0, y: -4 * k, duration: 0.5),
        ])))
        glow.run(.repeatForever(.sequence([.fadeAlpha(to: 0.6, duration: 0.5), .fadeAlpha(to: 0.3, duration: 0.5)])))
    }
}

final class SteelBall {
    let node: SKSpriteNode
    let r: CGFloat
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var deflected = false

    init(x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat, k: CGFloat) {
        r = 6 * k
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
        node = SKSpriteNode(texture: CarArt.steelBall(radius: r))
        node.position = CGPoint(x: x, y: y)
        node.zPosition = 12
    }
}
