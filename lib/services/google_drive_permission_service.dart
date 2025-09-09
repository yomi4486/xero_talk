import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:xero_talk/utils/auth_context.dart';

class GoogleDrivePermissionService {
  static const String driveScope = 'https://www.googleapis.com/auth/drive.appdata';

  /// GoogleDriveのスコープを要求し、DriveAPIを初期化する
  static Future<bool> requestDrivePermissionAndInitialize(BuildContext context) async {
    try {
      final googleSignIn = GoogleSignIn(scopes: [driveScope]);
      GoogleSignInAccount? currentUser = googleSignIn.currentUser;

      // 未ログインなら確認ダイアログを表示
      if (currentUser == null) {
        final result = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Google Drive権限の追加'),
            content: const Text('Google Driveに保存するには、Googleアカウントへの追加の権限が必要です。続行しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (result != true) {
          return false;
        }
        currentUser = await googleSignIn.signIn();
        if (currentUser == null) {
          // ユーザーがログインしなかった場合
          return false;
        }
      }

      // 既に権限があるか確認
      if (await _hasRequiredScope(currentUser)) {
        await _initializeDriveApi(googleSignIn);
        return true;
      }

      // 追加のスコープを要求
      final bool hasPermission = await googleSignIn.requestScopes([driveScope]);
      if (!hasPermission) {
        return false; // ユーザーが権限を拒否
      }

      await _initializeDriveApi(googleSignIn);
      return true;
    } catch (e) {
      print('GoogleDrivePermissionService: Error requesting permission: $e');
      return false;
    }
  }

  /// 必要なスコープが既に付与されているかチェック
  static Future<bool> _hasRequiredScope(GoogleSignInAccount user) async {
    try {
      final googleSignIn = GoogleSignIn();
      // authenticatedClientを取得できるかテスト
      final httpClient = await googleSignIn.authenticatedClient();
      if (httpClient == null) {
        return false;
      }

      // DriveAPIのテストリクエストを実行
      final driveApi = drive.DriveApi(httpClient);
      await driveApi.files.list(spaces: 'appDataFolder', pageSize: 1);
      return true;
    } catch (e) {
      print('GoogleDrivePermissionService: Scope check failed: $e');
      return false;
    }
  }

  /// DriveAPIを初期化してAuthContextに設定
  static Future<void> _initializeDriveApi(GoogleSignIn googleSignIn) async {
    final httpClient = await googleSignIn.authenticatedClient();
    if (httpClient == null) {
      throw Exception('認証クライアントの取得に失敗しました');
    }

    final driveApi = drive.DriveApi(httpClient);
    final authContext = AuthContext();
    authContext.googleDriveApi = driveApi;
    
    print('GoogleDrivePermissionService: DriveAPI initialized successfully');
  }

  /// 現在GoogleDriveの権限があるかチェック
  static Future<bool> hasDrivePermission() async {
    try {
      final googleSignIn = GoogleSignIn();
      final currentUser = googleSignIn.currentUser;
      
      if (currentUser == null) {
        return false;
      }

      return await _hasRequiredScope(currentUser);
    } catch (e) {
      print('GoogleDrivePermissionService: Permission check failed: $e');
      return false;
    }
  }

  /// GoogleDriveの権限を取り消す（完全な取り消しはできないため、AuthContextから削除のみ）
  static void revokeDrivePermission() {
    final authContext = AuthContext();
    authContext.googleDriveApi = null;
    print('GoogleDrivePermissionService: DriveAPI removed from AuthContext');
  }
}
