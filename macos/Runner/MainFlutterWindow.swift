import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // Configure window transparency
    self.styleMask = [.borderless]
    self.isOpaque = false
    self.backgroundColor = NSColor.clear
    self.hasShadow = false
    self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
    
    // Critical: Set Flutter view controller background to clear
    flutterViewController.backgroundColor = .clear

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
