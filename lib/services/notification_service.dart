import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _channel = MethodChannel('notification_service');
  static const String _badgeCountKey = 'notification_badge_count';

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
    
    // アプリ起動時にバッジ数を復元
    await _restoreBadgeCount();
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
      
      // バッジを0にクリア
      await clearBadge();
      
      debugPrint('All notifications cleared successfully');
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  /// バッジカウントを増加
  static Future<void> incrementBadgeCount() async {
    try {
      // バックグラウンドでも確実にSharedPreferencesを使用できるように初期化
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_badgeCountKey) ?? 0;
      final newCount = currentCount + 1;
      
      // SharedPreferencesに保存
      await prefs.setInt(_badgeCountKey, newCount);
      
      // バッジを更新
      await FlutterAppBadger.updateBadgeCount(newCount);
      
      debugPrint('Badge count incremented to: $newCount');
    } catch (e) {
      debugPrint('Error incrementing badge count: $e');
      // フォールバック：直接バッジを更新を試行
      try {
        await FlutterAppBadger.updateBadgeCount(1);
      } catch (fallbackError) {
        debugPrint('Fallback badge update also failed: $fallbackError');
      }
    }
  }

  /// バッジカウントを減少
  static Future<void> decrementBadgeCount() async {
    try {
      final currentCount = await getBadgeCount();
      final newCount = currentCount > 0 ? currentCount - 1 : 0;
      await setBadgeCount(newCount);
    } catch (e) {
      debugPrint('Error decrementing badge count: $e');
    }
  }

  /// バッジカウントを設定
  static Future<void> setBadgeCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_badgeCountKey, count);
      
      if (count > 0) {
        // Android の場合、一部のランチャーではバッジがサポートされていないため、
        // エラーをキャッチして続行
        try {
          await FlutterAppBadger.updateBadgeCount(count);
        } catch (badgerError) {
          debugPrint('FlutterAppBadger error (may be expected on some Android launchers): $badgerError');
        }
      } else {
        try {
          await FlutterAppBadger.removeBadge();
        } catch (badgerError) {
          debugPrint('FlutterAppBadger remove error (may be expected on some Android launchers): $badgerError');
        }
      }
      
      debugPrint('Badge count set to: $count');
    } catch (e) {
      debugPrint('Error setting badge count: $e');
    }
  }

  /// 現在のバッジカウントを取得
  static Future<int> getBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_badgeCountKey) ?? 0;
    } catch (e) {
      debugPrint('Error getting badge count: $e');
      return 0;
    }
  }

  /// バッジをクリア
  static Future<void> clearBadge() async {
    try {
      await FlutterAppBadger.removeBadge();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_badgeCountKey, 0);
      debugPrint('Badge cleared');
    } catch (e) {
      debugPrint('Error clearing badge: $e');
    }
  }

  /// バックグラウンド用のバッジ増加（初期化処理も含む）
  static Future<void> incrementBadgeCountForBackground() async {
    try {
      // バックグラウンドでも確実に動作するように直接処理
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_badgeCountKey) ?? 0;
      final newCount = currentCount + 1;
      
      await prefs.setInt(_badgeCountKey, newCount);
      
      // バッジ更新を試行（エラーを無視）
      try {
        await FlutterAppBadger.updateBadgeCount(newCount);
        debugPrint('Background badge count updated to: $newCount');
      } catch (badgerError) {
        debugPrint('Background badge update error (may be expected): $badgerError');
      }
    } catch (e) {
      debugPrint('Error in background badge increment: $e');
    }
  }

  /// アプリ起動時にバッジ数を復元
  static Future<void> _restoreBadgeCount() async {
    try {
      final count = await getBadgeCount();
      if (count > 0) {
        await FlutterAppBadger.updateBadgeCount(count);
      }
    } catch (e) {
      debugPrint('Error restoring badge count: $e');
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
