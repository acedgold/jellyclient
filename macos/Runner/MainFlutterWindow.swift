import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Version dans la barre de titre (à bumper à chaque release, comme Linux/Windows)
    self.title = "JellyClient v1.0.6"

    super.awakeFromNib()
  }
}
