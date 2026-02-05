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
    // 設定 MethodChannel 來接收 Flutter 傳來的 API Key
    let controller = window?.rootViewController as! FlutterViewController
    let googleMapsChannel = FlutterMethodChannel(
      name: "com.example.dinosaur/google_maps",
      binaryMessenger: controller.binaryMessenger
    )
    
    googleMapsChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "setApiKey" {
        if let args = call.arguments as? [String: Any],
           let apiKey = args["apiKey"] as? String {
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
    
    // 如果 Flutter 還沒傳 API key，先從 Info.plist 讀取（向後兼容）
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMS_API_KEY") as? String {
      self.googleMapsApiKey = apiKey
      GMSServices.provideAPIKey(apiKey)
    }
    // 注意：如果 Flutter 通過 MethodChannel 設置了 API key，會覆蓋 Info.plist 的值
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
