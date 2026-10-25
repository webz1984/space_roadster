import CoreGraphics
import Foundation

/// Feel numbers ported from the browser prototype. Distances are points at a 400 x 800
/// reference screen and get multiplied by the scene's scale factor `k`.
enum Tune {
    static let gravity: CGFloat = 2200
    static let thrust: CGFloat = 4300
    static let maxRise: CGFloat = 950

    /// A full tank is 2 s of thrust; the road refills it from empty in about 5.5 s.
    static let airDrain: CGFloat = 0.5
    static let airRefill: CGFloat = 0.18
    static let roofRefillMultiplier: CGFloat = 2
    static let canisterAir: CGFloat = 0.35

    /// Slower ramp than the prototype so top speed lands near 75 s.
    static let startSpeed: CGFloat = 260
    static let maxSpeed: CGFloat = 620
    static let speedRamp: CGFloat = 4.8
    static let mphPerUnit: CGFloat = 0.42
    static let idleSpeed: CGFloat = 120

    static let flipDuration: CGFloat = 0.55
    /// Landing after this much of the rotation still counts as a clean flip.
    static let flipForgive: CGFloat = 0.85
    static let swipeDistance: CGFloat = 40
    static let swipeWindow: TimeInterval = 0.4
    static let maxFlipChain = 5

    static let flipPoints = 250
    static let roofPoints = 100
    static let canisterPoints = 50
    static let nearMissPoints = 25
    static let armorGlassPoints = 300
    static let nearMissGap: CGFloat = 16

    static let ballGravity: CGFloat = 900
    static let retryDelay: TimeInterval = 0.6
}
