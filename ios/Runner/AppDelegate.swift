import UIKit
import Flutter
import CallKit
import MetricKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var callKitProvider: CXProvider?
  private var callController: CXCallController?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // MetricKitの設定
    setupMetricKit()
    
    // CallKitの初期化を遅延実行
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      self.setupCallKit()
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupMetricKit() {
    if #available(iOS 13.0, *) {
      // MetricKitのデリゲートを設定
      MXMetricManager.shared.add(self)
    }
  }
  
  private func setupCallKit() {
    // 既存のCallKitインスタンスをクリーンアップ
    cleanupCallKit()
    
    // iOS 14.0未満でも安全に動作するように条件分岐
    do {
      if #available(iOS 14.0, *) {
        // iOS 14.0以降の場合
        let configuration = CXProviderConfiguration()
        configuration.supportsVideo = true
        configuration.maximumCallGroups = 2
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.generic]
        
        callKitProvider = CXProvider(configuration: configuration)
        callController = CXCallController()
      } else {
        // iOS 14.0未満の場合
        let configuration = CXProviderConfiguration(localizedName: "Xero Talk")
        configuration.supportsVideo = true
        configuration.maximumCallGroups = 2
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.generic]
        
        callKitProvider = CXProvider(configuration: configuration)
        callController = CXCallController()
      }
      print("CallKit initialized successfully")
    } catch {
      print("Error initializing CallKit: \(error)")
    }
  }
  
  private func cleanupCallKit() {
    // 既存のCallKitインスタンスを適切にクリーンアップ
    callKitProvider?.invalidate()
    callKitProvider = nil
    callController = nil
  }
  
  // CallKit関連のライフサイクル管理
  override func applicationWillTerminate(_ application: UIApplication) {
    // CallKitのクリーンアップ
    cleanupCallKit()
    super.applicationWillTerminate(application)
  }
  
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    // アプリがアクティブになったときにCallKitを再初期化
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.setupCallKit()
    }
  }
  
  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
    // アプリが非アクティブになったときにCallKitをクリーンアップ
    cleanupCallKit()
  }
}

// MARK: - MetricKit Delegate
@available(iOS 13.0, *)
extension AppDelegate: MXMetricManagerSubscriber {
  func didReceive(_ payloads: [MXMetricPayload]) {
    // MetricKitのデータを受信したときの処理
    for payload in payloads {
      print("MetricKit payload received: \(payload)")
    }
  }
  
  @available(iOS 14.0, *)
  func didReceive(_ payloads: [MXDiagnosticPayload]) {
    // 診断データを受信したときの処理（iOS 14.0以降のみ）
    for payload in payloads {
      print("Diagnostic payload received: \(payload)")
    }
  }
}
