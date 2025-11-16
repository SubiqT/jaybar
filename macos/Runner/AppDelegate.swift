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
  }
}
