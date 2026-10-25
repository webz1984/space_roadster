import SpriteKit
import UIKit

/// Air-thrust effects modelled on the launch footage: two hard blue-white jets under the car,
/// a faint heat haze around them, road grit blasted outward when close to the ground, a
/// condensation puff when thrust cuts and a dust ring on landing.
///
/// Particles are emitted into `layer`, which the scene slides left with the road, so exhaust and
/// dust stay where they were blown instead of following the car.
final class ThrustFX {
    private let k: CGFloat
    private unowned let layer: SKNode
    private let jets: [SKEmitterNode]
    private let haze: SKEmitterNode
    private let groundDust: SKEmitterNode
    private let grit: SKEmitterNode

    init(k: CGFloat, car: SKNode, carSize: CGSize, layer: SKNode, scene: SKNode) {
        self.k = k
        self.layer = layer
        let nozzleY = -carSize.height / 2 + 4 * k
        jets = [CGFloat(-0.25), 0.22].map { (nx: CGFloat) -> SKEmitterNode in
            let e = ThrustFX.jet(k: k)
            e.position = CGPoint(x: nx * carSize.width, y: nozzleY)
            e.targetNode = layer
            e.zPosition = -1
            car.addChild(e)
            return e
        }
        haze = ThrustFX.haze(k: k)
        haze.position = CGPoint(x: 0, y: nozzleY - 10 * k)
        haze.targetNode = layer
        haze.zPosition = -2
        car.addChild(haze)

        groundDust = ThrustFX.dust(k: k)
        groundDust.targetNode = layer
        groundDust.zPosition = 6
        scene.addChild(groundDust)
        grit = ThrustFX.grit(k: k)
        grit.targetNode = layer
        grit.zPosition = 7
        scene.addChild(grit)
    }

    func remove() {
        jets.forEach { $0.removeFromParent() }
        haze.removeFromParent()
        groundDust.removeFromParent()
        grit.removeFromParent()
    }

    func reset() {
        update(on: false, intensity: 0, altitude: .infinity, ground: .zero)
        (jets + [haze, groundDust, grit]).forEach { $0.resetSimulation() }
    }

    /// - Parameters:
    ///   - intensity: 0...1, grows the longer the thrust is held.
    ///   - altitude: car bottom above the surface it is over, in points.
    ///   - ground: the point on the road under the car, in scene coordinates.
    func update(on: Bool, intensity: CGFloat, altitude: CGFloat, ground: CGPoint) {
        let i = max(0, min(1, intensity))
        for j in jets {
            j.particleBirthRate = on ? 260 + 220 * i : 0
            j.particleSpeed = (420 + 260 * i) * k
        }
        haze.particleBirthRate = on ? 26 + 30 * i : 0
        let reach = 150 * k
        let near = on ? max(0, 1 - altitude / reach) : 0
        groundDust.position = ground
        grit.position = ground
        groundDust.particleBirthRate = 180 * near
        grit.particleBirthRate = 140 * near
    }

    // MARK: One-shot bursts (scene coordinates in, drawn in the sliding layer)

    func takeoffBlast(at p: CGPoint) {
        burst(at: p, count: 46, life: 0.7, speed: 230, angle: .pi / 2, range: 2.6, color: UIColor(hex: 0xc9bfb2),
              alpha: 0.55, scale: 0.35, scaleSpeed: 1.4, yAccel: -180, blend: .alpha)
        burst(at: p, count: 24, life: 0.45, speed: 340, angle: .pi / 2, range: 2.2, color: UIColor(hex: 0xe8f9ff),
              alpha: 0.8, scale: 0.18, scaleSpeed: 0.2, yAccel: -600, blend: .add, texture: Textures.spark)
    }

    func cutoffPuff(at p: CGPoint) {
        burst(at: p, count: 22, life: 0.55, speed: 60, angle: -.pi / 2, range: 1.4, color: .white,
              alpha: 0.45, scale: 0.4, scaleSpeed: 1.6, yAccel: 40, blend: .alpha)
    }

    func landingRing(at p: CGPoint, hard: Bool) {
        burst(at: p, count: hard ? 34 : 18, life: 0.5, speed: hard ? 200 : 130, angle: .pi / 2, range: 2.9,
              color: UIColor(hex: 0xd8d2ca), alpha: 0.45, scale: 0.28, scaleSpeed: 1.1, yAccel: -120, blend: .alpha)
    }

    func canisterPop(at p: CGPoint) {
        burst(at: p, count: 20, life: 0.4, speed: 160, angle: 0, range: .pi * 2, color: Palette.plume,
              alpha: 0.9, scale: 0.2, scaleSpeed: -0.3, yAccel: 0, blend: .add, texture: Textures.spark)
    }

    func glassShatter(at p: CGPoint) {
        burst(at: p, count: 26, life: 0.6, speed: 180, angle: .pi / 2, range: 2.4, color: UIColor(hex: 0xdff7ff),
              alpha: 0.95, scale: 0.16, scaleSpeed: -0.1, yAccel: -700, blend: .add, texture: Textures.spark)
    }

