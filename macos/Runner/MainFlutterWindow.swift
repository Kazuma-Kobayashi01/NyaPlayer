import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

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
}
