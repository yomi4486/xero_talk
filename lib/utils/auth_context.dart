import 'dart:io';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  Future restoreConnection() async {
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
    channel = await WebSocket.connect(
      'wss://${dotenv.env['BASE_URL']}:8092/v1',
      headers: {
        'token':token
      }
    );
    bloadCast = channel.asBroadcastStream();
  }
}
