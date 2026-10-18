import AVFoundation

/// macOS playback core on AVAudioEngine (TECH_SPEC §4.7, M10-6).
///
/// Decoding and output are the system's (AudioToolbox / CoreAudio). The graph
/// is `AVAudioPlayerNode -> AVAudioUnitEQ (10 bands) -> main mixer`.
///
/// Gapless playback: shortly before the current file ends the next one is
/// scheduled on the same player node, which plays queued segments back to
/// back. A file whose sample rate or channel count differs from the one the
/// node is connected with cannot be queued behind it; that boundary rebuilds
/// the graph and leaves a short gap.
///
/// Everything runs on the main thread (Flutter delivers channel calls there
/// and the node's completion callbacks are hopped onto it).
final class MacPlayerCore {
  enum Loop { case none, all, one }

  var onPlaying: ((Bool) -> Void)?
  var onIndex: ((Int?) -> Void)?
  var onCompleted: (() -> Void)?
  var onError: ((String) -> Void)?

  /// Same centres as the Rust core and `eqBandFrequencies` in Dart.
  static let bandFrequencies: [Float] = [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]

  /// Consecutive files that fail to open before playback stops (FMT-07).
  private static let maxConsecutiveFailures = 5
  /// How long before the end the next file is queued behind the current one.
  private static let prefetchLead = 6.0

  private struct Item {
    var index: Int
    let path: String
    let file: AVAudioFile
    /// Where this item starts on the node's timeline, in frames.
    let startSample: AVAudioFramePosition
    /// Where in the file it starts (non-zero after a seek).
    let startFrame: AVAudioFramePosition
    let token: Int
  }

  private let engine = AVAudioEngine()
  private let node = AVAudioPlayerNode()
  private let eq = AVAudioUnitEQ(numberOfBands: 10)
  private var connectedFormat: AVAudioFormat?

  private var paths: [String] = []
  private(set) var currentIndex: Int?
  private var loop: Loop = .none
  /// What the user asked for; the node itself may be idle at the end of a queue.
  private(set) var wantsToPlay = false

  /// Items queued on the node; the first is the one being heard.
  private var queued: [Item] = []
  /// Bumped on every restart so callbacks from a flushed node are ignored.
  private var generation = 0
  private var tokenCounter = 0
  private var failures = 0
  private var cachedPosition = 0.0
  private var timer: Timer?
  private var observer: NSObjectProtocol?

  init() {
    engine.attach(node)
    engine.attach(eq)
    for (i, frequency) in Self.bandFrequencies.enumerated() {
      let band = eq.bands[i]
      band.filterType = .parametric
      band.frequency = frequency
      band.bandwidth = 1.0  // octaves, as the Rust core's Q = sqrt(2)
      band.gain = 0
      band.bypass = false
    }
    // Disabled until the app sends its settings.
    eq.bypass = true
    // The output device changed (headphones unplugged, Bluetooth switched):
    // the engine stops itself; rebuild and carry on from where we were.
    observer = NotificationCenter.default.addObserver(
      forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
    ) { [weak self] _ in self?.recoverFromConfigurationChange() }
  }

  deinit {
    if let observer { NotificationCenter.default.removeObserver(observer) }
    timer?.invalidate()
  }

  // MARK: Transport

  func openQueue(paths: [String], start: Int, autoplay: Bool) {
    self.paths = paths
    failures = 0
    if paths.isEmpty {
      stopAll()
      return
    }
    wantsToPlay = autoplay
    begin(at: min(max(start, 0), paths.count - 1), offset: 0, announce: true)
  }

  func play() {
    guard let current = currentIndex else { return }
    wantsToPlay = true
    if queued.isEmpty {
      // Nothing loaded (first play, or the queue finished): start the item.
      begin(at: current, offset: 0, announce: false)
      return
    }
    resumeNode()
  }

  func pause() {
    wantsToPlay = false
    cachedPosition = positionSeconds()
    node.pause()
    stopTimer()
    onPlaying?(false)
  }

  func seek(seconds: Double) {
    guard let current = currentIndex, !paths.isEmpty else { return }
    begin(at: current, offset: max(0, seconds), announce: false)
  }

  func jump(to index: Int) {
    guard index >= 0, index < paths.count else { return }
    begin(at: index, offset: 0, announce: true)
  }

  // MARK: Queue edits

  func add(path: String) {
    paths.append(path)
    if currentIndex == nil {
      currentIndex = 0
      onIndex?(0)
    }
    refreshNext()
  }

  func insert(at index: Int, path: String) {
    let at = min(max(index, 0), paths.count)
    paths.insert(path, at: at)
    if let current = currentIndex, at <= current {
      currentIndex = current + 1
      syncQueuedIndexes()
      onIndex?(currentIndex)
    } else if currentIndex == nil {
      currentIndex = 0
      onIndex?(0)
    }
    refreshNext()
  }

