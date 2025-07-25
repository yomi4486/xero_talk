import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _channel = MethodChannel('notification_service');

  /// 通知プラグインの初期化
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(initializationSettings);
  }

  /// 自分のアプリが発行した全ての通知を削除
  static Future<void> clearAllNotifications() async {
    try {
      // Flutter Local Notificationsによる通知を削除
      await _notifications.cancelAll();
      
      // Android固有の通知削除
      if (Platform.isAndroid) {
        await _clearAndroidNotifications();
      }
      
      debugPrint('All notifications cleared successfully');
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  /// 特定のIDの通知を削除
  static Future<void> clearNotification(int id) async {
    try {
      await _notifications.cancel(id);
      debugPrint('Notification with ID $id cleared');
    } catch (e) {
      debugPrint('Error clearing notification $id: $e');
    }
  }

  /// Androidのネイティブ通知を削除
  static Future<void> _clearAndroidNotifications() async {
    try {
      await _channel.invokeMethod('clearAllNotifications');
      debugPrint('Android native notifications cleared');
    } on PlatformException catch (e) {
      debugPrint("Failed to clear Android notifications: '${e.message}'");
    }
  }

  /// アクティブな通知の一覧を取得（Android）
  static Future<List<ActiveNotification>> getActiveNotifications() async {
    if (Platform.isAndroid) {
      try {
        final List<ActiveNotification>? activeNotifications = 
            await _notifications.getActiveNotifications();
        return activeNotifications ?? [];
      } catch (e) {
        debugPrint('Error getting active notifications: $e');
        return [];
      }
    }
    return [];
  }

  /// ペンディング通知の一覧を取得
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }

  /// 通知の詳細情報を取得
  static Future<NotificationAppLaunchDetails?> getNotificationLaunchDetails() async {
    try {
      return await _notifications.getNotificationAppLaunchDetails();
    } catch (e) {
      debugPrint('Error getting notification launch details: $e');
      return null;
    }
  }
}
