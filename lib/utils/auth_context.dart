import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

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
  late MqttServerClient mqttClient; // MQTTクライアント
  late StreamController<String> mqttStreamController;
  Stream<String> get mqttStream => mqttStreamController.stream;
  late UserCredential userCredential;
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
    Color.fromARGB(255, 228, 169, 114),
    Color.fromARGB(255, 153, 65, 216)
  ];
  StreamSubscription? _connectivitySubscription;

  Future<bool> startSession() async {
    try{// すでに接続中または接続試行中なら何もしない
    if (
        (mqttClient.connectionState == MqttConnectionState.connected ||
         mqttClient.connectionState == MqttConnectionState.connecting)
    ) {
      debugPrint('MQTT is already connecting or connected. Skipping startSession.');
      return mqttClient.connectionState == MqttConnectionState.connected;
    }
    }catch(_){}
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final baseUrl = dotenv.env['BASE_URL']!.replaceAll('wss://', '').replaceAll('https://', '');
    mqttClient = MqttServerClient.withPort("wss://$baseUrl", id,443);
    mqttClient.useWebSocket = true;
    mqttClient.logging(on: false);
    mqttClient.keepAlivePeriod = 20;
    mqttClient.onDisconnected = () {
      debugPrint('MQTT Disconnected');
    };
    mqttClient.onConnected = () {
      debugPrint('MQTT Connected');
    };
    mqttClient.onSubscribed = (String topic) {
      debugPrint('Subscribed to: ' + topic);
    };
    mqttClient.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(id)
        .authenticateAs(token, '')
        .startClean();
    mqttStreamController = StreamController<String>.broadcast();
    try {
      await mqttClient.connect();
      mqttClient.subscribe('response/$id', MqttQos.atMostOnce);
      mqttClient.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final recMess = c[0].payload as MqttPublishMessage;
        final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        mqttStreamController.add(pt);
      });
      await checkConnection();
      return mqttClient.connectionState == MqttConnectionState.connected;
    } catch (e) {
      debugPrint('MQTT connection error: $e');
      return false;
    }
  }

  /// セッションの復元を行うための関数です
  Future restoreConnection() async {
    await startSession();
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
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        debugPrint('Network reconnected: ${results.first}');
        try {
          await restoreConnection();
        } catch (e) {
          debugPrint('Error restoring connection on network change: $e');
        }
      }
    });

    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mqttClient.connectionState != MqttConnectionState.connected) {
        try {
          await restoreConnection();
        } catch (_) {
          return;
        }
      }
    });
  }

  Future logout() async {
    try {
      inHomeScreen = false;
      await _connectivitySubscription?.cancel();
      final googleSignIn = GoogleSignIn();
      mqttClient.disconnect();
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      // HiveからuserIdを削除
      var userInfoBox = await Hive.openBox('userInfo');
      await userInfoBox.delete('userId');
    } catch (_) {}
  }

  Future<void> deleteImageCache({String? id})async{
    if(id != null){
      // imageCache ボックス内のすべてのエントリーを削除
      var box = Hive.box('imageCache');
      await box.clear();
    }else{
      var box = Hive.box('imageCache');
      await box.delete(id);
    }
  }

  Future<void> refreshToken() async {
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signInSilently();
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
    // 必要ならgoogleDriveApiも再生成
  }
}
