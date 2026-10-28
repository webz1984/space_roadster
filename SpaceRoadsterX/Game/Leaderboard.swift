import Foundation

struct ScoreEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    let score: Int
    let flips: Int
    let date: Date
}

/// The player's top 20 runs, kept on the device.
final class Leaderboard: ObservableObject {
    static let shared = Leaderboard()
    static let size = 20

    @Published private(set) var entries: [ScoreEntry] = []
    private let key = "leaderboard.v1"

    var best: Int { entries.first?.score ?? 0 }

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([ScoreEntry].self, from: data) {
            entries = saved
        } else {
            // Carry over the single best score saved by the first build.
            let old = UserDefaults.standard.integer(forKey: "best")
            if old > 0 { entries = [ScoreEntry(score: old, flips: 0, date: Date())] }
        }
    }

    /// Records a run and returns its 1-based rank, or nil if it missed the top 20.
    @discardableResult
    func submit(score: Int, flips: Int) -> Int? {
        guard score > 0 else { return nil }
        let entry = ScoreEntry(score: score, flips: flips, date: Date())
        var list = entries
        let index = list.firstIndex { $0.score < score } ?? list.count
        guard index < Leaderboard.size else { return nil }
        list.insert(entry, at: index)
        entries = Array(list.prefix(Leaderboard.size))
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
        return index + 1
    }
}
