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
    let wallpaperChannel = FlutterMethodChannel(name: "jaybar/wallpaper",
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
    
    wallpaperChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getWallpaperDominantColor" {
        DispatchQueue.global(qos: .userInitiated).async {
          guard let desktopImageURL = NSWorkspace.shared.desktopImageURL(for: NSScreen.main ?? NSScreen.screens[0]),
                let image = NSImage(contentsOf: desktopImageURL) else {
            DispatchQueue.main.async { result(nil) }
            return
          }
          
          let dominantColor = self.getDominantColor(from: image)
          let hexColor = String(format: "#%02X%02X%02X", 
                               Int(dominantColor.redComponent * 255),
                               Int(dominantColor.greenComponent * 255),
                               Int(dominantColor.blueComponent * 255))
          
          DispatchQueue.main.async { result(hexColor) }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
  }
  
  private func getDominantColor(from image: NSImage) -> NSColor {
    guard image.cgImage(forProposedRect: nil, context: nil, hints: nil) != nil else {
      return NSColor(red: 0.77, green: 0.59, blue: 0.85, alpha: 1.0)
    }
    
    // Resize image for faster processing
    let targetSize = CGSize(width: 150, height: 150)
    let scaledImage = NSImage(size: targetSize)
    scaledImage.lockFocus()
    image.draw(in: NSRect(origin: .zero, size: targetSize))
    scaledImage.unlockFocus()
    
    guard let scaledCGImage = scaledImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return NSColor(red: 0.77, green: 0.59, blue: 0.85, alpha: 1.0)
    }
    
    let width = scaledCGImage.width
    let height = scaledCGImage.height
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    
    guard let data = CFDataCreateMutable(nil, width * height * bytesPerPixel),
          let context = CGContext(data: CFDataGetMutableBytePtr(data),
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: bytesPerRow,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
      return NSColor(red: 0.77, green: 0.59, blue: 0.85, alpha: 1.0)
    }
    
    context.draw(scaledCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    
    let pixelData = CFDataGetBytePtr(data)!
    var red: Double = 0, green: Double = 0, blue: Double = 0
    let totalPixels = width * height
    
    for i in 0..<totalPixels {
      let pixelIndex = i * bytesPerPixel
      red += Double(pixelData[pixelIndex])
      green += Double(pixelData[pixelIndex + 1])
      blue += Double(pixelData[pixelIndex + 2])
    }
    
    let avgRed = red / Double(totalPixels * 255)
    let avgGreen = green / Double(totalPixels * 255)
    let avgBlue = blue / Double(totalPixels * 255)
    
    print("Wallpaper dominant color: R=\(avgRed), G=\(avgGreen), B=\(avgBlue)")
    
    return NSColor(red: avgRed, green: avgGreen, blue: avgBlue, alpha: 1.0)
  }
}
