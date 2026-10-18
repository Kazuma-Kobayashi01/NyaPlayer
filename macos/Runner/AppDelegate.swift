import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var statusItem: NSStatusItem?
  private var isQuitting = false

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    createStatusItem()
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    showMainWindow(nil)
    return true
  }

  override func application(_ application: NSApplication, open urls: [URL]) {
    guard urls.contains(where: { $0.scheme == "nyaplayer" && $0.host == "player" }) else { return }
    showMainWindow(nil)
  }

  @objc func showMainWindow(_ sender: Any?) {
    guard let window = mainFlutterWindow else { return }
    if window.isMiniaturized { window.deminiaturize(nil) }
    NSApp.unhide(nil)
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    if isQuitting { return .terminateLater }
    guard let window = mainFlutterWindow as? MainFlutterWindow else { return .terminateNow }
    isQuitting = true
    var replied = false
    let finish = {
      if replied { return }
      replied = true
      sender.reply(toApplicationShouldTerminate: true)
    }
    window.prepareToExit(completion: finish)
    // A stuck Flutter isolate must never trap the user in the application.
    DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: finish)
    return .terminateLater
  }

  private func createStatusItem() {
    if statusItem != nil { return }
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "NyaPlayer")
    image?.isTemplate = true
    item.button?.image = image
    item.button?.toolTip = "NyaPlayer"
    statusItem = item
    updateStatusMenu([:])
  }

  func updateStatusMenu(_ values: [String: Any]) {
    if statusItem == nil { createStatusItem() }
    let menu = NSMenu()
    menu.autoenablesItems = false
    func add(_ title: String, _ action: Selector, enabled: Bool = true) {
      let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
      item.target = self
      item.isEnabled = enabled
      menu.addItem(item)
    }
    add(values["show"] as? String ?? "Show NyaPlayer", #selector(showMainWindow(_:)))
    menu.addItem(.separator())
    let title = values["title"] as? String ?? "NyaPlayer"
    let track = NSMenuItem(title: title, action: nil, keyEquivalent: "")
    track.isEnabled = false
    menu.addItem(track)
    let enabled = values["hasTrack"] as? Bool ?? false
    add(values["playPause"] as? String ?? "Play / pause", #selector(togglePlayback(_:)), enabled: enabled)
    add(values["previous"] as? String ?? "Previous track", #selector(previousTrack(_:)), enabled: enabled)
    add(values["next"] as? String ?? "Next track", #selector(nextTrack(_:)), enabled: enabled)
    menu.addItem(.separator())
    add(values["quit"] as? String ?? "Quit NyaPlayer", #selector(quitApplication(_:)))
    statusItem?.menu = menu
    statusItem?.button?.toolTip = title == "NyaPlayer" ? title : "NyaPlayer — \(title)"
  }

  private func sendPlaybackCommand(_ command: String) {
    (mainFlutterWindow as? MainFlutterWindow)?.sendPlaybackCommand(command)
  }

  @objc private func togglePlayback(_ sender: Any?) { sendPlaybackCommand("togglePlayback") }
  @objc private func previousTrack(_ sender: Any?) { sendPlaybackCommand("previousTrack") }
  @objc private func nextTrack(_ sender: Any?) { sendPlaybackCommand("nextTrack") }
  @objc private func quitApplication(_ sender: Any?) { NSApp.terminate(sender) }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
