import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var googleMapsApiKey: String?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 設定 MethodChannel 來接收 Flutter 傳來的 API Key（需安全處理：UIScene 下 rootViewController 可能尚未就緒）
    if let controller = window?.rootViewController as? FlutterViewController {
      let googleMapsChannel = FlutterMethodChannel(
        name: "com.example.dinosaur/google_maps",
        binaryMessenger: controller.binaryMessenger
      )
      googleMapsChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "setApiKey" {
          if let args = call.arguments as? [String: Any],
             let apiKey = args["apiKey"] as? String, !apiKey.isEmpty {
            self?.googleMapsApiKey = apiKey
            GMSServices.provideAPIKey(apiKey)
            result(true)
          } else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "API key is required", details: nil))
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    // 若尚未有 controller，仍可先用 Info.plist 的 key 初始化 Google Maps SDK，避免地圖載入時崩潰
    if googleMapsApiKey == nil, let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMS_API_KEY") as? String, !apiKey.isEmpty {
      googleMapsApiKey = apiKey
      GMSServices.provideAPIKey(apiKey)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
