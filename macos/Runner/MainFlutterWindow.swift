import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // Configure for true transparency like Übersicht
    self.styleMask = [.borderless]
    self.isOpaque = false
    self.backgroundColor = NSColor.clear
    self.hasShadow = true
    self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
