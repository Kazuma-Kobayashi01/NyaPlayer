import Cocoa
import FlutterMacOS
import WidgetKit

@available(macOS 14.0, *)
@MainActor
final class PlayerWidgetBridge {
  private let channel: FlutterMethodChannel
  private let storage = DispatchQueue(label: "com.kazuma.nyaplayer.widget-storage", qos: .utility)
  private var ready = false
  private var reloadWork: DispatchWorkItem?

  init(channel: FlutterMethodChannel) {
    self.channel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    WidgetCommandRouter.handler = { [weak self] command in
      guard let self else { throw CancellationError() }
      try await self.execute(command)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported": result(true)
    case "ready": ready = true; result(nil)
    case "publishSnapshot":
      guard var payload = call.arguments as? [String: Any] else {
        result(FlutterError(code: "invalid_snapshot", message: nil, details: nil)); return
      }
      let artworkSource = payload.removeValue(forKey: "artworkSource") as? String
      let reload = payload.removeValue(forKey: "reload") as? Bool ?? true
      storage.async {
        do {
          var snapshot = try JSONDecoder().decode(
            PlayerWidgetSnapshot.self, from: JSONSerialization.data(withJSONObject: payload))
          snapshot.artworkName = try? PlayerWidgetStore.importArtwork(from: artworkSource)
          try PlayerWidgetStore.save(snapshot)
          DispatchQueue.main.async { [weak self] in
            if reload { self?.reload() }
            result(nil)
          }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "widget_storage", message: error.localizedDescription, details: nil))
          }
        }
      }
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func reload() {
    reloadWork?.cancel()
    let work = DispatchWorkItem {
      WidgetCenter.shared.reloadTimelines(ofKind: PlayerWidgetStore.kind)
    }
    reloadWork = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
  }

  private func execute(_ command: WidgetPlayerCommand) async throws {
    for _ in 0..<150 {
      if ready { break }
      try await Task.sleep(nanoseconds: 100_000_000)
    }
    guard ready else {
      throw NSError(domain: "NyaPlayer.Widget", code: 3, userInfo: [
        NSLocalizedDescriptionKey: "The player is not ready yet.",
      ])
    }
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      var finished = false
      let finish: (Error?) -> Void = { error in
        guard !finished else { return }; finished = true
        if let error { continuation.resume(throwing: error) }
        else { continuation.resume() }
      }
      channel.invokeMethod("command", arguments: command.arguments) { response in
        if let error = response as? FlutterError {
          finish(NSError(domain: "NyaPlayer.Widget", code: 4, userInfo: [
            NSLocalizedDescriptionKey: error.message ?? error.code,
          ]))
        } else if let value = response as? NSObject, value == FlutterMethodNotImplemented {
          finish(NSError(domain: "NyaPlayer.Widget", code: 5, userInfo: [
            NSLocalizedDescriptionKey: "The player does not support this action.",
          ]))
        } else { finish(nil) }
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
        finish(NSError(domain: "NyaPlayer.Widget", code: 6, userInfo: [
          NSLocalizedDescriptionKey: "The player did not respond.",
        ]))
      }
    }
  }
}
