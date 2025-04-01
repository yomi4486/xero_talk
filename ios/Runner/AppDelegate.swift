import UIKit
import Flutter
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // オーディオセッションを設定
    let audioSession = AVAudioSession.sharedInstance()
    do {
        try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true)
    } catch {
        print("Audio session setup failed: \(error)")
    }
    
    // リモートコントロールイベントの受信を開始
    application.beginReceivingRemoteControlEvents()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
