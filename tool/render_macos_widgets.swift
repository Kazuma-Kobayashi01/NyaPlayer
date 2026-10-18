// Compile alongside WidgetShared/*.swift and NyaPlayerWidget/PlayerWidgetView.swift.
// Usage: render_macos_widgets <output-directory> [preview-artwork.jpg]
import AppKit
import SwiftUI
import WidgetKit

@main
struct WidgetPreviewRenderer {
  @MainActor static func main() throws {
    let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "build/widget_previews")
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    let artwork = CommandLine.arguments.count > 2 ? NSImage(contentsOfFile: CommandLine.arguments[2]) : nil
    let sizes: [(String, WidgetFamily, CGFloat, CGFloat)] = [
      ("small", .systemSmall, 170, 170),
      ("medium", .systemMedium, 364, 170),
      ("large", .systemLarge, 364, 382),
    ]
    for dark in [false, true] {
      NSApplication.shared.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
      for (name, family, width, height) in sizes {
        let entry = PlayerWidgetEntry(date: .now, snapshot: .preview, page: 0, artwork: artwork)
        let view = PlayerWidgetContent(entry: entry, family: family)
          .padding(16).frame(width: width, height: height)
          .background(Color(nsColor: .windowBackgroundColor))
          .clipShape(RoundedRectangle(cornerRadius: 22))
          .environment(\.colorScheme, dark ? .dark : .light)
          .environment(\.locale, Locale(identifier: "zh-Hans"))
        try render(view, to: output.appendingPathComponent("\(name)-\(dark ? "dark" : "light").png"))
      }
    }
    let empty = PlayerWidgetEntry(date: .now, snapshot: PlayerWidgetSnapshot(), page: 0)
    try render(
      PlayerWidgetContent(entry: empty, family: .systemSmall)
        .padding(16).frame(width: 170, height: 170)
        .background(Color(nsColor: .windowBackgroundColor))
        .environment(\.colorScheme, .light),
      to: output.appendingPathComponent("empty.png"))
    let overview = HStack(alignment: .top, spacing: 20) {
      ForEach(Array(sizes.enumerated()), id: \.offset) { _, item in
        VStack(alignment: .leading, spacing: 10) {
          Text(item.0.capitalized).font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
          PlayerWidgetContent(
            entry: PlayerWidgetEntry(date: .now, snapshot: .preview, page: 0, artwork: artwork), family: item.1)
            .padding(16).frame(width: item.2, height: item.3)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
      }
    }
    .padding(20).background(Color(nsColor: .underPageBackgroundColor))
    .environment(\.colorScheme, .dark)
    .environment(\.locale, Locale(identifier: "zh-Hans"))
    NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
    try render(overview, to: output.appendingPathComponent("overview.png"))
    print("Rendered widgets to \(output.path)")
  }

  @MainActor static func render<V: View>(_ view: V, to url: URL) throws {
    // Use AppKit's offscreen view drawing so native Text/Link controls are
    // included; ImageRenderer omits some platform-backed views on macOS.
    let hosting = NSHostingView(rootView: view)
    let size = hosting.fittingSize
    hosting.frame = NSRect(origin: .zero, size: size)
    let window = NSWindow(contentRect: hosting.frame, styleMask: [], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.contentView = hosting
    hosting.layoutSubtreeIfNeeded()
    guard let bitmap = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds)
    else { throw NSError(domain: "WidgetPreview", code: 1) }
    hosting.cacheDisplay(in: hosting.bounds, to: bitmap)
    window.close()
    guard let png = bitmap.representation(using: .png, properties: [:])
    else { throw NSError(domain: "WidgetPreview", code: 1) }
    try png.write(to: url)
  }
}
