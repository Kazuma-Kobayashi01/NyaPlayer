import FlutterMacOS

/// Flutter side of the macOS playback core (TECH_SPEC §4.7, M10-6).
///
/// Speaks the same channel protocol as the Android engine
/// (`AndroidPlayerEngine.kt`): method channel `nyaplayer/player`, event channel
/// `nyaplayer/player/events` with `playing` / `currentIndex` / `completed` /
/// `error` events, and a `position` call that Dart polls while playing.
final class MacPlayerEngine: NSObject, FlutterStreamHandler {
  private let core = MacPlayerCore()
  private let method: FlutterMethodChannel
  private let events: FlutterEventChannel
  private var sink: FlutterEventSink?
  private var playing = false

  init(messenger: FlutterBinaryMessenger) {
    method = FlutterMethodChannel(name: "nyaplayer/player", binaryMessenger: messenger)
    events = FlutterEventChannel(name: "nyaplayer/player/events", binaryMessenger: messenger)
    super.init()
    core.onPlaying = { [weak self] value in
      self?.playing = value
      self?.emit(["kind": "playing", "playing": value])
    }
    core.onIndex = { [weak self] index in
      self?.emit(["kind": "currentIndex", "index": Self.box(index)])
    }
    core.onCompleted = { [weak self] in self?.emit(["kind": "completed"]) }
    core.onError = { [weak self] message in self?.emit(["kind": "error", "message": message]) }
    method.setMethodCallHandler { [weak self] call, result in self?.handle(call, result) }
    events.setStreamHandler(self)
  }

  // MARK: Method channel

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    func int(_ key: String) -> Int? { (args[key] as? NSNumber)?.intValue }

    switch call.method {
    case "openQueue":
      core.openQueue(
        paths: args["paths"] as? [String] ?? [],
        start: int("startIndex") ?? 0,
        autoplay: args["autoplay"] as? Bool ?? true)
    case "play": core.play()
    case "pause": core.pause()
    case "seek": core.seek(seconds: Double(int("positionMs") ?? 0) / 1000)
    case "jumpTo": if let index = int("index") { core.jump(to: index) }
    case "add": if let path = args["path"] as? String { core.add(path: path) }
    case "insert":
      if let path = args["path"] as? String { core.insert(at: int("index") ?? 0, path: path) }
    case "remove": if let index = int("index") { core.remove(at: index) }
    case "move":
      if let from = int("from"), let to = int("to") { core.move(from: from, to: to) }
    case "reorder":
      core.reorder((args["order"] as? [NSNumber] ?? []).map { $0.intValue })
    case "setLoopMode":
      switch args["mode"] as? String {
      case "one": core.setLoop(.one)
      case "all": core.setLoop(.all)
      default: core.setLoop(.none)
      }
    case "setEqualizer":
      core.setEqualizer(
        enabled: args["enabled"] as? Bool ?? false,
        gains: (args["gainsDb"] as? [NSNumber] ?? []).map { $0.doubleValue },
        preamp: (args["preampDb"] as? NSNumber)?.doubleValue ?? 0)
    case "setVolume":
      core.setVolume(Float((args["volume"] as? NSNumber)?.doubleValue ?? 1))
    case "position":
      result(Int((core.positionSeconds() * 1000).rounded()))
      return
    default:
      result(FlutterMethodNotImplemented)
      return
    }
    result(nil)
  }

  // MARK: Event channel

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    // Catch the new subscriber up with where playback is.
    emit(["kind": "currentIndex", "index": Self.box(core.currentIndex)])
    emit(["kind": "playing", "playing": playing])
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  /// An optional index as the event channel wants it: a number or null.
  private static func box(_ index: Int?) -> Any { index.map { $0 as Any } ?? NSNull() }

  private func emit(_ event: [String: Any]) {
    sink?(event)
  }
}
