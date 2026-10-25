import SpriteKit
import UIKit

/// Every car in the game. The names are original; the shapes nod to famous EVs and supercars
/// without copying any badge, logo or exact body line.
enum CarModel: CaseIterable {
    case roadsterX, voltSedan, voltGrand, voltCrossover, voltFalcon, wedgeTruck, toroV12, rossoGT

    var displayName: String {
        switch self {
        case .roadsterX: return "RoadsterX"
        case .voltSedan: return "Volt Sedan"
        case .voltGrand: return "Volt Grand"
        case .voltCrossover: return "Volt Crossover"
        case .voltFalcon: return "Volt Falcon"
        case .wedgeTruck: return "Wedge Truck"
        case .toroV12: return "Toro V12"
        case .rossoGT: return "Rosso GT"
        }
    }

    /// Low enough to hop across in a three-car lineup.
    static let lowTraffic: [CarModel] = [.voltSedan, .voltGrand, .toroV12, .rossoGT]
    static let traffic: [CarModel] = [.voltSedan, .voltGrand, .voltCrossover, .voltFalcon, .wedgeTruck, .toroV12, .rossoGT]

    var paints: [UIColor] {
        switch self {
        case .roadsterX: return [UIColor(hex: 0xc8101e)]
        case .wedgeTruck: return [UIColor(hex: 0xaeb3b8)]
        case .toroV12: return [UIColor(hex: 0xf7c518), UIColor(hex: 0x5cc23a), UIColor(hex: 0xf2711c)]
        case .rossoGT: return [UIColor(hex: 0xcc0d12), UIColor(hex: 0xffd417)]
        default:
            return [UIColor(hex: 0xedeef2), UIColor(hex: 0x5c6068), UIColor(hex: 0x1f3a7a),
                    UIColor(hex: 0x16171b), UIColor(hex: 0xb4101a), UIColor(hex: 0x3d4046)]
        }
    }

    var spec: CarSpec {
        // Points are normalised: x runs rear (0) to nose (1), y runs roof (0) to wheel contact (1).
        switch self {
        case .roadsterX:
            return CarSpec(length: 82, height: 26, smooth: true,
                           body: [(0.03, 0.80), (0.0, 0.52), (0.05, 0.40), (0.30, 0.36), (0.44, 0.30), (0.52, 0.06),
                                  (0.64, 0.04), (0.76, 0.30), (0.93, 0.40), (1.0, 0.56), (0.99, 0.80)],
                           glass: [(0.47, 0.31), (0.53, 0.11), (0.63, 0.09), (0.73, 0.31)],
                           wheels: [0.19, 0.81], wheelRadius: 0.27, lightY: 0.50)
        case .voltSedan:
            return CarSpec(length: 92, height: 34, smooth: true,
                           body: [(0.02, 0.76), (0.0, 0.48), (0.06, 0.38), (0.20, 0.35), (0.33, 0.08), (0.55, 0.03),
                                  (0.74, 0.30), (0.93, 0.40), (1.0, 0.56), (0.99, 0.76)],
                           glass: [(0.24, 0.35), (0.35, 0.11), (0.54, 0.07), (0.71, 0.32)],
                           wheels: [0.18, 0.80], wheelRadius: 0.25, lightY: 0.47)
        case .voltGrand:
            return CarSpec(length: 104, height: 36, smooth: true,
                           body: [(0.02, 0.76), (0.0, 0.48), (0.05, 0.38), (0.18, 0.34), (0.32, 0.07), (0.58, 0.03),
                                  (0.76, 0.30), (0.93, 0.40), (1.0, 0.56), (0.99, 0.76)],
                           glass: [(0.22, 0.34), (0.34, 0.10), (0.57, 0.07), (0.73, 0.32)],
                           wheels: [0.17, 0.81], wheelRadius: 0.24, lightY: 0.47)
        case .voltCrossover:
            return CarSpec(length: 96, height: 44, smooth: true,
                           body: [(0.02, 0.78), (0.0, 0.42), (0.04, 0.30), (0.14, 0.24), (0.28, 0.05), (0.56, 0.01),
                                  (0.76, 0.28), (0.93, 0.38), (1.0, 0.55), (0.99, 0.78)],
                           glass: [(0.17, 0.25), (0.30, 0.08), (0.55, 0.05), (0.73, 0.30)],
                           wheels: [0.18, 0.80], wheelRadius: 0.22, lightY: 0.46)
        case .voltFalcon:
            return CarSpec(length: 104, height: 46, smooth: true,
                           body: [(0.02, 0.78), (0.0, 0.40), (0.04, 0.27), (0.14, 0.20), (0.26, 0.03), (0.58, 0.0),
                                  (0.77, 0.27), (0.93, 0.37), (1.0, 0.55), (0.99, 0.78)],
                           glass: [(0.17, 0.22), (0.28, 0.06), (0.57, 0.04), (0.74, 0.29)],
                           wheels: [0.18, 0.81], wheelRadius: 0.21, lightY: 0.45)
        case .wedgeTruck:
            return CarSpec(length: 122, height: 50, smooth: false,
                           body: [(0.0, 0.76), (0.0, 0.36), (0.50, 0.0), (1.0, 0.32), (1.0, 0.60), (0.97, 0.76)],
                           glass: [(0.31, 0.22), (0.50, 0.06), (0.70, 0.17), (0.69, 0.24), (0.33, 0.27)],
                           wheels: [0.17, 0.83], wheelRadius: 0.24, lightY: 0.34)
        case .toroV12:
            return CarSpec(length: 92, height: 26, smooth: false,
                           body: [(0.02, 0.78), (0.0, 0.50), (0.10, 0.38), (0.36, 0.30), (0.50, 0.06), (0.60, 0.06),
                                  (0.80, 0.32), (1.0, 0.50), (0.99, 0.78)],
                           glass: [(0.42, 0.30), (0.51, 0.11), (0.59, 0.11), (0.76, 0.33)],
                           wheels: [0.19, 0.80], wheelRadius: 0.29, lightY: 0.52)
        case .rossoGT:
            return CarSpec(length: 90, height: 28, smooth: true,
                           body: [(0.02, 0.78), (0.0, 0.48), (0.08, 0.36), (0.30, 0.30), (0.42, 0.08), (0.58, 0.05),
                                  (0.70, 0.30), (0.88, 0.36), (1.0, 0.54), (0.99, 0.78)],
                           glass: [(0.36, 0.30), (0.44, 0.12), (0.57, 0.09), (0.67, 0.31)],
                           wheels: [0.19, 0.80], wheelRadius: 0.28, lightY: 0.50)
        }
    }
}

