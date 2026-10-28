import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var scene: GameScene = {
        let scene = GameScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .resizeFill
        return scene
    }()
    @State private var playing = false
    @State private var showRanking = false
    @AppStorage("soundOn") private var soundOn = true
    @AppStorage("musicOn") private var musicOn = true
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
                        ToggleChip(systemImage: "music.note", on: musicOn && soundOn) {
                            musicOn.toggle()
                        }
                        ToggleChip(systemImage: hapticsOn ? "iphone.radiowaves.left.and.right" : "iphone.slash", on: hapticsOn) {
                            hapticsOn.toggle()
                        }
                        ToggleChip(systemImage: "trophy.fill", on: true) {
                            showRanking = true
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
                SoundEngine.shared.musicEnabled = musicOn
                Haptics.shared.enabled = hapticsOn
            }
            .onChange(of: geo.safeAreaInsets.top) { _, top in scene.safeTop = top }
            .onChange(of: soundOn) { _, on in SoundEngine.shared.enabled = on }
            .onChange(of: musicOn) { _, on in SoundEngine.shared.musicEnabled = on }
            .onChange(of: hapticsOn) { _, on in Haptics.shared.enabled = on }
        }
        .background(Color.black)
        .sheet(isPresented: $showRanking) {
            RankingView()
                .presentationDetents([.medium, .large])
        }
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

/// The top 20 runs on this phone.
private struct RankingView: View {
    @ObservedObject private var board = Leaderboard.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if board.entries.isEmpty {
                    ContentUnavailableView("No runs yet", systemImage: "trophy",
                                           description: Text("Your top \(Leaderboard.size) scores will show up here."))
                } else {
                    List {
                        ForEach(Array(board.entries.enumerated()), id: \.element.id) { index, entry in
                            HStack(spacing: 14) {
                                Text("\(index + 1)")
                                    .font(.system(.headline, design: .rounded).monospacedDigit())
                                    .foregroundStyle(index < 3 ? Color.yellow : Color.secondary)
                                    .frame(width: 28, alignment: .trailing)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(entry.score)")
                                        .font(.system(.title3, design: .rounded).weight(.heavy).monospacedDigit())
                                    Text("\(entry.flips) flips · \(entry.date.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Top \(Leaderboard.size)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