  func remove(at index: Int) {
    guard index >= 0, index < paths.count else { return }
    paths.remove(at: index)
    guard let current = currentIndex else { return }
    if paths.isEmpty {
      stopAll()
    } else if index == current {
      // The next item (or the previous one at the end) takes over.
      begin(at: min(index, paths.count - 1), offset: 0, announce: true)
    } else {
      if index < current {
        currentIndex = current - 1
        syncQueuedIndexes()
        onIndex?(currentIndex)
      }
      refreshNext()
    }
  }

  func move(from: Int, to: Int) {
    guard from >= 0, from < paths.count, to >= 0, to < paths.count, from != to else { return }
    let path = paths.remove(at: from)
    paths.insert(path, at: to)
    guard let current = currentIndex else { return }
    var updated = current
    if from == current {
      updated = to
    } else if from < current && to >= current {
      updated = current - 1
    } else if from > current && to <= current {
      updated = current + 1
    }
    if updated != current {
      currentIndex = updated
      syncQueuedIndexes()
      onIndex?(updated)
    }
    refreshNext()
  }

  /// `order[newPosition]` is the old index of the item that moves there.
  func reorder(_ order: [Int]) {
    guard order.count == paths.count, Set(order).count == order.count,
      order.allSatisfy({ $0 >= 0 && $0 < paths.count })
    else { return }
    let old = paths
    paths = order.map { old[$0] }
    if let current = currentIndex, let updated = order.firstIndex(of: current) {
      currentIndex = updated
      syncQueuedIndexes()
      onIndex?(updated)
    }
    refreshNext()
  }

  func setLoop(_ mode: Loop) {
    loop = mode
    refreshNext()
  }

  // MARK: Settings

  func setVolume(_ volume: Float) {
    engine.mainMixerNode.outputVolume = min(max(volume, 0), 1)
  }

  /// `gains` in dB per band; `preamp` already includes clipping prevention.
  func setEqualizer(enabled: Bool, gains: [Double], preamp: Double) {
    eq.bypass = !enabled
    for i in 0..<min(gains.count, eq.bands.count) {
      eq.bands[i].gain = Float(enabled ? gains[i] : 0)
    }
    eq.globalGain = Float(enabled ? preamp : 0)
  }

  // MARK: Position

  func positionSeconds() -> Double {
    guard let item = queued.first, node.isPlaying,
      let nodeTime = node.lastRenderTime, nodeTime.isSampleTimeValid,
      let playerTime = node.playerTime(forNodeTime: nodeTime)
    else { return cachedPosition }
    let rate = item.file.processingFormat.sampleRate
    let played = Double(playerTime.sampleTime - item.startSample) / rate
    let start = Double(item.startFrame) / rate
    let length = Double(item.file.length) / rate
    cachedPosition = min(start + max(0, played), length)
    return cachedPosition
  }

  // MARK: Starting items

  /// Flushes the node and starts `index` at `offset` seconds, then queues the
  /// item that follows. Files that cannot be opened are reported and skipped.
  private func begin(at index: Int, offset: Double, announce: Bool) {
    generation += 1
    node.stop()
    queued.removeAll()
    stopTimer()

    var candidate = index
    var offset = offset
    var tried = 0
    while true {
      do {
        let file = try AVAudioFile(forReading: URL(fileURLWithPath: paths[candidate]))
        try connect(for: file.processingFormat)
        let rate = file.processingFormat.sampleRate
        let startFrame = min(AVAudioFramePosition(offset * rate), max(file.length - 1, 0))
        currentIndex = candidate
        cachedPosition = Double(startFrame) / rate
        schedule(index: candidate, file: file, startFrame: startFrame, startSample: 0)
        failures = 0
        if announce || candidate != index { onIndex?(candidate) }
        break
      } catch {
        onError?("\(paths[candidate]): \(error.localizedDescription)")
        failures += 1
        tried += 1
        guard failures < Self.maxConsecutiveFailures, tried < paths.count,
          let next = indexAfter(candidate)
        else {
          currentIndex = candidate
          cachedPosition = 0
          wantsToPlay = false
          onIndex?(candidate)
          onPlaying?(false)
          return
        }
        candidate = next
        offset = 0
      }
    }

    maybePrefetch()
    if wantsToPlay {
      resumeNode()
    } else {
      onPlaying?(false)
    }
  }

  private func resumeNode() {
    do {
      if !engine.isRunning { try engine.start() }
    } catch {
      onError?("cannot start audio output: \(error.localizedDescription)")
      wantsToPlay = false
      onPlaying?(false)
      return
    }
    node.play()
    startTimer()
    onPlaying?(true)
  }

  /// (Re)connects the graph for a file format; a no-op when it already fits.
  private func connect(for format: AVAudioFormat) throws {
    if let connected = connectedFormat,
      connected.sampleRate == format.sampleRate,
      connected.channelCount == format.channelCount,
      engine.isRunning
    {
      return
    }
    if engine.isRunning { engine.stop() }
    engine.disconnectNodeOutput(node)
    engine.disconnectNodeOutput(eq)
    engine.connect(node, to: eq, format: format)
    engine.connect(eq, to: engine.mainMixerNode, format: format)
    engine.prepare()
    try engine.start()
    connectedFormat = format
  }