    func explosion(at p: CGPoint) {
        burst(at: p, count: 60, life: 0.5, speed: 260, angle: 0, range: .pi * 2, color: Palette.ember,
              alpha: 0.95, scale: 0.6, scaleSpeed: 1.8, yAccel: 120, blend: .add)
        burst(at: p, count: 50, life: 1.2, speed: 120, angle: .pi / 2, range: 2.0, color: UIColor(hex: 0x3a3a46),
              alpha: 0.6, scale: 0.6, scaleSpeed: 1.4, yAccel: 90, blend: .alpha)
        burst(at: p, count: 70, life: 0.9, speed: 420, angle: .pi / 2, range: 2.8, color: UIColor(hex: 0xffe2b0),
              alpha: 1, scale: 0.22, scaleSpeed: -0.15, yAccel: -900, blend: .add, texture: Textures.spark)
        burst(at: p, count: 18, life: 1.1, speed: 320, angle: .pi / 2, range: 2.4, color: UIColor(hex: 0xe2e6ee),
              alpha: 1, scale: 0.5, scaleSpeed: 0, yAccel: -1100, blend: .alpha, texture: Textures.spark)
    }

    private func burst(at p: CGPoint, count: Int, life: CGFloat, speed: CGFloat, angle: CGFloat, range: CGFloat,
                       color: UIColor, alpha: CGFloat, scale: CGFloat, scaleSpeed: CGFloat, yAccel: CGFloat,
                       blend: SKBlendMode, texture: SKTexture = Textures.softDot) {
        let e = SKEmitterNode()
        e.particleTexture = texture
        e.numParticlesToEmit = count
        e.particleBirthRate = CGFloat(count) / 0.04
        e.particleLifetime = life
        e.particleLifetimeRange = life * 0.4
        e.particleSpeed = speed * k
        e.particleSpeedRange = speed * k * 0.6
        e.emissionAngle = angle
        e.emissionAngleRange = range
        e.particleAlpha = alpha
        e.particleAlphaSpeed = -alpha / life
        e.particleScale = scale * k
        e.particleScaleRange = scale * k * 0.4
        e.particleScaleSpeed = scaleSpeed * k
        e.particleColor = color
        e.particleColorBlendFactor = 1
        e.particleBlendMode = blend
        e.yAcceleration = yAccel * k
        e.particlePositionRange = CGVector(dx: 14 * k, dy: 2 * k)
        if let scene = layer.scene { e.position = layer.convert(p, from: scene) } else { e.position = p }
        layer.addChild(e)
        e.run(.sequence([.wait(forDuration: TimeInterval(life * 1.5) + 0.2), .removeFromParent()]))
    }

    // MARK: Emitter recipes

    private static func jet(k: CGFloat) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = Textures.softDot
        e.particleBirthRate = 0
        e.particleLifetime = 0.2
        e.particleLifetimeRange = 0.08
        e.emissionAngle = -.pi / 2
        e.emissionAngleRange = 0.22
        e.particleSpeed = 480 * k
        e.particleSpeedRange = 140 * k
        e.particleAlpha = 0.95
        e.particleAlphaSpeed = -4.2
        e.particleScale = 0.14 * k
        e.particleScaleRange = 0.05 * k
        e.particleScaleSpeed = 1.9 * k
        e.particleColorBlendFactor = 1
        e.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [UIColor.white, UIColor(hex: 0xbff1ff), UIColor(hex: 0x7fe3ff), UIColor(hex: 0x7fe3ff, alpha: 0)],
            times: [0, 0.15, 0.5, 1])
        e.particleBlendMode = .add
        e.particlePositionRange = CGVector(dx: 4 * k, dy: 0)
        return e
    }

    /// Large faint particles that read as shimmering hot air around the jets.
    private static func haze(k: CGFloat) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = Textures.softDot
        e.particleBirthRate = 0
        e.particleLifetime = 0.45
        e.emissionAngle = -.pi / 2
        e.emissionAngleRange = 0.6
        e.particleSpeed = 160 * k
        e.particleSpeedRange = 60 * k
        e.particleAlpha = 0.09
        e.particleAlphaSpeed = -0.18
        e.particleScale = 1.4 * k
        e.particleScaleSpeed = 2.4 * k
        e.particleColor = UIColor(hex: 0xe8fbff)
        e.particleColorBlendFactor = 1
        e.particleBlendMode = .add
        e.particlePositionRange = CGVector(dx: 50 * k, dy: 6 * k)
        return e
    }

    private static func dust(k: CGFloat) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = Textures.softDot
        e.particleBirthRate = 0
        e.particleLifetime = 0.7
        e.particleLifetimeRange = 0.3
        e.emissionAngle = .pi / 2
        e.emissionAngleRange = 2.7
        e.particleSpeed = 190 * k
        e.particleSpeedRange = 90 * k
        e.yAcceleration = -160 * k
        e.particleAlpha = 0.42
        e.particleAlphaSpeed = -0.6
        e.particleScale = 0.4 * k
        e.particleScaleRange = 0.2 * k
        e.particleScaleSpeed = 1.3 * k
        e.particleColor = UIColor(hex: 0xc4b8aa)
        e.particleColorBlendFactor = 1
        e.particleBlendMode = .alpha
        e.particlePositionRange = CGVector(dx: 40 * k, dy: 2 * k)
        return e
    }

    private static func grit(k: CGFloat) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = Textures.spark
        e.particleBirthRate = 0
        e.particleLifetime = 0.5
        e.particleLifetimeRange = 0.2
        e.emissionAngle = .pi / 2
        e.emissionAngleRange = 2.2
        e.particleSpeed = 320 * k
        e.particleSpeedRange = 140 * k
        e.yAcceleration = -900 * k
        e.particleAlpha = 0.85
        e.particleAlphaSpeed = -1.4
        e.particleScale = 0.22 * k
        e.particleScaleRange = 0.1 * k
        e.particleColor = UIColor(hex: 0xe9e2d6)
        e.particleColorBlendFactor = 1
        e.particleBlendMode = .alpha
        e.particlePositionRange = CGVector(dx: 30 * k, dy: 0)
        return e
    }
}
