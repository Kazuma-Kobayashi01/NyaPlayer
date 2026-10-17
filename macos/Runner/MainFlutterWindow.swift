import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Dev aid: NYA_WINDOW_SIZE=400x860 opens the window phone-sized.
    if let spec = ProcessInfo.processInfo.environment["NYA_WINDOW_SIZE"] {
      let parts = spec.split(separator: "x").compactMap { Double($0) }
      if parts.count == 2 {
        // Delayed so it wins over macOS window-frame restoration.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
          self.setContentSize(NSSize(width: parts[0], height: parts[1]))
          self.center()
        }
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
