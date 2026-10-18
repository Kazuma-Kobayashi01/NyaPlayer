import Foundation
import CryptoKit

struct WidgetQueueTrack: Codable, Identifiable {
  var index: Int
  var id: Int
  var title: String
  var artist: String
  var durationMs: Int
}

struct PlayerWidgetSnapshot: Codable {
  var schemaVersion: Int = 1
  var title: String = ""
  var artist: String = ""
  var album: String = ""
  var artworkName: String?
  var currentIndex: Int?
  var isPlaying: Bool = false
  var appRunning: Bool = false
  var positionMs: Int = 0
  var durationMs: Int = 0
  var updatedAtMs: Double = 0
  var shuffle: Bool = false
  var repeatMode: String = "none"
  var queueRevision: String = ""
  var queue: [WidgetQueueTrack] = []
  var labels: [String: String] = [:]

  var hasTrack: Bool { currentIndex != nil && !queue.isEmpty }
  var updatedAt: Date { Date(timeIntervalSince1970: updatedAtMs / 1000) }
  var pageAnchor: String { "\(queueRevision):\(currentIndex ?? -1)" }

  func position(at date: Date) -> Double {
    let elapsed = isPlaying ? max(0, date.timeIntervalSince(updatedAt) * 1000) : 0
    return min(Double(durationMs), max(0, Double(positionMs) + elapsed))
  }

  func label(_ key: String, fallback: String) -> String {
    labels[key] ?? fallback
  }

  static var preview: PlayerWidgetSnapshot {
    var value = PlayerWidgetSnapshot()
    value.title = "那颗星梦见的春日"
    value.artist = "鸣潮先约电台 · jixwang · 小林未郁"
    value.album = "那颗星梦见的春日"
    value.currentIndex = 1
    value.positionMs = 78000
    value.durationMs = 236000
    value.isPlaying = true
    value.appRunning = true
    value.updatedAtMs = Date().timeIntervalSince1970 * 1000
    value.queueRevision = "preview"
    value.labels = ["queue": "播放列表", "previous": "上一首", "next": "下一首"]
    value.queue = [
      WidgetQueueTrack(index: 0, id: 1, title: "十年", artist: "陈奕迅", durationMs: 205000),
      WidgetQueueTrack(index: 1, id: 2, title: value.title, artist: value.artist, durationMs: 236000),
      WidgetQueueTrack(index: 2, id: 3, title: "小小奇迹", artist: "音乐收藏", durationMs: 221000),
      WidgetQueueTrack(index: 3, id: 4, title: "打上花火", artist: "DAOKO · 米津玄師", durationMs: 289000),
      WidgetQueueTrack(index: 4, id: 5, title: "缭花绚烂", artist: "音乐收藏", durationMs: 214000),
      WidgetQueueTrack(index: 5, id: 6, title: "下一段旅程", artist: "音乐收藏", durationMs: 193000),
    ]
    return value
  }
}

enum PlayerWidgetStore {
  static let kind = "NyaPlayer.NowPlaying"
  static let pageSize = 5
  static var appGroup: String {
    Bundle.main.object(forInfoDictionaryKey: "NyaWidgetAppGroup") as? String
      ?? "group.com.kazuma.nyaplayer.widgets"
  }

  static func directory() throws -> URL {
    guard let url = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroup)
    else {
      throw NSError(domain: "NyaPlayer.Widget", code: 1, userInfo: [
        NSLocalizedDescriptionKey: "App Group \(appGroup) is unavailable. Sign the app and widget with the same development team.",
      ])
    }
    return url
  }

  static func read() -> PlayerWidgetSnapshot {
    guard let root = try? directory(),
      let bytes = try? Data(contentsOf: root.appendingPathComponent("player.json")),
      let snapshot = try? JSONDecoder().decode(PlayerWidgetSnapshot.self, from: bytes),
      snapshot.schemaVersion == 1
    else { return PlayerWidgetSnapshot() }
    return snapshot
  }

  static func save(_ snapshot: PlayerWidgetSnapshot) throws {
    let root = try directory()
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let bytes = try JSONEncoder().encode(snapshot)
    try bytes.write(to: root.appendingPathComponent("player.json"), options: .atomic)
  }

  /// The sandboxed widget cannot read the host app's support directory. Copy
  /// only its 256px JPEG into the shared container, never the user's audio.
  static func importArtwork(from path: String?) throws -> String? {
    guard let path else { return nil }
    let filename = SHA256.hash(data: Data(path.utf8)).map { String(format: "%02x", $0) }.joined() + ".jpg"
    let root = try directory().appendingPathComponent("artwork", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let destination = root.appendingPathComponent(filename)
    if !FileManager.default.fileExists(atPath: destination.path) {
      let source = URL(fileURLWithPath: path)
      let size = try source.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
      guard size > 0, size <= 4 * 1024 * 1024 else { return nil }
      try Data(contentsOf: source).write(to: destination, options: .atomic)
    }
    // Preserve a few recent revisions while WidgetKit archives updated views.
    let files = try FileManager.default.contentsOfDirectory(
      at: root, includingPropertiesForKeys: [.contentModificationDateKey])
    let newest = files.sorted {
      ((try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
        > ((try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
    }
    for file in newest.dropFirst(8) where file.lastPathComponent != filename {
      try? FileManager.default.removeItem(at: file)
    }
    return filename
  }

  static func artworkURL(_ name: String?) -> URL? {
    guard let name, name == URL(fileURLWithPath: name).lastPathComponent,
      let root = try? directory()
    else { return nil }
    return root.appendingPathComponent("artwork").appendingPathComponent(name)
  }

  static func page(for snapshot: PlayerWidgetSnapshot) -> Int {
    let defaults = UserDefaults(suiteName: appGroup)
    let last = max(0, (snapshot.queue.count - 1) / pageSize)
    if defaults?.string(forKey: "queuePageAnchor") == snapshot.pageAnchor {
      return min(last, max(0, defaults?.integer(forKey: "queuePage") ?? 0))
    }
    return min(last, max(0, (snapshot.currentIndex ?? 0) / pageSize))
  }

  static func setPage(_ page: Int, anchor: String) {
    let defaults = UserDefaults(suiteName: appGroup)
    defaults?.set(page, forKey: "queuePage")
    defaults?.set(anchor, forKey: "queuePageAnchor")
  }
}
