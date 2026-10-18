import SwiftUI
import WidgetKit

struct PlayerWidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> PlayerWidgetEntry {
    PlayerWidgetEntry(date: .now, snapshot: .preview, page: 0)
  }

  func getSnapshot(in context: Context, completion: @escaping (PlayerWidgetEntry) -> Void) {
    let snapshot = context.isPreview ? PlayerWidgetSnapshot.preview : PlayerWidgetStore.read()
    completion(PlayerWidgetEntry(date: .now, snapshot: snapshot, page: PlayerWidgetStore.page(for: snapshot)))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PlayerWidgetEntry>) -> Void) {
    let snapshot = PlayerWidgetStore.read()
    let entry = PlayerWidgetEntry(date: .now, snapshot: snapshot, page: PlayerWidgetStore.page(for: snapshot))
    // Metadata and explicit seeks request reloads from the app. The system
    // drives timer progress; no per-second app/extension work is necessary.
    completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60))))
  }
}

@main
struct NyaPlayerNowPlayingWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: PlayerWidgetStore.kind, provider: PlayerWidgetProvider()) { entry in
      PlayerWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("NyaPlayer")
    .description("Album artwork, playback controls, and your queue.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}
