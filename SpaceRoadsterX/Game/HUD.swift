import SpriteKit

enum Fonts {
    static let heavy = "AvenirNext-Heavy"
    static let bold = "AvenirNext-Bold"
    static let medium = "AvenirNext-DemiBold"
}

/// Score, best, air gauge and speed, laid out inside the safe area.
final class HUD: SKNode {
    private let score = SKLabelNode(fontNamed: Fonts.heavy)
    private let best = SKLabelNode(fontNamed: Fonts.bold)
    private let mph = SKLabelNode(fontNamed: Fonts.bold)
    private let airLabel = SKLabelNode(fontNamed: Fonts.bold)
    private let chain = SKLabelNode(fontNamed: Fonts.heavy)
    private let gaugeBack: SKShapeNode
    private let gaugeFill: SKSpriteNode
    private let gaugeWidth: CGFloat = 112
    private var lowAir = false

    override init() {
        gaugeBack = SKShapeNode(rect: CGRect(x: 0, y: -5, width: 112, height: 10), cornerRadius: 5)
        gaugeFill = SKSpriteNode(color: Palette.plume, size: CGSize(width: 108, height: 6))
        super.init()
        zPosition = 100
        for (label, size, color) in [(score, 34, Palette.paint), (best, 13, Palette.mute), (mph, 13, Palette.mute),
                                     (airLabel, 12, Palette.mute), (chain, 16, Palette.gold)] as [(SKLabelNode, CGFloat, UIColor)] {
            label.fontSize = size
            label.fontColor = color
            label.verticalAlignmentMode = .center
            addChild(label)
        }
        airLabel.text = "AIR"
        airLabel.horizontalAlignmentMode = .right
        mph.horizontalAlignmentMode = .right
        gaugeBack.fillColor = UIColor(white: 1, alpha: 0.12)
        gaugeBack.strokeColor = UIColor(white: 1, alpha: 0.25)
        gaugeBack.lineWidth = 1
        addChild(gaugeBack)
        gaugeFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        gaugeFill.position = CGPoint(x: 2, y: 0)
        gaugeFill.zPosition = 1
        gaugeBack.addChild(gaugeFill)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func layout(size: CGSize, safeTop: CGFloat) {
        let top = size.height - max(safeTop, 20)
        score.position = CGPoint(x: size.width / 2, y: top - 26)
        best.position = CGPoint(x: size.width / 2, y: top - 52)
        chain.position = CGPoint(x: size.width / 2, y: top - 76)
        gaugeBack.position = CGPoint(x: size.width - 16 - gaugeWidth, y: top - 22)
        airLabel.position = CGPoint(x: gaugeBack.position.x - 8, y: top - 22)
        mph.position = CGPoint(x: size.width - 16, y: top - 44)
    }

    func update(score s: Int, best b: Int, air: CGFloat, mph m: Int, chain c: Int) {
        score.text = "\(s)"
        best.text = "BEST \(b)"
        mph.text = "\(m) MPH"
        chain.text = c > 1 ? "FLIP CHAIN x\(min(c, Tune.maxFlipChain))" : ""
        gaugeFill.xScale = max(0.001, min(1, air))
        let low = air < 0.2
        if low != lowAir {
            lowAir = low
            gaugeFill.removeAllActions()
            if low {
                gaugeFill.color = Palette.ember
                gaugeFill.run(.repeatForever(.sequence([.fadeAlpha(to: 0.3, duration: 0.15), .fadeAlpha(to: 1, duration: 0.15)])))
            } else {
                gaugeFill.color = Palette.plume
                gaugeFill.alpha = 1
            }
        }
    }
}

enum Panel {
    /// Centered card for the start and crash screens.
    static func make(title: String, lines: [String], footer: String?, accent: UIColor, size: CGSize, footerDelay: TimeInterval = 0) -> SKNode {
        let node = SKNode()
        node.zPosition = 200
        let width = min(size.width - 48, 340)
        let height = CGFloat(96 + lines.count * 26 + (footer == nil ? 0 : 40))
        let card = SKShapeNode(rect: CGRect(x: -width / 2, y: -height / 2, width: width, height: height), cornerRadius: 18)
        card.fillColor = UIColor(red: 14 / 255, green: 18 / 255, blue: 34 / 255, alpha: 0.82)
        card.strokeColor = accent.withAlphaComponent(0.6)
        card.lineWidth = 1.5
        node.addChild(card)

        var y = height / 2 - 40
        let t = SKLabelNode(fontNamed: Fonts.heavy)
        t.text = title
        t.fontSize = 28
        t.fontColor = accent
        t.verticalAlignmentMode = .center
        t.position = CGPoint(x: 0, y: y)
        t.zPosition = 1
        node.addChild(t)
        y -= 44
        for line in lines {
            let l = SKLabelNode(fontNamed: Fonts.medium)
            l.text = line
            l.fontSize = 15
            l.fontColor = Palette.paint
            l.verticalAlignmentMode = .center
            l.position = CGPoint(x: 0, y: y)
            l.zPosition = 1
            node.addChild(l)
            y -= 26
        }
        if let footer {
            let f = SKLabelNode(fontNamed: Fonts.heavy)
            f.text = footer
            f.fontSize = 17
            f.fontColor = Palette.plume
            f.verticalAlignmentMode = .center
            f.position = CGPoint(x: 0, y: -height / 2 + 30)
            f.alpha = 0
            f.zPosition = 1
            node.addChild(f)
            f.run(.sequence([.wait(forDuration: footerDelay), .fadeIn(withDuration: 0.15),
                             .repeatForever(.sequence([.fadeAlpha(to: 0.45, duration: 0.6), .fadeAlpha(to: 1, duration: 0.6)]))]))
        }
        node.position = CGPoint(x: size.width / 2, y: size.height * 0.55)
        return node
    }
}
