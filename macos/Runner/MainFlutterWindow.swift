import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var commandsChannel: FlutterMethodChannel?
  private var lifecycleChannel: FlutterMethodChannel?
  private var widgetChannel: FlutterMethodChannel?
  private var widgetBridge: AnyObject?

  func sendPlaybackCommand(_ command: String) {
    commandsChannel?.invokeMethod(command, arguments: nil)
  }

  func prepareToExit(completion: @escaping () -> Void) {
    lifecycleChannel?.invokeMethod("prepareToExit", arguments: nil) { _ in completion() }
  }
  @IBAction func openSettings(_ sender: Any?) {
    (NSApp.delegate as? AppDelegate)?.showMainWindow(nil)
    commandsChannel?.invokeMethod("openSettings", arguments: nil)
  }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // No system title bar: the app draws under it and the traffic lights sit
    // on top of the app's own surface. The (transparent) title bar strip is
    // still draggable and double-click zooms as usual.
    self.styleMask.insert(.fullSizeContentView)
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden

    // Traffic lights sit a little inside the window corner (like VS Code).
    // AppKit resets their layout on resize / full screen, so re-apply then.
    DispatchQueue.main.async { self.positionTrafficLights() }
    for name in [
      NSWindow.didResizeNotification,
      NSWindow.didEndLiveResizeNotification,
      NSWindow.didExitFullScreenNotification,
      NSWindow.didBecomeMainNotification,
    ] {
      NotificationCenter.default.addObserver(
        forName: name, object: self, queue: .main
      ) { [weak self] _ in self?.positionTrafficLights() }
    }

    commandsChannel = FlutterMethodChannel(
      name: "nyaplayer/commands",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    commandsChannel?.setMethodCallHandler { call, result in
      if call.method == "statusMenu", let args = call.arguments as? [String: Any] {
        (NSApp.delegate as? AppDelegate)?.updateStatusMenu(args)
        result(nil)
        return
      }
      result(FlutterMethodNotImplemented)
    }

    let widgetChannel = FlutterMethodChannel(
      name: "nyaplayer/widget",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    self.widgetChannel = widgetChannel
    if #available(macOS 14.0, *) {
      widgetBridge = PlayerWidgetBridge(channel: widgetChannel)
    } else {
      widgetChannel.setMethodCallHandler { call, result in
        result(call.method == "isSupported" ? false : FlutterMethodNotImplemented)
      }
    }

    // Native folder chooser (NSOpenPanel) for the library's scan locations.
    // Shown as a sheet on this window; several folders can be chosen at once.
    // The app is not sandboxed, so plain paths are enough (no security-scoped
    // bookmarks).
    let foldersChannel = FlutterMethodChannel(
      name: "nyaplayer/folders",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    foldersChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "pickDirectories" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let args = call.arguments as? [String: Any] ?? [:]
      let panel = NSOpenPanel()
      panel.canChooseDirectories = true
      panel.canChooseFiles = false
      panel.allowsMultipleSelection = true
      panel.canCreateDirectories = false
      if let title = args["title"] as? String { panel.title = title }
      if let message = args["message"] as? String { panel.message = message }
      if let prompt = args["prompt"] as? String { panel.prompt = prompt }
      if let start = args["initialDirectory"] as? String {
        panel.directoryURL = URL(fileURLWithPath: start, isDirectory: true)
      }
      let finish: (NSApplication.ModalResponse) -> Void = { response in
        result(response == .OK ? panel.urls.map { $0.path } : [String]())
      }
      if let window = self {
        panel.beginSheetModal(for: window, completionHandler: finish)
      } else {
        finish(panel.runModal())
      }
    }

    lifecycleChannel = FlutterMethodChannel(
      name: "nyaplayer/lifecycle",
      binaryMessenger: flutterViewController.engine.binaryMessenger)

    // Tells Flutter when the traffic lights go away (full screen), so it can
    // drop the inset it keeps for them.
    let channel = FlutterMethodChannel(
      name: "nyaplayer/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "isFullScreen" {
        result(self?.styleMask.contains(.fullScreen) ?? false)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    for (name, value) in [
      (NSWindow.willEnterFullScreenNotification, true),
      (NSWindow.willExitFullScreenNotification, false),
    ] {
      NotificationCenter.default.addObserver(
        forName: name, object: self, queue: .main
      ) { _ in channel.invokeMethod("fullScreen", arguments: value) }
    }

    // Smallest allowed window: a normal phone-sized layout. There is no
    // maximum; the window can grow up to (and into) full screen.
    let minSize = NSSize(width: 400, height: 700)
    self.contentMinSize = minSize
    self.collectionBehavior.insert(.fullScreenPrimary)
    // minSize only constrains user resizing, so a smaller restored frame has
    // to be grown by hand.
    let content = self.contentRect(forFrameRect: self.frame).size
    if content.width < minSize.width || content.height < minSize.height {
      self.setContentSize(NSSize(
        width: max(content.width, minSize.width),
        height: max(content.height, minSize.height)))
    }

    // Dev aid: NYA_WINDOW_SIZE=400x860 opens the window phone-sized.
    if let spec = ProcessInfo.processInfo.environment["NYA_WINDOW_SIZE"] {
      let parts = spec.split(separator: "x").compactMap { Double($0) }
      if parts.count == 2 {
        // Delayed so it wins over macOS window-frame restoration.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
          self.setContentSize(NSSize(
            width: max(parts[0], minSize.width),
            height: max(parts[1], minSize.height)))
          self.center()
        }
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  /// Extra space between the window corner and the traffic lights, in points.
  /// Flutter keeps `macTitlebarInset` (lib/app/window_chrome.dart) clear for
  /// them, so change both together.
  private static let trafficLightInsetX: CGFloat = 8
  private static let trafficLightInsetY: CGFloat = 6

  private func positionTrafficLights() {
    guard !styleMask.contains(.fullScreen),
      let close = standardWindowButton(.closeButton),
      let mini = standardWindowButton(.miniaturizeButton),
      let zoom = standardWindowButton(.zoomButton),
      let bar = close.superview,
      let container = bar.superview
    else { return }

    // Grow the title bar container downwards so the moved buttons stay
    // inside it (and keep receiving clicks).
    let extra = MainFlutterWindow.trafficLightInsetY * 2
    let height = 28 + extra
    container.frame = NSRect(
      x: 0, y: frame.height - height, width: frame.width, height: height)
    bar.frame = container.bounds

    let spacing = mini.frame.minX - close.frame.minX
    let startX = 7 + MainFlutterWindow.trafficLightInsetX
    for (i, button) in [close, mini, zoom].enumerated() {
      button.setFrameOrigin(
        NSPoint(
          x: startX + CGFloat(i) * spacing,
          y: (height - button.frame.height) / 2))
    }
  }
}
