import Cocoa
import FlutterMacOS
import GoogleSignIn

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // 处理 Google Sign-In 的 URL 回调
  override func application(_ application: NSApplication,
                            open urls: [URL]) {
    for url in urls {
      if GIDSignIn.sharedInstance.handle(url) {
        return
      }
    }
  }
}
