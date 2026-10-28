import AVFoundation

/// An original 8-bar driving rock loop in E minor at 140 BPM, synthesized at launch:
/// overdriven power chords, a pick bass doubling the roots, and a straight rock beat.
/// Everything is written modulo the loop length so the tails wrap and it loops seamlessly.
enum RockLoop {
    private static let bpm: Float = 140
    /// Root of each bar (Hz): E E C D | E E G D.
    private static let roots: [Float] = [82.41, 82.41, 65.41, 73.42, 82.41, 82.41, 98.00, 73.42]

    static func render(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sr = Float(format.sampleRate)
        let step = 60 / bpm / 2                     // one eighth note, in seconds
        let stepFrames = Int(step * sr)
        let total = stepFrames * 8 * roots.count
        var drums = [Float](repeating: 0, count: total)
        var guitar = [Float](repeating: 0, count: total)
        var bass = [Float](repeating: 0, count: total)

        var seed: UInt32 = 0x1234_5678
        func noise() -> Float {
            seed = seed &* 1_664_525 &+ 1_013_904_223
            return Float(Int32(bitPattern: seed)) / Float(Int32.max)
        }
        func saw(_ phase: Float) -> Float { 2 * (phase - floorf(phase + 0.5)) }

        func write(_ buf: inout [Float], at start: Int, seconds: Float, _ gen: (Float) -> Float) {
            let n = Int(seconds * sr)
            for i in 0..<n {
                buf[(start + i) % total] += gen(Float(i) / sr)
            }
        }

        func kick(_ at: Int) {
            var ph: Float = 0
            write(&drums, at: at, seconds: 0.3) { t in
                ph += (45 + 90 * expf(-t * 30)) / sr
                return sinf(ph * 2 * .pi) * expf(-t * 9) * 1.1
            }
        }
        func snare(_ at: Int) {
            var lp: Float = 0
            write(&drums, at: at, seconds: 0.25) { t in
                let n = noise()
                lp += (n - lp) * 0.3
                return ((n - lp) * 0.8 * expf(-t * 16) + sinf(t * 2 * .pi * 185) * 0.5 * expf(-t * 30)) * 0.8
            }
        }
        func hat(_ at: Int, open: Bool) {
            var lp: Float = 0
            write(&drums, at: at, seconds: open ? 0.3 : 0.05) { t in
                let n = noise()
                lp += (n - lp) * 0.6
                return (n - lp) * expf(-t * (open ? 9 : 70)) * 0.3
            }
        }
        func crash(_ at: Int) {
            var lp: Float = 0
            write(&drums, at: at, seconds: 1.6) { t in
                let n = noise()
                lp += (n - lp) * 0.5
                return (n - lp) * expf(-t * 2.2) * 0.35
            }
        }
        func chord(_ at: Int, root: Float, seconds: Float, muted: Bool) {
            var p1: Float = 0, p2: Float = 0, p3: Float = 0, lp: Float = 0
            let decay: Float = muted ? 16 : 2.5
            let tone: Float = muted ? 0.12 : 0.3
            write(&guitar, at: at, seconds: seconds) { t in
                p1 += root / sr; p2 += root * 1.5 / sr; p3 += root * 2.003 / sr
                let raw = saw(p1) + 0.8 * saw(p2) + 0.5 * saw(p3)
                let driven = tanhf(raw * 5)
                lp += (driven - lp) * tone
                return lp * expf(-t * decay) * min(1, t / 0.004)
            }
        }
        func bassNote(_ at: Int, root: Float, seconds: Float) {
            var ph: Float = 0, lp: Float = 0
            write(&bass, at: at, seconds: seconds) { t in
                ph += root / 2 / sr
                let raw = tanhf(saw(ph) * 2) + 0.6 * sinf(ph * 2 * .pi)
                lp += (raw - lp) * 0.08
                return lp * min(1, t / 0.005) * (t > seconds - 0.02 ? (seconds - t) / 0.02 : 1)
            }
        }

        for (bar, root) in roots.enumerated() {
            for s in 0..<8 {
                let at = (bar * 8 + s) * stepFrames
                // Drums: kick on 1, 3 and the "and" of 3; snare on 2 and 4; eighth-note hats.
                if s == 0 || s == 4 || s == 5 { kick(at) }
                if s == 2 || s == 6 { snare(at) }
                if bar % 4 == 0 && s == 0 { crash(at) } else { hat(at, open: s == 7 && bar % 2 == 1) }
                // Guitar: an open accent on each beat 1 and 3, palm-muted chugs between.
                if s == 0 || s == 4 {
                    chord(at, root: root, seconds: step * 1.9, muted: false)
                } else if s != 1 && s != 5 {
                    chord(at, root: root, seconds: step * 0.9, muted: true)
                }
                bassNote(at, root: root, seconds: step * 0.92)
            }
        }
        // Last bar turnaround: snare fill on the final four eighths.
        let fill = (roots.count * 8 - 4) * stepFrames
        for i in 0..<4 { snare(fill + i * stepFrames) }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(total)),
              let out = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = AVAudioFrameCount(total)
        var peak: Float = 0
        for i in 0..<total {
            let v = drums[i] * 0.9 + guitar[i] * 0.45 + bass[i] * 0.55
            let soft = v / (1 + abs(v) * 0.3)
            out[i] = soft
            peak = max(peak, abs(soft))
        }
        if peak > 0 {
            let gain = 0.9 / peak
            for i in 0..<total { out[i] *= gain }
        }
        return buffer
    }
}
