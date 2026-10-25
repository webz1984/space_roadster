import CoreHaptics
import Foundation

/// Phone vibration for every game moment, matched to the sound table in the design doc.
/// Thrust is a continuous rumble whose strength follows how long the thrust is held.
final class Haptics {
    static let shared = Haptics()

    var enabled = true {
        didSet { if !enabled { thrustStop() } }
    }

    private var engine: CHHapticEngine?
    private var thrustPlayer: CHHapticAdvancedPatternPlayer?
    private let supported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private init() {
        guard supported, let engine = try? CHHapticEngine() else { return }
        engine.playsHapticsOnly = true
        engine.isAutoShutdownEnabled = false
        engine.resetHandler = { [weak self] in
            self?.thrustPlayer = nil
            try? self?.engine?.start()
        }
        engine.stoppedHandler = { [weak self] _ in self?.thrustPlayer = nil }
        try? engine.start()
        self.engine = engine
    }

    // MARK: Moments

    func thrustStart() {
        transient(1.0, 0.6)
        guard enabled, let engine else { return }
        let rumble = CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.55),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25),
        ], relativeTime: 0, duration: 30)
        do {
            let player = try engine.makeAdvancedPlayer(with: CHHapticPattern(events: [rumble], parameters: []))
            try player.start(atTime: CHHapticTimeImmediate)
            thrustPlayer = player
        } catch {
            thrustPlayer = nil
        }
    }

    /// 0...1 multiplier on the rumble's intensity.
    func thrustLevel(_ level: Float) {
        let p = CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: max(0.2, min(1, level)), relativeTime: 0)
        try? thrustPlayer?.sendParameters([p], atTime: CHHapticTimeImmediate)
    }

    func thrustStop() {
        try? thrustPlayer?.stop(atTime: CHHapticTimeImmediate)
        thrustPlayer = nil
    }

    func landing() { transient(0.6, 0.3) }
    func roofLanding() { play([(0, 1.0, 0.35), (0.07, 0.6, 0.2)]) }
    func flipStart() { transient(0.5, 0.95) }
    func flipLand() { transient(1.0, 0.2) }
    func canister() { play([(0, 0.6, 0.8), (0.08, 0.6, 0.8)]) }
    func nearMiss() { continuous(0.5, 0.7, duration: 0.12) }
    func glassCrack() { transient(0.9, 1.0) }
    func tick() { transient(0.35, 0.7) }

    func crash() {
        thrustStop()
        guard enabled, let engine else { return }
        let events = [
            CHHapticEvent(eventType: .hapticTransient, parameters: params(1, 0.8), relativeTime: 0),
            CHHapticEvent(eventType: .hapticContinuous, parameters: params(1, 0.4), relativeTime: 0, duration: 0.55),
            CHHapticEvent(eventType: .hapticTransient, parameters: params(0.7, 0.6), relativeTime: 0.16),
        ]
        let fade = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
            .init(relativeTime: 0, value: 1), .init(relativeTime: 0.55, value: 0),
        ], relativeTime: 0)
        if let pattern = try? CHHapticPattern(events: events, parameterCurves: [fade]) {
            try? engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        }
    }

    // MARK: Building blocks

    private func params(_ intensity: Float, _ sharpness: Float) -> [CHHapticEventParameter] {
        [CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
         CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)]
    }

    private func transient(_ intensity: Float, _ sharpness: Float) {
        play([(0, intensity, sharpness)])
    }

    private func play(_ taps: [(TimeInterval, Float, Float)]) {
        guard enabled, let engine else { return }
        let events = taps.map { CHHapticEvent(eventType: .hapticTransient, parameters: params($0.1, $0.2), relativeTime: $0.0) }
        if let pattern = try? CHHapticPattern(events: events, parameters: []) {
            try? engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        }
    }

    private func continuous(_ intensity: Float, _ sharpness: Float, duration: TimeInterval) {
        guard enabled, let engine else { return }
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: params(intensity, sharpness),
                                  relativeTime: 0, duration: duration)
        if let pattern = try? CHHapticPattern(events: [event], parameters: []) {
            try? engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        }
    }
}