  private func schedule(
    index: Int, file: AVAudioFile, startFrame: AVAudioFramePosition,
    startSample: AVAudioFramePosition
  ) {
    tokenCounter += 1
    let token = tokenCounter
    let current = generation
    let frames = file.length - startFrame
    queued.append(
      Item(
        index: index, path: paths[index], file: file, startSample: startSample,
        startFrame: startFrame, token: token))
    node.scheduleSegment(
      file, startingFrame: startFrame, frameCount: AVAudioFrameCount(max(frames, 0)),
      at: nil, completionCallbackType: .dataPlayedBack
    ) { [weak self] _ in
      DispatchQueue.main.async { self?.itemFinished(generation: current, token: token) }
    }
  }

  // MARK: Following items

  private func indexAfter(_ index: Int) -> Int? {
    guard !paths.isEmpty else { return nil }
    switch loop {
    case .one: return index
    case .all: return (index + 1) % paths.count
    case .none: return index + 1 < paths.count ? index + 1 : nil
    }
  }

  /// Queues the item that follows the last queued one, when it can play
  /// gaplessly behind it and is due soon enough.
  private func prefetchNext() {
    guard queued.count == 1, let last = queued.last else { return }
    var candidate = indexAfter(last.index)
    var tried = 0
    while let index = candidate, tried < paths.count {
      do {
        let file = try AVAudioFile(forReading: URL(fileURLWithPath: paths[index]))
        let format = file.processingFormat
        guard let connected = connectedFormat,
          connected.sampleRate == format.sampleRate,
          connected.channelCount == format.channelCount
        else { return }  // different format: handled at the boundary
        let frames = last.file.length - last.startFrame
        schedule(index: index, file: file, startFrame: 0, startSample: last.startSample + frames)
        return
      } catch {
        onError?("\(paths[index]): \(error.localizedDescription)")
        tried += 1
        candidate = indexAfter(index)
        if candidate == index { return }  // repeat-one on a broken file
      }
    }
  }

  /// Called after queue edits: the queued follow-up may no longer be the right
  /// one. Nodes cannot drop a single queued segment, so restart the current
  /// item from where it is (a rare, tiny glitch) only when that happens.
  private func refreshNext() {
    guard let current = currentIndex, current < paths.count, !queued.isEmpty else { return }
    if queued.count > 1 {
      let wanted = indexAfter(current).map { paths[$0] }
      if queued[1].path != wanted || queued[0].path != paths[current] {
        begin(at: current, offset: positionSeconds(), announce: false)
        return
      }
    }
    syncQueuedIndexes()
  }

  /// Queue edits renumber items; the queued segments keep their files, so
  /// refresh the indexes they report when they become current.
  private func syncQueuedIndexes() {
    guard let current = currentIndex, !queued.isEmpty else { return }
    queued[0].index = current
    if queued.count > 1, let next = indexAfter(current) { queued[1].index = next }
  }

  private func itemFinished(generation: Int, token: Int) {
    guard generation == self.generation, let first = queued.first, first.token == token else {
      return
    }
    queued.removeFirst()
    failures = 0
    if let now = queued.first {
      // The follow-up is already playing, with no gap.
      currentIndex = now.index
      cachedPosition = Double(now.startFrame) / now.file.processingFormat.sampleRate
      onIndex?(now.index)
      maybePrefetch()
    } else if let next = indexAfter(first.index) {
      // Nothing was queued (different format, or a late edit): start it now.
      wantsToPlay = true
      begin(at: next, offset: 0, announce: true)
    } else {
      finishQueue()
    }
  }

  private func finishQueue() {
    node.stop()
    stopTimer()
    wantsToPlay = false
    cachedPosition = 0
    onPlaying?(false)
    onCompleted?()
  }

  private func stopAll() {
    generation += 1
    node.stop()
    queued.removeAll()
    stopTimer()
    wantsToPlay = false
    cachedPosition = 0
    currentIndex = nil
    onIndex?(nil)
    onPlaying?(false)
  }

  // MARK: Housekeeping

  private func startTimer() {
    guard timer == nil else { return }
    timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
      self?.tick()
    }
  }

  private func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  private func tick() { maybePrefetch() }

  /// Queues the follow-up once the current item is within [prefetchLead] of
  /// its end. Waiting keeps queue edits from invalidating it early.
  private func maybePrefetch() {
    guard queued.count == 1, let item = queued.first else { return }
    let length = Double(item.file.length) / item.file.processingFormat.sampleRate
    if length - positionSeconds() < Self.prefetchLead { prefetchNext() }
  }

  private func recoverFromConfigurationChange() {
    guard let current = currentIndex, !paths.isEmpty else { return }
    let position = positionSeconds()
    connectedFormat = nil
    begin(at: current, offset: position, announce: false)
  }
}
