import FlutterMacOS

/// Flutter side of the AI super-resolution (SQ-AI, TECH_SPEC §4.8).
///
/// Method channel `nyaplayer/sr`:
///  - `status` -> `{available: Bool}`: whether the Core ML model is installed.
///  - `convert {job, source, destination}`: queues a conversion; returns at once.
///  - `cancel {job}`.
/// Event channel `nyaplayer/sr/events`: `{job, kind: progress|done|error|cancelled,
/// fraction?, message?}`. Jobs run one at a time on a background queue: the
/// network already keeps the GPU busy.
final class MacSuperResolution: NSObject, FlutterStreamHandler {
  private let method: FlutterMethodChannel
  private let events: FlutterEventChannel
  private var sink: FlutterEventSink?
  private let queue = DispatchQueue(label: "nyaplayer.sr", qos: .utility)
  private let lock = NSLock()
  private var cancelled = Set<Int>()
  private var converter: SRConverter?
  /// Jobs queued or running. When the last one ends the converter is dropped:
  /// the model and its GPU buffers (a conversion peaks near 2 GB) have no
  /// business staying in memory between conversions; loading takes about 1.4 s.
  private var pending = 0

  init(messenger: FlutterBinaryMessenger) {
    method = FlutterMethodChannel(name: "nyaplayer/sr", binaryMessenger: messenger)
    events = FlutterEventChannel(name: "nyaplayer/sr/events", binaryMessenger: messenger)
    super.init()
    method.setMethodCallHandler { [weak self] call, result in self?.handle(call, result) }
    events.setStreamHandler(self)
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "status":
      result(["available": SRConverter.locateModel() != nil])
    case "convert":
      guard let job = (args["job"] as? NSNumber)?.intValue,
        let source = args["source"] as? String,
        let destination = args["destination"] as? String
      else { return result(FlutterError(code: "args", message: "job, source, destination", details: nil)) }
      let seconds = (args["maxSeconds"] as? NSNumber)?.doubleValue
      lock.lock()
      pending += 1
      lock.unlock()
      queue.async { [weak self] in
        self?.run(job, source, destination, seconds)
        self?.jobEnded()
      }
      result(nil)
    case "cancel":
      if let job = (args["job"] as? NSNumber)?.intValue {
        lock.lock()
        cancelled.insert(job)
        lock.unlock()
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func isCancelled(_ job: Int) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return cancelled.contains(job)
  }

  private func jobEnded() {
    lock.lock()
    pending -= 1
    let idle = pending <= 0
    lock.unlock()
    // `converter` is only touched on `queue`, which this runs on.
    if idle { converter = nil }
  }

  private func run(_ job: Int, _ source: String, _ destination: String, _ seconds: Double?) {
    if isCancelled(job) { return emit(["job": job, "kind": "cancelled"]) }
    do {
      if converter == nil {
        guard let url = SRConverter.locateModel() else { throw SRConverter.Failure.modelMissing }
        converter = try SRConverter(modelURL: url)
      }
      var last = -1.0
      try converter!.convert(
        source: URL(fileURLWithPath: source), destination: URL(fileURLWithPath: destination),
        maxSeconds: seconds,
        progress: { [weak self] fraction in
          // Throttled: a chunk takes seconds, but a short file can be one chunk.
          if fraction - last >= 0.005 || fraction >= 1 {
            last = fraction
            self?.emit(["job": job, "kind": "progress", "fraction": fraction])
          }
        },
        isCancelled: { [weak self] in self?.isCancelled(job) ?? true })
      emit(["job": job, "kind": "done"])
    } catch SRConverter.Failure.cancelled {
      emit(["job": job, "kind": "cancelled"])
    } catch {
      emit(["job": job, "kind": "error", "message": "\(error.localizedDescription)"])
    }
  }

  private func emit(_ event: [String: Any]) {
    DispatchQueue.main.async { [weak self] in self?.sink?(event) }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }
}
