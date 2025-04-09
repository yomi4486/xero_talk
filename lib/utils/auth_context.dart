import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:livekit_client/livekit_client.dart';

/// アプリ全体の状態管理を担うクラス
class AuthContext extends ChangeNotifier {
  // プライベートコンストラクタ
  AuthContext._privateConstructor();

  // シングルトンインスタンス
  static final AuthContext _instance = AuthContext._privateConstructor();

  // インスタンスを取得するためのファクトリコンストラクタ
  factory AuthContext() {
    return _instance;
  }

  // クラスのプロパティやメソッド
  late String id; // 現在ログインしているユーザーのサービス内でのID
  late WebSocket channel; // サーバーとのWebSocket接続
  late UserCredential userCredential; // Firebaseのログインインスタンス
  late drive.DriveApi googleDriveApi; // GoogleDriveにデータを書き込むためのインスタンス
  late String deviceName; // アプリが動作しているデバイスの機種名を保管
  late Widget lastOpenedChat; // スワイプでチャット画面を行き来した際の状態管理を行う
  bool editing = false; // メッセージが編集中かどうかの状態管理を行う
  late String editingMessageId;
  late Room room;
  bool inHomeScreen = false;
  late String showChatId;
  bool showBottomBar = true;
  List<Color> theme = const [
    Color.fromARGB(204, 228, 169, 114),
    Color.fromARGB(204, 153, 65, 216)
  ];

  /// セッションの復元を行うための関数です
  Future restoreConnection() async {
    await channel.close();
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw "token is undefined.";
    }
    channel = await WebSocket.connect('wss://${dotenv.env['BASE_URL']}/v1',
        headers: {'token': token});
    notifyListeners();
  }

  /// HEXカラーコードをColorオブジェクトに変換します
  Color hexToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  ///背景色に応じてダーク、ホワイトを切り替えてカラーセットを返却します
  List<Color> getTextColor(Color backgroundColor) {
    double brightness = (backgroundColor.red * 0.299 +
            backgroundColor.green * 0.587 +
            backgroundColor.blue * 0.114) /
        255;
    List<Color> textColor = brightness > 0.5
        ? [
            const Color.fromARGB(198, 79, 79, 79),
            const Color.fromARGB(255, 33, 33, 33), // メッセージコンテンツ等の重要な内容
            const Color.fromARGB(255, 55, 55, 55), // 名前など
          ]
        : [
            const Color.fromARGB(198, 176, 176, 176),
            const Color.fromARGB(255, 222, 222, 222), // メッセージコンテンツ等の重要な内容
            const Color.fromARGB(255, 200, 200, 200), // 名前など
          ];
    return textColor;
  }

  /// Firestoreから自分の設定しているテーマを取得します
  Future getTheme() async {
    final themeDoc = await FirebaseFirestore.instance
        .collection('user_account')
        .doc(id)
        .get();
    final data = themeDoc.data();
    if (data != null && data.containsKey("color_theme")) {
      final themeData = data["color_theme"];
      if (theme.isNotEmpty) {
        final oneColor = hexToColor(themeData[0]);
        final twoColor = hexToColor(themeData[1]);
        theme = [oneColor, twoColor];
      }
    }
  }

  Future checkConnection() async {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (channel.readyState != 1) {
        try {
          await restoreConnection();
        } catch (_) {
          return;
        }
      }
    });
  }

  void notify(){
    notifyListeners();
  }

  Future logout() async {
    try {
      inHomeScreen = false;
      final googleSignIn = GoogleSignIn();
      await channel.close();
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }
}
