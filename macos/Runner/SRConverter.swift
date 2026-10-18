import Accelerate
import AVFoundation
import CoreML

/// AI super-resolution of a lossy file into a 16-bit / 44.1 kHz FLAC (SQ-AI).
///
/// The network is Apollo (JusperLee/Apollo, CC BY-SA 4.0) converted to Core ML
/// without its STFT / iSTFT, so those are done here with matrix products on
/// Accelerate (882 = 2·3²·7² is not a size vDSP's FFT supports). Each chunk of
/// 5 s is run with 1 s of real audio on both sides, which is thrown away
/// afterwards because the network is wrong near the edge of what it is given;
/// every chunk is computed once and the results are joined. Everything the
/// network needs to match the Python reference lives in `python/` (see
/// `coreml_convert.py`); `docs/TECH_SPEC.md` §4.8 has the decisions.
final class SRConverter {
  enum Failure: LocalizedError {
    case modelMissing
    case cancelled
    case cannotRead(String)
    case cannotWrite(String)
    case badModelOutput

    var errorDescription: String? {
      switch self {
      case .modelMissing: return "The super-resolution model is not installed."
      case .cancelled: return "Cancelled."
      case .cannotRead(let why): return "Cannot read the audio: \(why)"
      case .cannotWrite(let why): return "Cannot write the FLAC: \(why)"
      case .badModelOutput: return "The model returned an unexpected result."
      }
    }
  }

  static let sampleRate = 44100.0
  private static let nFFT = 882
  private static let hop = 441
  private static let bins = 442
  /// Real audio kept on each side of a chunk and thrown away afterwards: the
  /// network is wrong near the edge of what it is given. 0.5 s is not enough
  /// (a click at every seam, measured), 1 s is seamless.
  private static let padSamples = 44100
  private static let channels = 2
  /// The model was converted for a fixed window of this many STFT frames
  /// (`python/coreml_convert.py --seconds 12` gives 1201); read from the model.
  private let frames: Int
  private let windowSamples: Int
  /// What each window contributes: the window minus its two pads. A longer
  /// window wastes less on the pads (12 s: 10 s of 12) but the network gets
  /// slower per second beyond that (measured: 17 s windows are slower overall).
  private let chunkSamples: Int

  /// The model file, without extension (`python/coreml_convert.py`).
  static let modelName = "apollo_core_fp16_12s"

  /// Where a model may be: inside the app, or dropped into Application Support.
  static func locateModel() -> URL? {
    let name = modelName
    if let bundled = Bundle.main.url(forResource: name, withExtension: "mlpackage")
      ?? Bundle.main.url(forResource: name, withExtension: "mlmodelc")
    {
      return bundled
    }
    let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
      .first?.appendingPathComponent("NyaPlayer/SR", isDirectory: true)
    for ext in ["mlmodelc", "mlpackage"] {
      if let url = support?.appendingPathComponent("\(name).\(ext)"),
        FileManager.default.fileExists(atPath: url.path)
      {
        return url
      }
    }
    return nil
  }

  private let model: MLModel
  // STFT as matrices: frames [T×N] times these.
  private var forwardCos = [Float]()  // [N×K]   w[n]·cos(2πkn/N)
  private var forwardSin = [Float]()  // [N×K]  -w[n]·sin(2πkn/N)
  private var inverseCos = [Float]()  // [K×N]   a_k·cos(2πkn/N)/N
  private var inverseSin = [Float]()  // [K×N]  -a_k·sin(2πkn/N)/N
  private var window = [Float]()
  private var envelopeInverse = [Float]()  // 1 / Σ w², per padded sample

  init(modelURL: URL) throws {
    var url = modelURL
    if url.pathExtension == "mlpackage" {
      url = try SRConverter.compiledCopy(of: modelURL)
    }
    let config = MLModelConfiguration()
    config.computeUnits = .cpuAndGPU
    model = try MLModel(contentsOf: url, configuration: config)
    let shape = model.modelDescription.inputDescriptionsByName["re"]?
      .multiArrayConstraint?.shape.map(\.intValue)
    frames = (shape?.count == 3 ? shape![2] : nil) ?? 1201
    windowSamples = (frames - 1) * SRConverter.hop
    chunkSamples = windowSamples - 2 * SRConverter.padSamples
    buildTransforms()
  }

