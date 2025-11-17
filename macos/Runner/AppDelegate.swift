import Cocoa
import FlutterMacOS
import ImageIO
import UniformTypeIdentifiers

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  override func applicationDidFinishLaunching(_ aNotification: Notification) {
    let controller : FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
    let windowChannel = FlutterMethodChannel(name: "jaybar/window",
                                           binaryMessenger: controller.engine.binaryMessenger)
    let appIconChannel = FlutterMethodChannel(name: "jaybar/app_icon",
                                            binaryMessenger: controller.engine.binaryMessenger)
    
    windowChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "setWindowCollectionBehavior" {
        if let window = self.mainFlutterWindow {
          window.collectionBehavior = [.ignoresCycle, .canJoinAllSpaces, .stationary]
        }
        result(nil)
      } else if call.method == "positionInNotch" {
        if let window = self.mainFlutterWindow,
           let screen = NSScreen.main {
          if #available(macOS 12.0, *) {
            window.titlebarSeparatorStyle = .none
          }
          window.titleVisibility = .hidden
          window.styleMask.insert(.fullSizeContentView)
          
          let screenFrame = screen.frame
          let windowWidth = screenFrame.width
          let windowHeight = CGFloat(32.0)
          let targetFrame = NSRect(x: 0, y: screenFrame.maxY - windowHeight, width: windowWidth, height: windowHeight)
          
          window.setFrame(targetFrame, display: true)
        }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    appIconChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getFocusedAppIcon" {
        DispatchQueue.global(qos: .userInitiated).async {
          guard let frontApp = NSWorkspace.shared.frontmostApplication,
                let appName = frontApp.localizedName else {
            DispatchQueue.main.async { result(nil) }
            return
          }
          
          let icon = NSWorkspace.shared.icon(forFile: frontApp.bundleURL?.path ?? "")
          icon.size = NSSize(width: 16, height: 16)
          
          guard let cgImage = icon.cgImage(forProposedRect: nil, context: nil, hints: nil),
                let data = CFDataCreateMutable(nil, 0),
                let destination = CGImageDestinationCreateWithData(data, kUTTypePNG, 1, nil) else {
            DispatchQueue.main.async { result(nil) }
            return
          }
          
          CGImageDestinationAddImage(destination, cgImage, nil)
          CGImageDestinationFinalize(destination)
          
          DispatchQueue.main.async {
            result([
              "appName": appName,
              "icon": FlutterStandardTypedData(bytes: Data(referencing: data))
            ])
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
  }
}
