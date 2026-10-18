import AppKit
import SwiftUI
import WidgetKit

struct PlayerWidgetEntry: TimelineEntry {
  let date: Date
  let snapshot: PlayerWidgetSnapshot
  let page: Int
  var artwork: NSImage? = nil
}

@available(macOS 14.0, *)
struct PlayerWidgetEntryView: View {
  @Environment(\.widgetFamily) private var family
  let entry: PlayerWidgetEntry

  var body: some View {
    PlayerWidgetContent(entry: entry, family: family)
      .widgetURL(URL(string: "nyaplayer://player"))
      .containerBackground(for: .widget) {
        Color(nsColor: .windowBackgroundColor)
          .overlay(alignment: .topLeading) {
            LinearGradient(
              colors: [Color.accentColor.opacity(0.10), .clear],
              startPoint: .topLeading, endPoint: .bottomTrailing)
          }
      }
  }
}

@available(macOS 14.0, *)
struct PlayerWidgetContent: View {
  let entry: PlayerWidgetEntry
  let family: WidgetFamily
  private var player: PlayerWidgetSnapshot { entry.snapshot }

  var body: some View {
    Group {
      if !player.hasTrack { empty }
      else if family == .systemSmall { small }
      else if family == .systemLarge { large }
      else { medium }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .foregroundStyle(Color.primary)
    .tint(.accentColor)
  }

  private var small: some View {
    VStack(alignment: .leading, spacing: 7) {
      HStack(alignment: .top) {
        cover(side: 58)
        Spacer(minLength: 8)
        Image(systemName: player.isPlaying ? "waveform" : "music.note")
          .font(.system(size: 17, weight: .medium))
          .foregroundStyle(.secondary)
          .padding(.top, 3)
          .accessibilityHidden(true)
      }
      Text(player.album.isEmpty ? player.title : player.album)
        .font(.system(size: 13, weight: .semibold))
        .lineLimit(1).minimumScaleFactor(0.8)
        .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 0)
      controls(compact: true)
    }
  }

  private var medium: some View {
    VStack(alignment: .leading, spacing: 10) {
      header
      Spacer(minLength: 0)
      progress
    }
  }

  private var large: some View {
    VStack(alignment: .leading, spacing: 9) {
      header
      progress
      Divider().overlay(Color.primary.opacity(0.03))
      queueHeader
      VStack(spacing: 1) {
        ForEach(visibleQueue, id: \.index) { track in queueRow(track) }
      }
      Spacer(minLength: 0)
    }
  }

  private var header: some View {
    HStack(alignment: .top, spacing: 12) {
      cover(side: family == .systemLarge ? 80 : 72)
      VStack(alignment: .leading, spacing: 4) {
        Text(player.title)
          .font(.system(size: 15, weight: .semibold))
          .lineLimit(1).minimumScaleFactor(0.85)
          .fixedSize(horizontal: false, vertical: true)
        Text(player.artist.isEmpty ? player.album : player.artist)
          .font(.system(size: 11)).foregroundStyle(.secondary)
          .lineLimit(1)
          .fixedSize(horizontal: false, vertical: true)
        Spacer(minLength: 2)
        controls(compact: false)
      }
      .frame(height: 80)
    }
  }