struct CarSpec {
    let length: CGFloat
    let height: CGFloat
    let smooth: Bool
    let body: [(CGFloat, CGFloat)]
    let glass: [(CGFloat, CGFloat)]
    let wheels: [CGFloat]
    let wheelRadius: CGFloat
    let lightY: CGFloat
}

/// Draws cars and roadside props into textures. Everything is vector-drawn at the device's
/// pixel density, so it stays sharp on every iPhone. Swap in pre-rendered 3D sprites later
/// by returning image textures from here; the game code only sees `SKTexture`s.
enum CarArt {
    private static var cache: [String: SKTexture] = [:]

    static func texture(_ model: CarModel, paint: Int, k: CGFloat) -> SKTexture {
        let key = "\(model)-\(paint)-\(Int(k * 100))"
        if let tex = cache[key] { return tex }
        let spec = model.spec
        let color = model.paints[paint % model.paints.count]
        let tex = Textures.texture(CGSize(width: spec.length * k, height: spec.height * k)) { ctx, size in
            drawCar(ctx, size: size, spec: spec, paint: color, k: k, stainless: model == .wedgeTruck)
        }
        cache[key] = tex
        return tex
    }

    // MARK: Cars

    private static func path(_ pts: [(CGFloat, CGFloat)], size: CGSize, smooth: Bool) -> CGPath {
        let p = pts.map { CGPoint(x: $0.0 * size.width, y: $0.1 * size.height) }
        let path = CGMutablePath()
        guard p.count > 2 else { return path }
        if !smooth {
            path.addLines(between: p)
            path.closeSubpath()
            return path
        }
        // Round every corner by curving through the midpoints of each edge.
        func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint { CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2) }
        path.move(to: mid(p[p.count - 1], p[0]))
        for i in 0..<p.count {
            path.addQuadCurve(to: mid(p[i], p[(i + 1) % p.count]), control: p[i])
        }
        path.closeSubpath()
        return path
    }

    private static func drawCar(_ ctx: CGContext, size: CGSize, spec: CarSpec, paint: UIColor, k: CGFloat, stainless: Bool) {
        let W = size.width, H = size.height
        let body = path(spec.body, size: size, smooth: spec.smooth)
        let glass = path(spec.glass, size: size, smooth: spec.smooth)
        let r = spec.wheelRadius * H
        let roofY = (spec.body.map { $0.1 }.min() ?? 0) * H
        let sillY = (spec.body.map { $0.1 }.max() ?? 1) * H

        // Paint: light on top, deep below, like a car lit by a low sun.
        ctx.saveGState()
        ctx.addPath(body)
        ctx.clip()
        let paintColors = stainless
            ? [paint.shaded(0.25), paint, paint.shaded(-0.12), paint.shaded(-0.35)]
            : [paint.shaded(0.22), paint, paint.shaded(-0.18), paint.shaded(-0.42)]
        ctx.drawLinearGradient(Textures.gradient(paintColors, locations: [0, 0.35, 0.7, 1]),
                               start: CGPoint(x: 0, y: roofY), end: CGPoint(x: 0, y: sillY), options: [])
        // Clear-coat sheen along the shoulder.
        ctx.drawLinearGradient(Textures.gradient([UIColor.white.withAlphaComponent(0), UIColor.white.withAlphaComponent(0.35),
                                                  UIColor.white.withAlphaComponent(0)], locations: [0, 0.5, 1]),
                               start: CGPoint(x: 0, y: roofY + (sillY - roofY) * 0.30),
                               end: CGPoint(x: 0, y: roofY + (sillY - roofY) * 0.55), options: [])
        // Warm sunset bounce on the rear, cool sky on the nose.
        ctx.drawLinearGradient(Textures.gradient([UIColor(hex: 0xff9a5a, alpha: 0.22), UIColor(hex: 0xff9a5a, alpha: 0),
                                                  UIColor(hex: 0x7fe3ff, alpha: 0), UIColor(hex: 0x7fe3ff, alpha: 0.12)],
                                                 locations: [0, 0.3, 0.7, 1]),
                               start: .zero, end: CGPoint(x: W, y: 0), options: [])
        // Character line.
        ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.22).cgColor)
        ctx.setLineWidth(max(0.6, 0.8 * k))
        ctx.move(to: CGPoint(x: W * 0.06, y: roofY + (sillY - roofY) * 0.62))
        ctx.addLine(to: CGPoint(x: W * 0.94, y: roofY + (sillY - roofY) * 0.58))
        ctx.strokePath()
        // Wheel arches.
        ctx.setFillColor(UIColor(hex: 0x07080c).cgColor)
        for wx in spec.wheels {
            ctx.fillEllipse(in: CGRect(x: wx * W - r * 1.16, y: H - r - r * 1.16, width: r * 2.32, height: r * 2.32))
        }
        ctx.restoreGState()

        // Glass with a sky reflection streak.
        ctx.saveGState()
        ctx.addPath(glass)
        ctx.clip()
        ctx.drawLinearGradient(Textures.gradient([UIColor(hex: 0x3a4766), UIColor(hex: 0x141a2b), UIColor(hex: 0x0b0e18)],
                                                 locations: [0, 0.5, 1]),
                               start: CGPoint(x: 0, y: roofY), end: CGPoint(x: 0, y: roofY + (sillY - roofY) * 0.5), options: [])
        ctx.setFillColor(UIColor.white.withAlphaComponent(0.22).cgColor)
        let gb = glass.boundingBox
        ctx.move(to: CGPoint(x: gb.minX + gb.width * 0.30, y: gb.maxY))
        ctx.addLine(to: CGPoint(x: gb.minX + gb.width * 0.48, y: gb.minY))
        ctx.addLine(to: CGPoint(x: gb.minX + gb.width * 0.60, y: gb.minY))
        ctx.addLine(to: CGPoint(x: gb.minX + gb.width * 0.42, y: gb.maxY))
        ctx.fillPath()
        ctx.restoreGState()

        // Outline keeps light paint readable against the sky.
        ctx.addPath(body)
        ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.4).cgColor)
        ctx.setLineWidth(max(0.6, 0.9 * k))
        ctx.strokePath()

        // Lights: a full-width style bar at the back, a slim LED strip at the nose.
        let ly = spec.lightY * H
        ctx.setFillColor(UIColor(hex: 0xff2a36).cgColor)
        ctx.fill(CGRect(x: 0, y: ly - 1.6 * k, width: max(1.5, 2.2 * k), height: 3.2 * k))
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 4 * k, color: UIColor(hex: 0xdff7ff).cgColor)
        ctx.setFillColor(UIColor(hex: 0xf4fbff).cgColor)
        ctx.fill(CGRect(x: W - 6 * k, y: ly - 1.2 * k, width: 6 * k, height: 2.2 * k))
        ctx.restoreGState()

        for wx in spec.wheels { drawWheel(ctx, center: CGPoint(x: wx * W, y: H - r), r: r, k: k) }
    }

    private static func drawWheel(_ ctx: CGContext, center c: CGPoint, r: CGFloat, k: CGFloat) {
        ctx.setFillColor(UIColor(hex: 0x0b0c10).cgColor)
        ctx.fillEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        // Sidewall highlight.
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.08).cgColor)
        ctx.setLineWidth(max(0.5, 0.6 * k))
        ctx.strokeEllipse(in: CGRect(x: c.x - r * 0.86, y: c.y - r * 0.86, width: r * 1.72, height: r * 1.72))
        let rim = r * 0.64
        ctx.saveGState()
        ctx.addEllipse(in: CGRect(x: c.x - rim, y: c.y - rim, width: rim * 2, height: rim * 2))
        ctx.clip()
        ctx.drawRadialGradient(Textures.gradient([UIColor(hex: 0xd9dde4), UIColor(hex: 0x8a909c), UIColor(hex: 0x3b3f47)],
                                                 locations: [0, 0.6, 1]),
                               startCenter: CGPoint(x: c.x - rim * 0.3, y: c.y - rim * 0.3), startRadius: 0,
                               endCenter: c, endRadius: rim, options: [])
        ctx.restoreGState()
        // Aero spokes.
        ctx.setStrokeColor(UIColor(hex: 0x23262d).cgColor)
        ctx.setLineWidth(max(0.6, rim * 0.16))
        for i in 0..<5 {
            let a = CGFloat(i) / 5 * .pi * 2 + 0.3
            ctx.move(to: CGPoint(x: c.x + cos(a) * rim * 0.22, y: c.y + sin(a) * rim * 0.22))
            ctx.addLine(to: CGPoint(x: c.x + cos(a + 0.35) * rim * 0.92, y: c.y + sin(a + 0.35) * rim * 0.92))
        }
        ctx.strokePath()
        ctx.setFillColor(UIColor(hex: 0x1a1c21).cgColor)
        ctx.fillEllipse(in: CGRect(x: c.x - rim * 0.18, y: c.y - rim * 0.18, width: rim * 0.36, height: rim * 0.36))
    }

    // MARK: Hauler (electric semi)

    static func hauler(k: CGFloat) -> SKTexture {
        let key = "hauler-\(Int(k * 100))"
        if let tex = cache[key] { return tex }
        let tex = Textures.texture(CGSize(width: 236 * k, height: 94 * k)) { ctx, size in
            let W = size.width, H = size.height
            let r = H * 0.12
            let trailer = CGRect(x: 0, y: 0, width: W * 0.75, height: H * 0.80)
            ctx.saveGState()
            ctx.addPath(CGPath(roundedRect: trailer, cornerWidth: 3 * k, cornerHeight: 3 * k, transform: nil))
            ctx.clip()
            ctx.drawLinearGradient(Textures.gradient([UIColor(hex: 0xf3f4f7), UIColor(hex: 0xd4d8e0), UIColor(hex: 0x9097a6)],
                                                     locations: [0, 0.6, 1]),
                                   start: .zero, end: CGPoint(x: 0, y: trailer.maxY), options: [])
            // Panel seams.
            ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.10).cgColor)
            ctx.setLineWidth(max(0.5, 0.7 * k))
            var x: CGFloat = 14 * k
            while x < trailer.maxX {
                ctx.move(to: CGPoint(x: x, y: 2 * k)); ctx.addLine(to: CGPoint(x: x, y: trailer.maxY - 6 * k))
                x += 14 * k
            }
            ctx.strokePath()
            // Livery stripe.
            ctx.setFillColor(UIColor(hex: 0x1f2433).cgColor)
            ctx.fill(CGRect(x: 0, y: trailer.maxY * 0.58, width: trailer.width, height: 7 * k))
            ctx.setFillColor(UIColor(hex: 0x7fe3ff).cgColor)
            ctx.fill(CGRect(x: 0, y: trailer.maxY * 0.58 + 7 * k, width: trailer.width, height: 1.6 * k))
            ctx.restoreGState()

            // Cab: tall, smooth, bullet nose.
            let cab: [(CGFloat, CGFloat)] = [(0.765, 0.90), (0.765, 0.20), (0.80, 0.12), (0.90, 0.13), (0.98, 0.40),
                                             (1.0, 0.62), (1.0, 0.86), (0.985, 0.90)]
            let cabPath = path(cab, size: size, smooth: true)
            ctx.saveGState()
            ctx.addPath(cabPath)
            ctx.clip()
            ctx.drawLinearGradient(Textures.gradient([UIColor(hex: 0xf7f8fa), UIColor(hex: 0xc9ced8), UIColor(hex: 0x7f8696)],
                                                     locations: [0, 0.55, 1]),
                                   start: CGPoint(x: 0, y: H * 0.12), end: CGPoint(x: 0, y: H * 0.9), options: [])
            ctx.restoreGState()
            ctx.addPath(cabPath)
            ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.35).cgColor)
            ctx.setLineWidth(max(0.6, 0.9 * k))
            ctx.strokePath()
            let windshield = path([(0.81, 0.17), (0.895, 0.17), (0.955, 0.40), (0.80, 0.40)], size: size, smooth: true)
            ctx.addPath(windshield)
            ctx.setFillColor(UIColor(hex: 0x141a2b).cgColor)
            ctx.fillPath()
            ctx.setFillColor(UIColor(hex: 0xf4fbff).cgColor)
            ctx.fill(CGRect(x: W - 7 * k, y: H * 0.64, width: 7 * k, height: 2.4 * k))

            for wx: CGFloat in [0.07, 0.15, 0.62, 0.70, 0.83, 0.95] {
                drawWheel(ctx, center: CGPoint(x: wx * W, y: H - r), r: r, k: k)
            }
        }
        cache[key] = tex
        return tex
    }

    // MARK: Props

    static func barrier(k: CGFloat) -> SKTexture {
        let key = "barrier-\(Int(k * 100))"
        if let tex = cache[key] { return tex }
        let tex = Textures.texture(CGSize(width: 24 * k, height: 50 * k)) { ctx, size in
            let W = size.width, H = size.height
            // Legs and feet.
            ctx.setFillColor(UIColor(hex: 0x2b2f3a).cgColor)
            ctx.fill(CGRect(x: W * 0.15, y: H * 0.15, width: W * 0.14, height: H * 0.8))
            ctx.fill(CGRect(x: W * 0.71, y: H * 0.15, width: W * 0.14, height: H * 0.8))
            ctx.fill(CGRect(x: 0, y: H * 0.93, width: W, height: H * 0.07))
            // Striped boards.
            for (i, y) in [CGFloat(0.16), 0.46].enumerated() {
                let board = CGRect(x: 0, y: H * y, width: W, height: H * 0.2)
                ctx.saveGState()
                ctx.clip(to: board)
                ctx.setFillColor(UIColor(hex: 0xf4f4f0).cgColor)
                ctx.fill(board)
                ctx.setFillColor(UIColor(hex: 0xff6a1a).cgColor)
                var x: CGFloat = -W + CGFloat(i) * 4 * k
                while x < W * 2 {
                    ctx.move(to: CGPoint(x: x, y: board.maxY))
                    ctx.addLine(to: CGPoint(x: x + 6 * k, y: board.maxY))
                    ctx.addLine(to: CGPoint(x: x + 6 * k + board.height, y: board.minY))
                    ctx.addLine(to: CGPoint(x: x + board.height, y: board.minY))
                    ctx.fillPath()
                    x += 12 * k
                }
                ctx.restoreGState()
            }
            // Amber lamp.
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: 5 * k, color: UIColor(hex: 0xffb020).cgColor)
            ctx.setFillColor(UIColor(hex: 0xffc23a).cgColor)
            ctx.fillEllipse(in: CGRect(x: W / 2 - 3.5 * k, y: 0.5 * k, width: 7 * k, height: 7 * k))
            ctx.restoreGState()
        }
        cache[key] = tex
        return tex
    }

    static func canister(k: CGFloat) -> SKTexture {
        let key = "can-\(Int(k * 100))"
        if let tex = cache[key] { return tex }
        let tex = Textures.texture(CGSize(width: 16 * k, height: 28 * k)) { ctx, size in
            let body = CGRect(x: 1 * k, y: 1 * k, width: size.width - 2 * k, height: size.height - 2 * k)
            ctx.saveGState()
            ctx.addPath(CGPath(roundedRect: body, cornerWidth: 6 * k, cornerHeight: 6 * k, transform: nil))
            ctx.clip()
            ctx.drawLinearGradient(Textures.gradient([UIColor(hex: 0x3fb6d8), UIColor(hex: 0xc9f6ff), UIColor(hex: 0x2a8fb0)],
                                                     locations: [0, 0.45, 1]),
                                   start: CGPoint(x: body.minX, y: 0), end: CGPoint(x: body.maxX, y: 0), options: [])
            ctx.setFillColor(Palette.night.cgColor)
            ctx.fill(CGRect(x: 0, y: size.height * 0.46, width: size.width, height: 3 * k))
            ctx.restoreGState()
        }
        cache[key] = tex
        return tex
    }

    static func steelBall(radius r: CGFloat) -> SKTexture {
        Textures.texture(CGSize(width: r * 2, height: r * 2)) { ctx, size in
            let c = CGPoint(x: r, y: r)
            ctx.drawRadialGradient(Textures.gradient([.white, UIColor(hex: 0xb9bec7), UIColor(hex: 0x3c4048)], locations: [0, 0.45, 1]),
                                   startCenter: CGPoint(x: r * 0.7, y: r * 0.65), startRadius: 0,
                                   endCenter: c, endRadius: r, options: [])
        }
    }

    /// The bystander who throws the steel ball. Drawn as a dark silhouette on the far shoulder.
    static func thrower(k: CGFloat, throwing: Bool) -> SKTexture {
        Textures.texture(CGSize(width: 18 * k, height: 34 * k)) { ctx, size in
            let W = size.width, H = size.height
            ctx.setFillColor(UIColor(hex: 0x14172a).cgColor)
            ctx.fillEllipse(in: CGRect(x: W * 0.36, y: 0, width: 6 * k, height: 6 * k))
            ctx.fill(CGRect(x: W * 0.33, y: 6.5 * k, width: 7 * k, height: H * 0.42))
            ctx.fill(CGRect(x: W * 0.35, y: H * 0.6, width: 2.6 * k, height: H * 0.4))
            ctx.fill(CGRect(x: W * 0.52, y: H * 0.6, width: 2.6 * k, height: H * 0.4))
            ctx.setStrokeColor(UIColor(hex: 0x14172a).cgColor)
            ctx.setLineWidth(2.4 * k)
            ctx.setLineCap(.round)
            ctx.move(to: CGPoint(x: W * 0.5, y: 9 * k))
            if throwing {
                ctx.addLine(to: CGPoint(x: W * 0.05, y: 2 * k))
            } else {
                ctx.addLine(to: CGPoint(x: W * 0.95, y: 3 * k))
            }
            ctx.strokePath()
        }
    }

    static func crack(k: CGFloat) -> SKTexture {
        Textures.texture(CGSize(width: 22 * k, height: 14 * k)) { ctx, size in
            let c = CGPoint(x: size.width * 0.55, y: size.height * 0.5)
            ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.9).cgColor)
            ctx.setLineWidth(max(0.5, 0.7 * k))
            for i in 0..<9 {
                let a = CGFloat(i) / 9 * .pi * 2 + 0.2
                let len = size.width * (0.28 + 0.18 * CGFloat((i * 7) % 3) / 2)
                ctx.move(to: c)
                ctx.addLine(to: CGPoint(x: c.x + cos(a) * len * 0.5, y: c.y + sin(a) * len * 0.45))
                ctx.addLine(to: CGPoint(x: c.x + cos(a + 0.15) * len, y: c.y + sin(a + 0.15) * len * 0.8))
            }
            ctx.strokePath()
            ctx.strokeEllipse(in: CGRect(x: c.x - 2.5 * k, y: c.y - 2 * k, width: 5 * k, height: 4 * k))
        }
    }
}
