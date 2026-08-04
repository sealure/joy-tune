import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // 设备 ID 通道：Flutter 侧通过此通道获取 iOS 系统稳定的 identifierForVendor
    let channel = FlutterMethodChannel(
      name: "joy_tune/device_id",
      binaryMessenger: engineBridge.applicationBinaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "getSystemDeviceId" {
        if let identifierForVendor = UIDevice.current.identifierForVendor?.uuidString {
          result(identifierForVendor)
        } else {
          result(nil)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
