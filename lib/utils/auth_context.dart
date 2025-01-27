import 'dart:io';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class AuthContext {
  // プライベートコンストラクタ
  AuthContext._privateConstructor();

  // シングルトンインスタンス
  static final AuthContext _instance = AuthContext._privateConstructor();

  // インスタンスを取得するためのファクトリコンストラクタ
  factory AuthContext() {
    return _instance;
  }

  // クラスのプロパティやメソッド
  late String id;
  late WebSocket channel;
  late UserCredential userCredential;
  late Stream<dynamic> bloadCast;
  late drive.DriveApi googleDriveApi;
}
