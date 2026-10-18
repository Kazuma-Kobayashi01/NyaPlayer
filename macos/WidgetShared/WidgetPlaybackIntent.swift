import AppIntents
import Foundation
import WidgetKit

@available(macOS 14.0, *)
enum WidgetPlaybackAction: String, AppEnum {
  case togglePlayback, previousTrack, nextTrack, toggleShuffle, cycleLoopMode, playQueueItem

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Playback action"
  static var caseDisplayRepresentations: [WidgetPlaybackAction: DisplayRepresentation] = [
    .togglePlayback: "Play or pause", .previousTrack: "Previous track", .nextTrack: "Next track",
    .toggleShuffle: "Shuffle", .cycleLoopMode: "Repeat mode", .playQueueItem: "Play queued track",
  ]
}

@available(macOS 14.0, *)
struct WidgetPlayerCommand {
  let action: String
  let index: Int
  let queueRevision: String

  var arguments: [String: Any] {
    ["action": action, "index": index, "queueRevision": queueRevision]
  }
}

@available(macOS 14.0, *)
@MainActor
enum WidgetCommandRouter {
  // The app target installs this handler once Flutter's restored player is
  // ready. AudioPlaybackIntent executes in that app process, in background.
  static var handler: ((WidgetPlayerCommand) async throws -> Void)?

  static func perform(_ command: WidgetPlayerCommand) async throws {
    for _ in 0..<150 {
      if let handler { try await handler(command); return }
      try await Task.sleep(nanoseconds: 100_000_000)
    }
    throw NSError(domain: "NyaPlayer.Widget", code: 2, userInfo: [
      NSLocalizedDescriptionKey: "NyaPlayer has not finished starting.",
    ])
  }
}

@available(macOS 14.0, *)
struct PlayerControlIntent: AudioPlaybackIntent {
  static var title: LocalizedStringResource = "Control NyaPlayer"
  static var isDiscoverable: Bool = false

  @Parameter(title: "Action") var action: WidgetPlaybackAction
  @Parameter(title: "Queue index") var index: Int
  @Parameter(title: "Queue revision") var queueRevision: String

  init() { action = .togglePlayback; index = -1; queueRevision = "" }
  init(_ action: WidgetPlaybackAction, index: Int = -1, queueRevision: String = "") {
    self.action = action; self.index = index; self.queueRevision = queueRevision
  }

  func perform() async throws -> some IntentResult {
    try await WidgetCommandRouter.perform(WidgetPlayerCommand(
      action: action.rawValue, index: index, queueRevision: queueRevision))
    return .result()
  }
}

@available(macOS 14.0, *)
struct QueuePageIntent: AppIntent {
  static var title: LocalizedStringResource = "Browse playback queue"
  static var isDiscoverable: Bool = false

  @Parameter(title: "Page") var page: Int
  @Parameter(title: "Queue anchor") var anchor: String

  init() { page = 0; anchor = "" }
  init(page: Int, anchor: String) { self.page = page; self.anchor = anchor }

  func perform() async throws -> some IntentResult {
    PlayerWidgetStore.setPage(page, anchor: anchor)
    WidgetCenter.shared.reloadTimelines(ofKind: PlayerWidgetStore.kind)
    return .result()
  }
}
