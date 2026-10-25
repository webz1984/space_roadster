import SpriteKit

/// Thrust Hop, the core run: hold to fire the thrusters, release to drop, swipe up to flip.
/// The physics and spawn rules are a direct port of the browser prototype, flipped to
/// SpriteKit's y-up coordinates. `y` is the car's wheel line; `gy` is the road.
final class GameScene: SKScene {
    enum State { case ready, play, over }

    var onStateChange: ((State) -> Void)?
    var safeTop: CGFloat = 47 {
        didSet { hud?.layout(size: size, safeTop: safeTop) }
    }

    private(set) var state: State = .ready {
        didSet { if oldValue != state { onStateChange?(state) } }
    }

    private let sound = SoundEngine.shared
    private let haptics = Haptics.shared

    // Layout
    private var k: CGFloat = 1
    private var gy: CGFloat = 0
    private var carLen: CGFloat = 82
    private var carH: CGFloat = 26
    private var cx: CGFloat = 0

    // Run
    private var y: CGFloat = 0
    private var vy: CGFloat = 0
    private var air: CGFloat = 1
    private var speed: CGFloat = Tune.startSpeed
    private var dist: CGFloat = 0
    private var t: CGFloat = 0
    private var scroll: CGFloat = 0
    private var bonus = 0
    private var score = 0
    private var best = UserDefaults.standard.integer(forKey: "best")
    private var flips = 0
    private var chain = 0
    private var grounded = true
    private var flipping = false
    private var flipT: CGFloat = 0
    private var rot: CGFloat = 0
    private var nextGap: CGFloat = 0
    private var overT: TimeInterval = 0
    private var reason = ""
    private var thrusting = false
    private var holdTime: CGFloat = 0

    private var obstacles: [Obstacle] = []
    private var cans: [Canister] = []
    private var balls: [SteelBall] = []

    // Input
    private var holding = false
    private var activeTouch: UITouch?
    private var touchStart: CGPoint = .zero
    private var touchStartTime: TimeInterval = 0
    private var swiped = false
    private var lastTime: TimeInterval = 0

    // Nodes
    private var backdrop: Backdrop?
    private let world = SKNode()
    private let fxLayer = SKNode()
    private let carNode = SKNode()
    private let shadow = SKShapeNode()
    private var fx: ThrustFX?
    private var hud: HUD?
    private var panel: SKNode?
    private var built = false

    override func didMove(to view: SKView) {
        backgroundColor = Palette.night
        view.isMultipleTouchEnabled = false
        guard !built else { return }
        built = true
        world.zPosition = 0
        fxLayer.zPosition = 8
        carNode.zPosition = 10
        shadow.zPosition = -10
        shadow.strokeColor = .clear
        [world, fxLayer, shadow, carNode].forEach(addChild)
        relayout()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard built, size.width > 0, size.height > 0, size != oldSize else { return }
        relayout()
    }

    private func relayout() {
        k = min(size.width / 400, size.height / 800)
        gy = (size.height * 0.26).rounded()
        cx = size.width * 0.26

        backdrop?.removeFromParent()
        let bd = Backdrop(size: size, groundY: gy, k: k)
        addChild(bd)
        backdrop = bd

        carNode.removeAllChildren()
        let tex = CarArt.texture(.roadsterX, paint: 0, k: k)
        carLen = tex.size().width
        carH = tex.size().height
        carNode.addChild(SKSpriteNode(texture: tex))

        fx?.remove()
        fx = ThrustFX(k: k, car: carNode, carSize: tex.size(), layer: fxLayer, scene: self)

        shadow.path = CGPath(ellipseIn: CGRect(x: -carLen * 0.45, y: -5 * k, width: carLen * 0.9, height: 10 * k), transform: nil)

        hud?.removeFromParent()
        let h = HUD()
        addChild(h)
        h.layout(size: size, safeTop: safeTop)
        hud = h

        reset()
    }

    // MARK: Run lifecycle

    private func reset() {
        obstacles.forEach { $0.node.removeFromParent() }
        cans.forEach { $0.node.removeFromParent() }
        balls.forEach { $0.node.removeFromParent() }
        obstacles = []
        cans = []
        balls = []
        fxLayer.removeAllChildren()
        fxLayer.position = .zero
        fx?.reset()
        stopThrust(puff: false)

        y = gy
        vy = 0
        air = 1
        speed = Tune.startSpeed
        dist = 0
        t = 0
        bonus = 0
        score = 0
        flips = 0
        chain = 0
        grounded = true
        flipping = false
        flipT = 0
        rot = 0
        nextGap = 300 * k
        overT = 0
        holding = false
        carNode.isHidden = false
        shadow.isHidden = false
        state = .ready
        showPanel(Panel.make(title: "Space Roadster X",
                             lines: ["Hold anywhere to fire the thrusters.", "Let go to drop. Land on roofs or jump them.",
                                     "Swipe up in the air to flip for +250.", "Ground time refills air. Grab canisters too."],
                             footer: "Tap to start", accent: Palette.paint, size: size))
        placeCar()
        updateHUD()
    }