  private func cover(side: CGFloat) -> some View {
    Group {
      if let image = entry.artwork ?? PlayerWidgetStore.artworkURL(player.artworkName).flatMap({ NSImage(contentsOf: $0) }) {
        Image(nsImage: image).resizable().scaledToFill()
      } else {
        RoundedRectangle(cornerRadius: 10)
          .fill(Color.accentColor.opacity(0.13))
          .overlay {
            Image(systemName: "opticaldisc")
              .font(.system(size: side * 0.40, weight: .light))
              .foregroundStyle(Color.accentColor)
          }
      }
    }
    .frame(width: side, height: side)
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
    }
    .accessibilityLabel(player.album)
  }

  private func controls(compact: Bool) -> some View {
    HStack(spacing: compact ? 10 : 5) {
      control(.previousTrack, symbol: "backward.end.fill",
        label: player.label("previous", fallback: String(localized: "Previous track")), size: 27)
      control(.togglePlayback, symbol: player.isPlaying ? "pause.fill" : "play.fill",
        label: player.label(player.isPlaying ? "pause" : "play", fallback: String(localized: "Play or pause")),
        size: 32, primary: true)
      control(.nextTrack, symbol: "forward.end.fill",
        label: player.label("next", fallback: String(localized: "Next track")), size: 27)
      if !compact {
        Spacer(minLength: 3)
        control(.toggleShuffle, symbol: "shuffle",
          label: player.label(player.shuffle ? "shuffleOn" : "shuffleOff", fallback: String(localized: "Shuffle")),
          size: 25, selected: player.shuffle)
        control(.cycleLoopMode, symbol: player.repeatMode == "one" ? "repeat.1" : "repeat",
          label: player.label(
            player.repeatMode == "none" ? "repeatOff" : (player.repeatMode == "one" ? "repeatOne" : "repeatAll"),
            fallback: String(localized: "Repeat mode")),
          size: 25, selected: player.repeatMode != "none")
      }
    }
    .frame(maxWidth: .infinity)
  }

  private func control(
    _ action: WidgetPlaybackAction, symbol: String, label: String,
    size: CGFloat, primary: Bool = false, selected: Bool = false
  ) -> some View {
    Button(intent: PlayerControlIntent(action)) {
      Image(systemName: symbol)
        .font(.system(size: primary ? 13 : 12, weight: .semibold))
        .foregroundStyle(primary ? Color(nsColor: .windowBackgroundColor) : (selected ? Color.accentColor : Color.primary))
        .frame(width: size, height: size)
        .background {
          Circle().fill(primary ? Color.primary : (selected ? Color.accentColor.opacity(0.13) : Color.primary.opacity(0.045)))
        }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
    .help(label)
  }

  private var progress: some View {
    VStack(spacing: 3) {
      if player.isPlaying && player.durationMs > 0 {
        let start = player.updatedAt.addingTimeInterval(-Double(player.positionMs) / 1000)
        let end = start.addingTimeInterval(Double(player.durationMs) / 1000)
        ProgressView(timerInterval: start...max(start.addingTimeInterval(0.001), end), countsDown: false) {
          EmptyView()
        } currentValueLabel: { EmptyView() }
          .progressViewStyle(.linear)
          .frame(height: 4)
      } else {
        GeometryReader { geometry in
          Capsule().fill(Color.primary.opacity(0.12))
            .overlay(alignment: .leading) {
              Capsule().fill(Color.accentColor)
                .frame(width: geometry.size.width * player.position(at: entry.date) / Double(max(1, player.durationMs)))
            }
        }.frame(height: 3)
      }
      HStack {
        if player.isPlaying && player.durationMs > 0 {
          let start = player.updatedAt.addingTimeInterval(-Double(player.positionMs) / 1000)
          let end = start.addingTimeInterval(Double(player.durationMs) / 1000)
          Text(timerInterval: start...max(start.addingTimeInterval(0.001), end), countsDown: false)
            .monospacedDigit()
            .frame(width: 45, alignment: .leading)
        } else {
          Text(time(player.positionMs)).monospacedDigit()
        }
        Spacer()
        Text(time(player.durationMs)).monospacedDigit().fixedSize()
      }
      .font(.system(size: 9, weight: .medium)).foregroundStyle(.secondary)
    }
    .accessibilityLabel(Text("Playback progress"))
  }

  private var visibleQueue: [WidgetQueueTrack] {
    Array(player.queue.dropFirst(entry.page * PlayerWidgetStore.pageSize).prefix(PlayerWidgetStore.pageSize))
  }

  private var queueHeader: some View {
    HStack(spacing: 6) {
      Text(player.label("queue", fallback: String(localized: "Playback queue")))
        .font(.system(size: 11, weight: .semibold))
      Text("\(player.queue.count)")
        .font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
      Spacer(minLength: 0)
      let pageCount = max(1, (player.queue.count + PlayerWidgetStore.pageSize - 1) / PlayerWidgetStore.pageSize)
      if pageCount > 1 {
        Text("\(entry.page + 1)/\(pageCount)")
          .font(.system(size: 9, weight: .medium)).monospacedDigit().foregroundStyle(.secondary)
        pageButton(.init(page: entry.page - 1, anchor: player.pageAnchor), symbol: "chevron.left", enabled: entry.page > 0)
        pageButton(.init(page: entry.page + 1, anchor: player.pageAnchor), symbol: "chevron.right", enabled: entry.page + 1 < pageCount)
      }
    }
    .frame(height: 18)
  }

  private func pageButton(_ intent: QueuePageIntent, symbol: String, enabled: Bool) -> some View {
    Button(intent: intent) {
      Image(systemName: symbol).font(.system(size: 9, weight: .semibold))
        .frame(width: 20, height: 20).contentShape(Rectangle())
    }
    .buttonStyle(.plain).disabled(!enabled)
    .accessibilityLabel(symbol == "chevron.left" ? Text("Previous page") : Text("Next page"))
  }

  private func queueRow(_ track: WidgetQueueTrack) -> some View {
    let current = track.index == player.currentIndex
    return Button(intent: PlayerControlIntent(.playQueueItem, index: track.index, queueRevision: player.queueRevision)) {
      HStack(spacing: 8) {
        Group {
          if current { Image(systemName: player.isPlaying ? "waveform" : "pause.fill") }
          else { Text("\(track.index + 1)").monospacedDigit() }
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(current ? Color.accentColor : Color.secondary)
        .frame(width: 17)
        VStack(alignment: .leading, spacing: 1) {
          Text(track.title).font(.system(size: 11, weight: current ? .semibold : .medium)).lineLimit(1)
          Text(track.artist).font(.system(size: 9)).foregroundStyle(.secondary).lineLimit(1)
        }
        Spacer(minLength: 2)
        Text(time(track.durationMs)).font(.system(size: 9)).monospacedDigit().foregroundStyle(.secondary)
      }
      .padding(.horizontal, 6).frame(height: 29)
      .background(RoundedRectangle(cornerRadius: 6).fill(current ? Color.accentColor.opacity(0.10) : .clear))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(track.title), \(track.artist)")
    .accessibilityAddTraits(current ? .isSelected : [])
  }

  private var empty: some View {
    VStack(alignment: .leading, spacing: 9) {
      cover(side: family == .systemSmall ? 50 : 60)
      Text(player.label("notPlaying", fallback: String(localized: "Not playing")))
        .font(.system(size: 14, weight: .semibold))
      if family != .systemSmall {
        Text(player.label("emptyHint", fallback: String(localized: "Choose music in NyaPlayer to get started.")))
          .font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(2)
      }
      Spacer(minLength: 0)
      Link(destination: URL(string: "nyaplayer://player")!) {
        Label("Open NyaPlayer", systemImage: "arrow.up.forward")
          .font(.system(size: 11, weight: .medium))
      }
    }
  }

  private func time(_ milliseconds: Int) -> String {
    let seconds = max(0, milliseconds / 1000)
    return String(format: "%d:%02d", seconds / 60, seconds % 60)
  }
}