  /// Compiling an .mlpackage takes seconds; keep the result next to the
  /// package's modification time.
  private static func compiledCopy(of package: URL) throws -> URL {
    let fm = FileManager.default
    let dir = try fm.url(
      for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("NyaPlayer/SR", isDirectory: true)
    try fm.createDirectory(at: dir, withIntermediateDirectories: true)
    let target = dir.appendingPathComponent(
      package.deletingPathExtension().lastPathComponent + ".compiled.mlmodelc")
    let stamp = (try? package.resourceValues(forKeys: [.contentModificationDateKey]))?
      .contentModificationDate
    let built = (try? target.resourceValues(forKeys: [.contentModificationDateKey]))?
      .contentModificationDate
    if let stamp, let built, built >= stamp { return target }
    let temp = try MLModel.compileModel(at: package)
    try? fm.removeItem(at: target)
    try fm.moveItem(at: temp, to: target)
    return target
  }

  private func buildTransforms() {
    let n = SRConverter.nFFT, k = SRConverter.bins, hop = SRConverter.hop
    // torch.hann_window (periodic).
    window = (0..<n).map { Float(0.5 - 0.5 * cos(2 * Double.pi * Double($0) / Double(n))) }
    forwardCos = [Float](repeating: 0, count: n * k)
    forwardSin = [Float](repeating: 0, count: n * k)
    inverseCos = [Float](repeating: 0, count: k * n)
    inverseSin = [Float](repeating: 0, count: k * n)
    for bin in 0..<k {
      // One-sided inverse: bins other than DC and Nyquist count twice.
      let scale = (bin == 0 || bin == n / 2) ? 1.0 : 2.0
      for i in 0..<n {
        let angle = 2 * Double.pi * Double((bin * i) % n) / Double(n)
        forwardCos[i * k + bin] = window[i] * Float(cos(angle))
        forwardSin[i * k + bin] = -window[i] * Float(sin(angle))
        inverseCos[bin * n + i] = Float(scale * cos(angle) / Double(n))
        inverseSin[bin * n + i] = Float(-scale * sin(angle) / Double(n))
      }
    }
    let length = n + hop * (frames - 1)
    var envelope = [Float](repeating: 0, count: length)
    for t in 0..<frames {
      for i in 0..<n { envelope[t * hop + i] += window[i] * window[i] }
    }
    envelopeInverse = envelope.map { $0 > 1e-11 ? 1 / $0 : 0 }
  }

  // MARK: Conversion

  /// Converts `source` into a FLAC at `destination`. `maxSeconds` limits the
  /// work to the start of the file (tests). `progress` gets 0...1 after each
  /// chunk; throw from `isCancelled` handling by returning true.
  func convert(
    source: URL, destination: URL, maxSeconds: Double? = nil,
    progress: (Double) -> Void, isCancelled: () -> Bool
  ) throws {
    var audio = try SRConverter.readStereo(source)
    if let maxSeconds {
      let limit = Int(maxSeconds * SRConverter.sampleRate)
      if audio[0].count > limit { audio = audio.map { Array($0[0..<limit]) } }
    }
    let total = audio[0].count
    if total == 0 { throw Failure.cannotRead("the file has no audio") }
    // Shorter than one window: pad with silence, crop afterwards.
    let padded = max(total, windowSamples)
    if padded > total { audio = audio.map { $0 + [Float](repeating: 0, count: padded - total) } }

    var output = [[Float]](
      repeating: [Float](repeating: 0, count: total), count: SRConverter.channels)
    var start = 0
    while start < total {
      if isCancelled() { throw Failure.cancelled }
      let count = min(chunkSamples, total - start)
      let from = min(max(0, start - SRConverter.padSamples), padded - windowSamples)
      let window = audio.map { Array($0[from..<(from + windowSamples)]) }
      let result = try run(window: window)
      let offset = start - from
      for ch in 0..<SRConverter.channels {
        output[ch].replaceSubrange(start..<(start + count), with: result[ch][offset..<(offset + count)])
      }
      start += count
      progress(Double(start) / Double(total))
    }

    // The network changes the level a little, and its peaks can pass full
    // scale. Match the song's loudness to the input's (RMS over the whole song),
    // then catch whatever is still too high with a limiter instead of turning
    // the whole song down.
    let inputRMS = SRConverter.rms(audio.map { Array($0[0..<total]) })
    let outputRMS = SRConverter.rms(output)
    if inputRMS > 1e-6, outputRMS > 1e-6 {
      let gain = min(max(inputRMS / outputRMS, 0.5), 2)  // within +-6 dB
      output = output.map { vDSP.multiply(gain, $0) }
    }
    SRConverter.limit(&output, ceiling: 0.999)
    try SRConverter.writeFLAC(output, to: destination)
  }

  /// Root mean square over all channels together.
  static func rms(_ channels: [[Float]]) -> Float {
    let count = channels.reduce(0) { $0 + $1.count }
    guard count > 0 else { return 0 }
    let sum = channels.reduce(Double(0)) { $0 + Double(vDSP.sumOfSquares($1)) }
    return Float((sum / Double(count)).squareRoot())
  }

  /// A look-ahead brick-wall limiter, stereo-linked: nothing leaves above
  /// `ceiling`, and samples that need no limiting are left exactly as they are.
  ///
  /// Each sample's wanted gain is `ceiling / |peak|` (at most 1). The gain
  /// curve is the minimum of those over a window of ±`reach` samples, then
  /// averaged over the same window: the average of values that are all at most
  /// the wanted gain at a sample is itself at most that, so the ceiling holds,
  /// and the gain glides down before a peak and back up after it (10 ms each
  /// way) instead of clipping it.
  static func limit(_ channels: inout [[Float]], ceiling: Float, reach: Int = 441) {
    let count = channels[0].count
    var wanted = [Float](repeating: 1, count: count)
    var any = false
    for i in 0..<count {
      var peak: Float = 0
      for ch in 0..<channels.count { peak = max(peak, abs(channels[ch][i])) }
      if peak > ceiling {
        wanted[i] = ceiling / peak
        any = true
      }
    }
    guard any else { return }

    // Sliding minimum over [i-reach, i+reach] with a monotonic queue.
    var lowest = [Float](repeating: 1, count: count)
    var queue = [Int](repeating: 0, count: count)
    var head = 0, tail = 0
    var next = 0
    for i in 0..<count {
      let last = min(count - 1, i + reach)
      while next <= last {
        while tail > head && wanted[queue[tail - 1]] >= wanted[next] { tail -= 1 }
        queue[tail] = next
        tail += 1
        next += 1
      }
      while queue[head] < i - reach { head += 1 }
      lowest[i] = wanted[queue[head]]
    }
    // Moving average of that, in Double so a long sum does not drift.
    var prefix = [Double](repeating: 0, count: count + 1)
    for i in 0..<count { prefix[i + 1] = prefix[i] + Double(lowest[i]) }
    for i in 0..<count {
      let from = max(0, i - reach), to = min(count - 1, i + reach)
      let gain = Float((prefix[to + 1] - prefix[from]) / Double(to - from + 1))
      if gain < 1 {
        for ch in 0..<channels.count { channels[ch][i] *= gain }
      }
    }
    // Float rounding of the average: never let a sample past the ceiling.
    for ch in 0..<channels.count {
      for i in 0..<count { channels[ch][i] = min(max(channels[ch][i], -ceiling), ceiling) }
    }
  }

  /// One window (12 s) of [channel][samples] through STFT, the network, iSTFT.
  private func run(window audio: [[Float]]) throws -> [[Float]] {
    let n = SRConverter.nFFT, k = SRConverter.bins, t = frames
    let hop = SRConverter.hop, count = windowSamples
    let input = try (MLMultiArray(shape: [2, NSNumber(value: k), NSNumber(value: t)], dataType: .float32),
                     MLMultiArray(shape: [2, NSNumber(value: k), NSNumber(value: t)], dataType: .float32))
    let reIn = input.0.dataPointer.assumingMemoryBound(to: Float.self)
    let imIn = input.1.dataPointer.assumingMemoryBound(to: Float.self)

    for ch in 0..<SRConverter.channels {
      let x = audio[ch]
      // Reflect padding, as torch.stft(center=True).
      let paddedCount = n + hop * (t - 1)
      var padded = [Float](repeating: 0, count: paddedCount)
      for i in 0..<paddedCount {
        var j = i - n / 2
        if j < 0 { j = -j }
        if j >= count { j = 2 * (count - 1) - j }
        padded[i] = x[max(0, min(count - 1, j))]
      }
      var frames = [Float](repeating: 0, count: t * n)
      for f in 0..<t { for i in 0..<n { frames[f * n + i] = padded[f * hop + i] } }
      // Spectrum^T [K×T] = basis^T [K×N] · frames^T [N×T].
      let base = ch * k * t
      cblas_sgemm(CblasRowMajor, CblasTrans, CblasTrans, Int32(k), Int32(t), Int32(n), 1,
                  forwardCos, Int32(k), frames, Int32(n), 0, reIn + base, Int32(t))
      cblas_sgemm(CblasRowMajor, CblasTrans, CblasTrans, Int32(k), Int32(t), Int32(n), 1,
                  forwardSin, Int32(k), frames, Int32(n), 0, imIn + base, Int32(t))
    }

    let features = try MLDictionaryFeatureProvider(dictionary: ["re": input.0, "im": input.1])
    let prediction = try model.prediction(from: features)
    guard let estRe = prediction.featureValue(for: "est_re")?.multiArrayValue,
      let estIm = prediction.featureValue(for: "est_im")?.multiArrayValue,
      estRe.shape.map(\.intValue) == [2, k, t]
    else { throw Failure.badModelOutput }
    let re = SRConverter.contiguous(estRe), im = SRConverter.contiguous(estIm)

    var result = [[Float]]()
    for ch in 0..<SRConverter.channels {
      // Frames [T×N] = Re^T [T×K]·basisCos [K×N] + Im^T·basisSin.
      var framesOut = [Float](repeating: 0, count: t * n)
      let base = ch * k * t
      re.withUnsafeBufferPointer { r in
        im.withUnsafeBufferPointer { m in
          cblas_sgemm(CblasRowMajor, CblasTrans, CblasNoTrans, Int32(t), Int32(n), Int32(k), 1,
                      r.baseAddress! + base, Int32(t), inverseCos, Int32(n), 0, &framesOut, Int32(n))
          cblas_sgemm(CblasRowMajor, CblasTrans, CblasNoTrans, Int32(t), Int32(n), Int32(k), 1,
                      m.baseAddress! + base, Int32(t), inverseSin, Int32(n), 1, &framesOut, Int32(n))
        }
      }
      // Window, overlap-add, divide by the window envelope, drop the centre padding.
      var overlapped = [Float](repeating: 0, count: n + hop * (t - 1))
      for f in 0..<t {
        for i in 0..<n { overlapped[f * hop + i] += framesOut[f * n + i] * window[i] }
      }
      var samples = [Float](repeating: 0, count: count)
      for i in 0..<count { samples[i] = overlapped[i + n / 2] * envelopeInverse[i + n / 2] }
      result.append(samples)
    }
    return result
  }

  /// A Core ML output as a dense [channel][bin][frame] float array: strides
  /// can be padded and the type can be half precision.
  private static func contiguous(_ array: MLMultiArray) -> [Float] {
    let shape = array.shape.map(\.intValue), strides = array.strides.map(\.intValue)
    var out = [Float](repeating: 0, count: shape[0] * shape[1] * shape[2])
    func copy<T>(_ type: T.Type, _ convert: (T) -> Float) {
      let p = array.dataPointer.assumingMemoryBound(to: T.self)
      var o = 0
      for a in 0..<shape[0] {
        for b in 0..<shape[1] {
          for c in 0..<shape[2] {
            out[o] = convert(p[a * strides[0] + b * strides[1] + c * strides[2]])
            o += 1
          }
        }
      }
    }
    switch array.dataType {
    case .float16: copy(Float16.self) { Float($0) }
    case .float32: copy(Float.self) { $0 }
    default: copy(Double.self) { Float($0) }
    }
    return out
  }

  // MARK: Audio files

  /// Any file AVFoundation can read, as two channels at 44.1 kHz.
  private static func readStereo(_ url: URL) throws -> [[Float]] {
    let file: AVAudioFile
    do { file = try AVAudioFile(forReading: url) } catch { throw Failure.cannotRead("\(error)") }
    guard let format = AVAudioFormat(
      commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 2, interleaved: false),
      let inBuffer = AVAudioPCMBuffer(
        pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
    else { throw Failure.cannotRead("no buffer") }
    try file.read(into: inBuffer)

    let buffer: AVAudioPCMBuffer
    if file.processingFormat.sampleRate == sampleRate && file.processingFormat.channelCount == 2 {
      buffer = inBuffer
    } else {
      // Resample, and make mono two-channel.
      guard let converter = AVAudioConverter(from: file.processingFormat, to: format) else {
        throw Failure.cannotRead("cannot convert the sample rate")
      }
      let capacity = AVAudioFrameCount(Double(inBuffer.frameLength) * sampleRate
        / file.processingFormat.sampleRate) + 4096
      guard let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
        throw Failure.cannotRead("no buffer")
      }
      var consumed = false
      var error: NSError?
      converter.convert(to: out, error: &error) { _, status in
        if consumed { status.pointee = .endOfStream; return nil }
        consumed = true
        status.pointee = .haveData
        return inBuffer
      }
      if let error { throw Failure.cannotRead("\(error)") }
      buffer = out
    }
    let frames = Int(buffer.frameLength)
    guard let data = buffer.floatChannelData else { throw Failure.cannotRead("no samples") }
    let left = Array(UnsafeBufferPointer(start: data[0], count: frames))
    let right = buffer.format.channelCount > 1
      ? Array(UnsafeBufferPointer(start: data[1], count: frames)) : left
    return [left, right]
  }

  /// 16-bit FLAC through ExtAudioFile. AVAudioFile cannot be told the source
  /// depth of a FLAC and writes 24-bit, which the app would then show as Hi-Res.
  private static func writeFLAC(_ channels: [[Float]], to url: URL) throws {
    let partial = url.deletingLastPathComponent()
      .appendingPathComponent(".\(url.lastPathComponent).part.flac")
    try? FileManager.default.removeItem(at: partial)

    var fileFormat = AudioStreamBasicDescription(
      mSampleRate: sampleRate, mFormatID: kAudioFormatFLAC,
      // kFLACFormatFlag_16BitSourceData (CoreAudioBaseTypes.h) is 1.
      mFormatFlags: 1,
      mBytesPerPacket: 0, mFramesPerPacket: 0, mBytesPerFrame: 0,
      mChannelsPerFrame: 2, mBitsPerChannel: 0, mReserved: 0)
    var client = AudioStreamBasicDescription(
      mSampleRate: sampleRate, mFormatID: kAudioFormatLinearPCM,
      mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked
        | kAudioFormatFlagIsNonInterleaved,
      mBytesPerPacket: 4, mFramesPerPacket: 1, mBytesPerFrame: 4,
      mChannelsPerFrame: 2, mBitsPerChannel: 32, mReserved: 0)

    var ref: ExtAudioFileRef?
    var status = ExtAudioFileCreateWithURL(
      partial as CFURL, kAudioFileFLACType, &fileFormat, nil,
      AudioFileFlags.eraseFile.rawValue, &ref)
    guard status == noErr, let file = ref else { throw Failure.cannotWrite("create: \(status)") }
    var closed = false
    func close() {
      if !closed { ExtAudioFileDispose(file); closed = true }
    }
    defer { close() }
    status = ExtAudioFileSetProperty(
      file, kExtAudioFileProperty_ClientDataFormat,
      UInt32(MemoryLayout<AudioStreamBasicDescription>.size), &client)
    guard status == noErr else { throw Failure.cannotWrite("format: \(status)") }

    let total = channels[0].count, step = 1 << 16
    var position = 0
    let list = AudioBufferList.allocate(maximumBuffers: 2)
    defer { free(list.unsafeMutablePointer) }
    while position < total {
      let count = min(step, total - position)
      for ch in 0..<2 {
        channels[ch].withUnsafeBufferPointer { p in
          list[ch] = AudioBuffer(
            mNumberChannels: 1, mDataByteSize: UInt32(count * 4),
            mData: UnsafeMutableRawPointer(mutating: p.baseAddress! + position))
        }
      }
      status = ExtAudioFileWrite(file, UInt32(count), list.unsafePointer)
      guard status == noErr else { throw Failure.cannotWrite("write: \(status)") }
      position += count
    }
    // Close (flush) before the file is moved into place.
    close()
    try? FileManager.default.removeItem(at: url)
    try FileManager.default.moveItem(at: partial, to: url)
  }
}
