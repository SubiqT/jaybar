import Cocoa
import FlutterMacOS

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
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    appIconChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getFocusedAppIcon" {
        DispatchQueue.global(qos: .userInitiated).async {
          guard let frontApp = NSWorkspace.shared.frontmostApplication,
                let bundleID = frontApp.bundleIdentifier else {
            DispatchQueue.main.async { result(nil) }
            return
          }
          
          // Use smaller icon size for faster loading
          let icon = NSWorkspace.shared.icon(forFile: frontApp.bundleURL?.path ?? "")
          icon.size = NSSize(width: 32, height: 32)
          
          guard let tiffData = icon.tiffRepresentation,
                let bitmap = NSBitmapImageRep(data: tiffData),
                let pngData = bitmap.representation(using: .png, properties: [:]) else {
            DispatchQueue.main.async { result(nil) }
            return
          }
          
          DispatchQueue.main.async {
            result(FlutterStandardTypedData(bytes: pngData))
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
  }
}