    private func startRun() {
        state = .play
        showPanel(nil)
        haptics.tick()
    }

    private func crash(_ why: String) {
        guard state == .play else { return }
        state = .over
        overT = 0
        reason = why
        holding = false
        stopThrust(puff: false)
        fx?.update(on: false, intensity: 0, altitude: .infinity, ground: .zero)
        fx?.explosion(at: CGPoint(x: cx, y: y + carH * 0.5))
        carNode.isHidden = true
        shadow.isHidden = true
        sound.play(.crash)
        haptics.crash()
        var lines = [why, "Score \(score) · \(flips) flips"]
        if score > best {
            best = score
            UserDefaults.standard.set(best, forKey: "best")
            lines.append("New best!")
        } else {
            lines.append("Best \(best)")
        }
        updateHUD()
        showPanel(Panel.make(title: "Crashed", lines: lines, footer: "Tap to retry", accent: Palette.ember,
                             size: size, footerDelay: Tune.retryDelay))
    }

    private func showPanel(_ node: SKNode?) {
        panel?.removeFromParent()
        panel = node
        if let node { addChild(node) }
    }

    // MARK: Loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 1.0 / 60 : min(1.0 / 30, currentTime - lastTime)
        lastTime = currentTime
        step(CGFloat(dt))
    }

    private func step(_ dt: CGFloat) {
        if state == .over {
            overT += TimeInterval(dt)
            return
        }
        let sp = (state == .play ? speed : Tune.idleSpeed) * k
        scroll += sp * dt
        backdrop?.update(scroll: scroll)
        guard state == .play else {
            placeCar()
            return
        }

        t += dt
        speed = min(Tune.maxSpeed, Tune.startSpeed + t * Tune.speedRamp)
        let v = sp * dt
        dist += v
        for o in obstacles { o.x -= v }
        for c in cans { c.x -= v }
        for b in balls { b.x -= v }
        fxLayer.position.x -= v
        obstacles.removeAll { o in
            let gone = o.x + o.w < -80 * k
            if gone { o.node.removeFromParent() }
            return gone
        }
        cans.removeAll { c in
            let gone = c.x < -60 * k || c.got
            if gone { c.node.removeFromParent() }
            return gone
        }
        nextGap -= v
        if nextGap <= 0 { spawn() }

        // Thrust
        let wantThrust = holding && air > 0
        if wantThrust && !thrusting {
            thrusting = true
            holdTime = 0
            sound.play(.blast, volume: 0.8)
            haptics.thrustStart()
            if y - gy < 40 * k { fx?.takeoffBlast(at: CGPoint(x: cx, y: gy)) }
        } else if !wantThrust && thrusting {
            if holding && air <= 0 { sound.play(.sputter, volume: 0.7) }
            stopThrust(puff: true)
        }
        if thrusting {
            holdTime += dt
            vy += Tune.thrust * k * dt
            air = max(0, air - Tune.airDrain * dt)
            let level = min(1, 0.35 + holdTime * 0.9)
            sound.setThrust(Float(level))
            haptics.thrustLevel(Float(level))
        }

        // Gravity and the ceiling under the HUD.
        vy -= Tune.gravity * k * dt
        vy = min(vy, Tune.maxRise * k)
        let prev = y
        y += vy * dt
        let ceiling = size.height - max(safeTop, 20) - 120 - carLen * 0.3
        if y > ceiling {
            y = ceiling
            if vy > 0 { vy = 0 }
        }

        // Landing on the road or a roof.
        let hw = carLen * 0.4
        var support = gy
        for o in obstacles where cx + hw > o.x && cx - hw < o.x + o.w && prev >= o.top - 3 * k {
            support = max(support, o.top)
        }
        if y <= support {
            if !grounded {
                land(onRoof: support > gy)
                if state != .play { return }
            }
            y = support
            vy = 0
            grounded = true
        } else {
            grounded = false
        }
        let onRoof = grounded && support > gy

        // Side hits, and near-miss tracking while flying over.
        for o in obstacles {
            let overlap = cx + hw * 0.85 > o.x && cx - hw * 0.85 < o.x + o.w
            if overlap && y < o.top - 5 * k {
                crash(o.kind.crashReason)
                return
            }
            if overlap && !grounded && y >= o.top { o.minGap = min(o.minGap, y - o.top) }
            if !o.passed && o.x + o.w < cx - hw {
                o.passed = true
                if o.minGap < Tune.nearMissGap * k {
                    bonus += Tune.nearMissPoints
                    pop("CLOSE +\(Tune.nearMissPoints)", at: CGPoint(x: cx, y: y + carH * 1.6), color: Palette.mute)
                    sound.play(.nearMiss, volume: 0.7)
                    haptics.nearMiss()
                }
            }
            // The Window Test: the ball is thrown as the truck rolls into view.
            if o.thrower != nil && !o.thrown && o.x < size.width * 0.92 { throwBall(at: o) }
        }

        if updateBalls(dt) == false { return }

        // Canisters
        for c in cans where !c.got {
            if abs(c.x - cx) < 0.5 * carLen && abs(c.y - (y + carH * 0.5)) < 0.4 * carLen {
                c.got = true
                air = min(1, air + Tune.canisterAir)
                bonus += Tune.canisterPoints
                pop("AIR +\(Tune.canisterPoints)", at: CGPoint(x: c.x, y: c.y + 20 * k), color: Palette.plume)
                fx?.canisterPop(at: CGPoint(x: c.x, y: c.y))
                sound.play(.chime, volume: 0.8)
                haptics.canister()
            }
        }

        if grounded && !thrusting {
            air = min(1, air + Tune.airRefill * (onRoof ? Tune.roofRefillMultiplier : 1) * dt)
        }

        if flipping {
            flipT += dt
            let p = min(1, flipT / Tune.flipDuration)
            rot = .pi * 2 * (1 - pow(1 - p, 2))
            if p >= 1 { completeFlip() }
        }

        score = Int(dist / (10 * k)) + bonus
        fx?.update(on: thrusting, intensity: min(1, holdTime / 1.2), altitude: y - support,
                   ground: CGPoint(x: cx, y: support))
        placeCar()
        updateHUD()
    }

    private func stopThrust(puff: Bool) {
        guard thrusting else { return }
        thrusting = false
        sound.setThrust(0)
        haptics.thrustStop()
        if puff {
            sound.play(.puff, volume: 0.5)
            fx?.cutoffPuff(at: CGPoint(x: cx, y: y))
        }
    }

    private func land(onRoof: Bool) {
        if flipping {
            if flipT / Tune.flipDuration > Tune.flipForgive {
                completeFlip()
            } else {
                crash("Landed mid-flip. Flip earlier or higher.")
                return
            }
        }
        chain = 0
        let hard = vy < -700 * k
        if onRoof {
            bonus += Tune.roofPoints
            pop("ROOF +\(Tune.roofPoints)", at: CGPoint(x: cx, y: y + carH * 1.4), color: Palette.paint)
            sound.play(.clunk)
            haptics.roofLanding()
        } else {
            sound.play(.land, volume: hard ? 0.9 : 0.5)
            haptics.landing()
        }
        fx?.landingRing(at: CGPoint(x: cx, y: onRoof ? y : gy), hard: hard)
    }

    private func startFlip() {
        flipping = true
        flipT = 0
        sound.play(.whoosh, volume: 0.8)
        haptics.flipStart()
    }

    private func completeFlip() {
        flipping = false
        rot = 0
        flips += 1
        chain += 1
        let mult = min(chain, Tune.maxFlipChain)
        let points = Tune.flipPoints * mult
        bonus += points
        pop(mult > 1 ? "FLIP x\(mult) +\(points)" : "FLIP +\(points)", at: CGPoint(x: cx, y: y + carH * 2), color: Palette.gold)
        haptics.flipLand()
    }

    // MARK: Spawning

    private func spawn() {
        let x0 = size.width + 40 * k
        let r = CGFloat.random(in: 0..<1)
        var span: CGFloat = 0

        @discardableResult
        func add(_ dx: CGFloat, _ kind: ObstacleKind) -> Obstacle {
            let o = Obstacle(kind: kind, k: k, groundY: gy)
            o.x = x0 + dx
            world.addChild(o.node)
            obstacles.append(o)
            span = max(span, dx + o.w)
            return o
        }

        if t > 12 && r < 0.20 {
            // The reveal-event lineup: three cars nose to tail.
            var dx: CGFloat = 0
            for _ in 0..<3 {
                let o = add(dx, .car(CarModel.lowTraffic.randomElement()!))
                dx += o.w + 6 * k
            }
        } else if t > 6 && r < 0.45 {
            add(0, .hauler)
        } else if t > 18 && r < 0.58 && balls.isEmpty {
            add(0, .car(.wedgeTruck)).addThrower(k: k)
        } else if r < 0.72 {
            add(0, .barrier)
        } else {
            add(0, .car(CarModel.traffic.randomElement()!))
        }

        if CGFloat.random(in: 0..<1) < 0.45 {
            let c = Canister(x: x0 + span / 2, y: gy + CGFloat.random(in: 140...250) * k, k: k)
            c.node.zPosition = 5
            world.addChild(c.node)
            cans.append(c)
        }
        nextGap = span + CGFloat.random(in: 1.05...1.8) * speed * k
    }

    private func throwBall(at truck: Obstacle) {
        truck.crackWindow(k: k)
        let p = CGPoint(x: truck.x + truck.w * 0.56, y: gy + truck.h * 0.8)
        let ball = SteelBall(x: p.x, y: p.y, vx: -220 * k, vy: 620 * k, k: k)
        world.addChild(ball.node)
        balls.append(ball)
        fx?.glassShatter(at: p)
        sound.play(.crack, volume: 0.9)
        haptics.glassCrack()
    }

    /// Returns false if the ball ended the run.
    private func updateBalls(_ dt: CGFloat) -> Bool {
        for b in balls {
            b.x += b.vx * dt
            b.vy -= Tune.ballGravity * k * dt
            b.y += b.vy * dt
            if b.y - b.r < gy {
                b.y = gy + b.r
                b.vy = abs(b.vy) * 0.45
                b.vx *= 0.8
            }
            b.node.position = CGPoint(x: b.x, y: b.y)
            b.node.zRotation += b.vx * dt / b.r
            guard !b.deflected else { continue }
            let dx = b.x - cx, dy = b.y - (y + carH * 0.5)
            let ex = carLen * 0.45 + b.r, ey = carH * 0.6 + b.r
            if (dx * dx) / (ex * ex) + (dy * dy) / (ey * ey) < 1 {
                if flipping {
                    // Armor glass: flipping through the ball bats it away.
                    b.deflected = true
                    b.vx = 480 * k
                    b.vy = 520 * k
                    bonus += Tune.armorGlassPoints
                    pop("ARMOR GLASS +\(Tune.armorGlassPoints)", at: CGPoint(x: cx, y: y + carH * 2.4), color: Palette.gold)
                    sound.play(.clunk, volume: 0.8)
                    haptics.glassCrack()
                } else {
                    crash("The steel ball cracked your glass.")
                    return false
                }
            }
        }
        balls.removeAll { b in
            let gone = b.x < -60 * k || b.x > size.width + 300 * k
            if gone { b.node.removeFromParent() }
            return gone
        }
        return true
    }

    // MARK: Drawing

    private func placeCar() {
        // A slight nose-up when rising and nose-down when falling sells the weight.
        let pitch = state == .play && !grounded ? max(-0.12, min(0.12, vy / (Tune.maxRise * k) * 0.12)) : 0
        carNode.position = CGPoint(x: cx, y: y + carH / 2)
        carNode.zRotation = rot + pitch
        let alt = max(0, min(1, (y - gy) / (200 * k)))
        shadow.position = CGPoint(x: cx, y: gy + 1)
        shadow.fillColor = UIColor(white: 0, alpha: 0.38 * (1 - alt * 0.7))
        shadow.xScale = 1 - alt * 0.4
    }

    private func updateHUD() {
        hud?.update(score: score, best: best, air: air, mph: Int(speed * Tune.mphPerUnit), chain: chain)
    }

    private func pop(_ text: String, at p: CGPoint, color: UIColor) {
        let label = SKLabelNode(fontNamed: Fonts.heavy)
        label.text = text
        label.fontSize = 16
        label.fontColor = color
        label.position = p
        label.zPosition = 50
        addChild(label)
        label.run(.sequence([.group([.moveBy(x: 0, y: 46, duration: 0.8), .sequence([.wait(forDuration: 0.4), .fadeOut(withDuration: 0.4)])]),
                             .removeFromParent()]))
    }

    // MARK: Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first else { return }
        switch state {
        case .ready:
            startRun()
        case .over:
            guard overT > Tune.retryDelay else { return }
            reset()
            startRun()
        case .play:
            break
        }
        activeTouch = touch
        holding = true
        touchStart = touch.location(in: self)
        touchStartTime = touch.timestamp
        swiped = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch), holding, !swiped, state == .play else { return }
        let p = touch.location(in: self)
        if p.y - touchStart.y > Tune.swipeDistance * k && touch.timestamp - touchStartTime < Tune.swipeWindow && !flipping {
            swiped = true
            if !grounded || vy > 0 { startFlip() }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        activeTouch = nil
        holding = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeTouch = nil
        holding = false
    }
}
