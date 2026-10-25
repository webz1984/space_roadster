import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var scene: GameScene = {
        let scene = GameScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .resizeFill
        return scene
    }()
    @State private var playing = false
    @AppStorage("soundOn") private var soundOn = true
    @AppStorage("hapticsOn") private var hapticsOn = true

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                SpriteView(scene: scene, preferredFramesPerSecond: 120, options: [.ignoresSiblingOrder])
                    .ignoresSafeArea()

                // Settings only show between runs so they never steal a thrust tap.
                if !playing {
                    HStack(spacing: 10) {
                        ToggleChip(systemImage: soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill", on: soundOn) {
                            soundOn.toggle()
                        }
                        ToggleChip(systemImage: hapticsOn ? "iphone.radiowaves.left.and.right" : "iphone.slash", on: hapticsOn) {
                            hapticsOn.toggle()
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.2), value: playing)
            .onAppear {
                scene.safeTop = geo.safeAreaInsets.top
                scene.onStateChange = { playing = $0 == .play }
                SoundEngine.shared.enabled = soundOn
                Haptics.shared.enabled = hapticsOn
            }
            .onChange(of: geo.safeAreaInsets.top) { _, top in scene.safeTop = top }
            .onChange(of: soundOn) { _, on in SoundEngine.shared.enabled = on }
            .onChange(of: hapticsOn) { _, on in Haptics.shared.enabled = on }
        }
        .background(Color.black)
    }
}

private struct ToggleChip: View {
    let systemImage: String
    let on: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(on ? Color.white : Color.white.opacity(0.5))
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }
}
