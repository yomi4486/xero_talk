import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AccountSuspensionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ユーザーアカウントを一時停止する
  /// 注意: Firebase Authenticationのユーザー無効化はAdmin SDKでのみ可能なため、
  /// クライアント側では代替手段を使用します
  Future<void> suspendAccount(String userId, String reason) async {
    print('AccountSuspensionService: Suspending account for userId: $userId');
    
    try {
      // Firestoreでユーザーアカウントを無効化状態にマーク
      await _firestore.collection('user_account').doc(userId).update({
        'is_suspended': true,
        'suspension_reason': reason,
        'suspended_at': FieldValue.serverTimestamp(),
        'suspended_by': 'user', // ユーザー自身による停止
      });

      // FCMトークンを削除して通知を停止
      await _firestore.collection('fcm_token').doc(userId).delete();

      // Google Sign-Inからサインアウト
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      // Firebase Authからサインアウト
      await _auth.signOut();

      print('AccountSuspensionService: Account suspended successfully');
      
    } catch (e) {
      print('AccountSuspensionService: Error suspending account: $e');
      throw Exception('アカウント停止中にエラーが発生しました: ${e.toString()}');
    }
  }

  /// アカウントの停止を解除する
  Future<void> reactivateAccount(String userId) async {
    print('AccountSuspensionService: Reactivating account for userId: $userId');
    
    try {
      // Firestoreでユーザーアカウントの停止状態を解除
      await _firestore.collection('user_account').doc(userId).update({
        'is_suspended': false,
        'suspension_reason': FieldValue.delete(),
        'suspended_at': FieldValue.delete(),
        'suspended_by': FieldValue.delete(),
        'reactivated_at': FieldValue.serverTimestamp(),
      });

      print('AccountSuspensionService: Account reactivated successfully');
      
    } catch (e) {
      print('AccountSuspensionService: Error reactivating account: $e');
      throw Exception('アカウント復旧中にエラーが発生しました: ${e.toString()}');
    }
  }

  /// ユーザーが停止状態かどうかを確認
  Future<bool> isAccountSuspended(String userId) async {
    try {
      final doc = await _firestore.collection('user_account').doc(userId).get();
      
      if (!doc.exists) {
        return false;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      return data['is_suspended'] == true;
      
    } catch (e) {
      print('AccountSuspensionService: Error checking suspension status: $e');
      return false;
    }
  }

  /// 停止理由とタイムスタンプを取得
  Future<Map<String, dynamic>?> getSuspensionInfo(String userId) async {
    try {
      final doc = await _firestore.collection('user_account').doc(userId).get();
      
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      
      if (data['is_suspended'] != true) {
        return null;
      }
      
      return {
        'reason': data['suspension_reason'] ?? '理由なし',
        'suspended_at': data['suspended_at'],
        'suspended_by': data['suspended_by'] ?? 'unknown',
      };
      
    } catch (e) {
      print('AccountSuspensionService: Error getting suspension info: $e');
      return null;
    }
  }

  /// ログイン時に停止状態をチェックし、停止中なら例外を投げる
  Future<void> checkSuspensionOnLogin(String userId) async {
    final isSuspended = await isAccountSuspended(userId);
    
    if (isSuspended) {
      final suspensionInfo = await getSuspensionInfo(userId);
      
      String message = 'このアカウントは一時停止中です。';
      if (suspensionInfo != null) {
        message += '\n理由: ${suspensionInfo['reason']}';
        
        if (suspensionInfo['suspended_at'] != null) {
          final suspendedAt = (suspensionInfo['suspended_at'] as Timestamp).toDate();
          message += '\n停止日時: ${_formatDate(suspendedAt)}';
        }
      }
      
      throw AccountSuspendedException(message, suspensionInfo);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// アカウント停止例外クラス
class AccountSuspendedException implements Exception {
  final String message;
  final Map<String, dynamic>? suspensionInfo;

  AccountSuspendedException(this.message, this.suspensionInfo);

  @override
  String toString() => message;
}
