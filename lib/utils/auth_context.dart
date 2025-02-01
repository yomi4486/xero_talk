import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
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
  late String deviceName;
  List<Color> theme = const [ Color.fromARGB(204, 228, 169, 114),Color.fromARGB(204, 153, 65, 216)];

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

  Color hexToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  Future getTheme() async {
    final themeDoc = await FirebaseFirestore.instance
      .collection('user_account') // コレクションID
      .doc(id) // ドキュメントID
      .get();
    final data = themeDoc.data();
    if (data != null && data.containsKey("color_theme")) {
      final themeData = data["color_theme"];
      if (theme.isNotEmpty) {
        final oneColor = hexToColor(themeData[0]);
        final twoColor = hexToColor(themeData[1]);
        theme = [oneColor,twoColor];
      }
    }
  }
}
