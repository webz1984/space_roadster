import AVFoundation

/// All game audio is synthesised at launch, so there are no sound files to license or ship.
/// Thrust is a live synth (jet hiss, low roar and turbine whine) that rises while held;
/// everything else is a short pre-rendered buffer played on a small voice pool.
final class SoundEngine {
    static let shared = SoundEngine()

    enum Sfx: CaseIterable {
        case blast, puff, land, clunk, whoosh, chime, nearMiss, crack, crash, tick, sputter
    }

    var enabled = true {
        didSet { if !enabled { setThrust(0) } }
    }

    private let engine = AVAudioEngine()
    private let format: AVAudioFormat
    private var voices: [AVAudioPlayerNode] = []
    private var nextVoice = 0
    private var buffers: [Sfx: AVAudioPCMBuffer] = [:]
    private let synth = ThrustSynth()

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        // Ambient: respects the silent switch and mixes with the player's own music.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        for sfx in Sfx.allCases { buffers[sfx] = SoundEngine.render(sfx, format: format) }
        for _ in 0..<8 {
            let voice = AVAudioPlayerNode()
            engine.attach(voice)
            engine.connect(voice, to: engine.mainMixerNode, format: format)
            voices.append(voice)
        }

        let synth = self.synth
        let sampleRate = Float(format.sampleRate)
        let source = AVAudioSourceNode(format: format) { _, _, frameCount, bufferList -> OSStatus in
            let list = UnsafeMutableAudioBufferListPointer(bufferList)
            for buffer in list {
                guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
                synth.render(into: data, frames: Int(frameCount), sampleRate: sampleRate)
            }
            return noErr
        }
        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.9
        start()

        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            self?.start()
        }
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            if raw == AVAudioSession.InterruptionType.ended.rawValue { self?.start() }
        }
    }

    func start() {
        guard !engine.isRunning else { return }
        engine.prepare()
        try? engine.start()
    }

    func play(_ sfx: Sfx, volume: Float = 1) {
        guard enabled, let buffer = buffers[sfx] else { return }
        start()
        guard engine.isRunning else { return }
        let voice = voices[nextVoice]
        nextVoice = (nextVoice + 1) % voices.count
        voice.stop()
        voice.volume = volume
        voice.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        voice.play()
    }

    /// 0 silences the thrust; 0...1 sets how hard it is blowing.
    func setThrust(_ level: Float) {
        let on = enabled && level > 0
        synth.targetAmp = on ? 0.35 + 0.4 * level : 0
        synth.targetPitch = on ? level : 0
    }

    // MARK: Synthesis

    private static func render(_ sfx: Sfx, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sr = Float(format.sampleRate)
        var seed: UInt32 = 0x9e37_79b9
        func noise() -> Float {
            seed = seed &* 1_664_525 &+ 1_013_904_223
            return Float(Int32(bitPattern: seed)) / Float(Int32.max)
        }
        let tau = Float.pi * 2
        var lp: Float = 0, lp2: Float = 0, phase: Float = 0

        let duration: Float
        let gen: (Float) -> Float
        switch sfx {
        case .blast:
            // Pneumatic release: a bright burst of air over a low thump.
            duration = 0.4
            gen = { t in
                lp += (noise() - lp) * (0.5 * expf(-t * 6) + 0.05)
                let thump = sinf(tau * (95 - 70 * t) * t) * expf(-t * 22)
                return lp * expf(-t * 9) + 0.9 * thump
            }
        case .puff:
            duration = 0.3
            gen = { t in
                lp += (noise() - lp) * 0.08
                return lp * min(1, t / 0.015) * expf(-t * 14)
            }
        case .land:
            duration = 0.25
            gen = { t in
                lp += (noise() - lp) * 0.2
                return sinf(tau * 60 * t) * expf(-t * 25) + lp * expf(-t * 40) * 0.3
            }
        case .clunk:
            // Suspension soaking up a roof landing: two quick heavy hits.
            duration = 0.35
            gen = { t in
                func hit(_ u: Float) -> Float {
                    guard u >= 0 else { return 0 }
                    return sinf(tau * 72 * u) * expf(-u * 20) + noise() * expf(-u * 90) * 0.4
                }
                return hit(t) + 0.6 * hit(t - 0.07)
            }
        case .whoosh:
            duration = 0.5
            gen = { t in
                let env = sinf(.pi * t / 0.5)
                lp += (noise() - lp) * (0.02 + 0.25 * env)
                lp2 += (lp - lp2) * 0.01
                return (lp - lp2) * env * env
            }
        case .chime:
            duration = 0.7
            gen = { t in
                let tone = sinf(tau * 1318 * t) + 0.55 * sinf(tau * 1975 * t) + 0.25 * sinf(tau * 2637 * t)
                let hiss = t < 0.15 ? noise() * 0.15 * (1 - t / 0.15) : 0
                return tone * expf(-t * 5) * min(1, t / 0.003) * 0.4 + hiss
            }
        case .nearMiss:
            // Doppler swoosh: noise swelling past the ear with a falling tone.
            duration = 0.55
            gen = { t in
                let env = expf(-powf((t - 0.28) / 0.11, 2))
                phase += tau * (700 - 400 * t / 0.55) / sr
                lp += (noise() - lp) * 0.15
                return env * (0.8 * lp + 0.25 * sinf(phase))
            }
        case .crack:
            duration = 0.45
            gen = { t in
                let n = noise()
                let crackle = abs(n) > 0.93 ? n : 0
                lp += (n - lp) * 0.3
                let ping = sinf(tau * 3100 * t) * expf(-t * 18) * 0.4
                return crackle * expf(-t * 6) + ping + (n - lp) * expf(-t * 30) * 0.6
            }
        case .crash:
            duration = 1.5
            gen = { t in
                let n = noise()
                lp += (n - lp) * 0.25
                lp2 += (n - lp2) * 0.01
                let metal = (sinf(tau * 523 * t) + 0.8 * sinf(tau * 787 * t) + 0.6 * sinf(tau * 1190 * t)) * expf(-t * 4) * 0.25
                let g = noise()
                let glass = t > 0.08 && abs(g) > 0.96 ? g * expf(-(t - 0.08) * 3) * 0.7 : 0
                return lp * expf(-t * 3.5) + lp2 * 6 * expf(-t * 2.5) + metal + glass
            }
        case .tick:
            duration = 0.04
            gen = { t in sinf(tau * 2000 * t) * expf(-t * 120) }
        case .sputter:
            duration = 0.35
            gen = { t in
                lp += (noise() - lp) * 0.2
                let gate: Float = sinf(tau * 18 * t) > 0 ? 1 : 0.1
                return lp * gate * expf(-t * 5)
            }
        }

        let frames = AVAudioFrameCount(duration * sr)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let out = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frames
        var peak: Float = 0
        for i in 0..<Int(frames) {
            let v = gen(Float(i) / sr)
            out[i] = v
            peak = max(peak, abs(v))
        }
        if peak > 0 {
            let gain = 0.8 / peak
            for i in 0..<Int(frames) { out[i] *= gain }
        }
        return buffer
    }
}

/// Runs on the audio thread. The scene only writes the two targets; the synth glides to them.
final class ThrustSynth {
    var targetAmp: Float = 0
    var targetPitch: Float = 0

    private var amp: Float = 0
    private var pitch: Float = 0
    private var phase: Float = 0
    private var hiss1: Float = 0
    private var hiss2: Float = 0
    private var roar: Float = 0
    private var seed: UInt32 = 22_222

    func render(into out: UnsafeMutablePointer<Float>, frames: Int, sampleRate: Float) {
        let ta = targetAmp, tp = targetPitch
        for i in 0..<frames {
            amp += (ta - amp) * 0.0012
            pitch += (tp - pitch) * 0.0004
            seed = seed &* 1_664_525 &+ 1_013_904_223
            let n = Float(Int32(bitPattern: seed)) / Float(Int32.max)
            hiss1 += (n - hiss1) * (0.10 + 0.35 * pitch)
            hiss2 += (hiss1 - hiss2) * 0.02
            roar += (n - roar) * 0.006
            phase += 2 * .pi * (220 + 700 * pitch) / sampleRate
            if phase > 2 * .pi { phase -= 2 * .pi }
            let s = amp * (0.9 * (hiss1 - hiss2) + 2.2 * roar + 0.05 * sinf(phase))
            out[i] = s / (1 + abs(s))
        }
    }
}
