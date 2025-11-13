import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:xero_talk/account_startup.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:xero_talk/chat.dart';
import 'package:xero_talk/tabs.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:xero_talk/voice_chat.dart';
import 'utils/voice_chat.dart';
import 'services/notification_service.dart';
import 'services/account_suspension_service.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

late drive.DriveApi googleDriveApi;
bool failed = false;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // バックグラウンドでFirebaseを初期化
  await Firebase.initializeApp();
  
  if(message.data["type"] == "call"){
    showCallkitIncoming(message.data["room_id"],message.data["display_name"]);
  } else {
    // 通話以外の通知の場合はバッジを増加（バックグラウンド専用メソッド使用）
    await NotificationService.incrementBadgeCountForBackground();
  }
  
  // ここでバックグラウンドでの処理（ローカル通知の表示など）
}

Future<void> _initializeAndroidAudioSettings() async {
  await webrtc.WebRTC.initialize(options: {
    'androidAudioConfiguration': webrtc.AndroidAudioConfiguration.media.toMap()
  });
  webrtc.Helper.setAndroidAudioConfiguration(
      webrtc.AndroidAudioConfiguration.media);
}

Future<void> initializeFirebase() async {
  if (kIsWeb) {
    // Web用のFirebase設定
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDsw8W8EGDbk0GodyI06CIMdx115fVxPn8",
        authDomain: "xero-talk.firebaseapp.com",
        projectId: "xero-talk",
        storageBucket: "xero-talk.firebasestorage.app",
        messagingSenderId: "163114823018",
        appId: "1:163114823018:web:0c47a0498a95d903afc913",
        measurementId: "G-X6QHV0BFL1",
        iosClientId: "163114823018-rufpd5iuiglp79b8rgteb35orb238ouu.apps.googleusercontent.com",
      ),
    );
  }else{
    await Firebase.initializeApp();
  }
}

Future<void> showCallkitIncoming(String uuid,String? displayName) async {
  final params = CallKitParams(
    id: uuid,
    nameCaller: displayName ?? "不明な着信",
    appName: 'Callkit',
    avatar: 'https://i.pravatar.cc/100',
    handle: '0123456789',
    type: 0,
    duration: 30000,
    textAccept: 'Accept',
    textDecline: 'Decline',
    missedCallNotification: const NotificationParams(
      showNotification: true,
      isShowCallback: true,
      subtitle: 'Missed call',
      callbackText: 'Call back',
    ),
    extra: <String, dynamic>{'userId': '1a2b3c4d'},
    headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
    android: const AndroidParams(
      isCustomNotification: true,
      isShowLogo: true,
      logoUrl: 'assets/test.png',
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#0955fa',
      backgroundUrl: 'assets/test.png',
      actionColor: '#4CAF50',
      textColor: '#ffffff',
    ),
    ios: const IOSParams(
      iconName: 'CallKitLogo',
      handleType: '',
      supportsVideo: true,
      maximumCallGroups: 2,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: true,
      supportsHolding: true,
      supportsGrouping: false,
      supportsUngrouping: false,
      ringtonePath: 'system_ringtone_default',
    ),
  );
  await FlutterCallkitIncoming.showCallkitIncoming(params);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('imageCache');
  await initializeFirebase();
  await _initializeAndroidAudioSettings();
  await dotenv.load();
  
  // 通知サービスを初期化
  await NotificationService.initialize();
  
  // アプリ起動時に自分のアプリの通知を全て削除
  await NotificationService.clearAllNotifications();
  
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TabsProvider()),
        ChangeNotifierProvider(create:(_) => AuthContext()),
        ChangeNotifierProvider(create: (_) => chatProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Xero Talk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 22, 22, 22)),
        useMaterial3: true,
      ),
      scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
      home: const MyHomePage(),
      navigatorKey: navigatorKey,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage();

  @override
  State<MyHomePage> createState() => _LoginPageState();
}

class _LoginPageState extends State<MyHomePage> with WidgetsBindingObserver  {
  bool failed = false;

  // サインイン成功後の共通処理（Google/Apple 共通）
  Future<void> _handlePostSignIn(UserCredential userCredential, AuthContext authContext, AccountSuspensionService suspensionService) async {
    try {
      // idが取得できなかった場合はHiveから取得
      if (userCredential.additionalUserInfo?.profile?['sub'] == null) {
        var userInfoBox = await Hive.openBox('userInfo');
        authContext.id = userInfoBox.get('userId', defaultValue: userCredential.additionalUserInfo?.profile?['sub'] ?? userCredential.user?.uid);
      } else {
        // idが取得できた場合はHiveに保存
        var userInfoBox = await Hive.openBox('userInfo');
        await userInfoBox.put('userId', userCredential.additionalUserInfo?.profile?['sub']);
        authContext.id = userCredential.additionalUserInfo?.profile?['sub'];
      }
      
      authContext.googleDriveApi = null; // 初期化時はnull
      authContext.userCredential = userCredential;
      await authContext.getTheme();

      // Check if user exists in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('user_account')
          .doc(authContext.id)
          .get();

      final messaging = FirebaseMessaging.instance;
      
      try{
        final fcmToken = await messaging.getToken();

        if (fcmToken != null) {
          await FirebaseFirestore.instance
              .collection('fcm_token')
              .doc(authContext.id)
              .set({"fcm_token": fcmToken}, SetOptions(merge: true));
        } else {
          debugPrint("FCM token is null. Skipping Firestore write operation.");
        }
      }catch(e, stack){ // Rejectされた場合
        debugPrint('Exception: ${e.toString()}');
        debugPrint('Stack trace: $stack');
      }

      debugPrint("ログインしたID: ${authContext.id}");

      // アカウント停止状態をチェック
      try {
        await suspensionService.checkSuspensionOnLogin(authContext.id);
      } catch (e) {
        if (e is AccountSuspendedException) {
          // 停止されている場合、ユーザーに復旧の選択肢を提供
          if (mounted) {
            _showSuspensionDialog(authContext.id, e.message, e.suspensionInfo);
          }
          return;
        } else {
          // その他のエラーは継続
          debugPrint("Suspension check error: $e");
        }
      }

      if (userCredential.additionalUserInfo!.isNewUser || !userDoc.exists) {
        // 新規ユーザーの場合
        bool connected = await authContext.startSession();

        if (connected && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AccountStartup()),
          );
        } else {
          if(mounted){
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('接続エラー'),
                content: Text('サーバーに接続できませんでした。ネットワークやサーバー設定を確認してください。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      } else if (!authContext.inHomeScreen) {
        //既存ユーザーの場合
        bool connected = await authContext.startSession();
        if (connected) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PageViewTabsScreen()),
          );
        } else {
          if(mounted){
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('接続エラー'),
                content: Text('サーバーに接続できませんでした。ネットワークやサーバー設定を確認してください。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }
      authContext.inHomeScreen = true;
      authContext.userCredential = userCredential;
    } catch(e){
      debugPrint("Post sign-in processing error: $e");
      rethrow;
    }
  }

  void signInWithGoogle(bool isExistUser) async {
    try {
      final authContext = AuthContext();
      final suspensionService = AccountSuspensionService();
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceData;

      if (Theme.of(context).platform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceData =
            'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt}), ${androidInfo.model}';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        /// iPhoneの内部名を表示される機種名に変換
        String getIosDeviceName(String machine) {
          Map<String, String> iosDeviceNames = {
            'iPhone13,4': 'iPhone 12 Pro Max',
            'iPhone14,2': 'iPhone 13 Pro',
            'iPhone14,3': 'iPhone 13 Pro Max',
            'iPhone14,4': 'iPhone 13 mini',
            'iPhone14,5': 'iPhone 13',
            'iPhone15,2': 'iPhone 14 Pro',
            'iPhone15,3': 'iPhone 14 Pro Max',
            'iPhone15,4': 'iPhone 14',
            'iPhone15,5': 'iPhone 14 Plus',
            'iPhone16,1': 'iPhone 15 Pro',
            'iPhone16,2': 'iPhone 15 Pro Max',
            'iPhone16,3': 'iPhone 15',
            'iPhone16,4': 'iPhone 15 Plus',
            'iPhone17,1': 'iPhone 16 Pro',
            'iPhone17,2': 'iPhone 16 Pro Max',
            'iPhone17,3': 'iPhone 16',
            'iPhone17,4': 'iPhone 16 Plus',
          };
          return iosDeviceNames[machine] ?? machine;
        }

        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceData =
            '${getIosDeviceName(iosInfo.utsname.machine)}, ${iosInfo.systemName} ${iosInfo.systemVersion}';
      } else {
        deviceData = 'Unsupported platform';
      }
      authContext.deviceName = deviceData;

      //Google認証フローを起動する
      final googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
        ],
      );

      late GoogleSignInAccount? googleUser = googleSignIn.currentUser;
      if (!isExistUser && googleUser == null) {
        googleUser = await googleSignIn.signIn();
      } else {
        googleUser = await googleSignIn.signInSilently();
      }

      if (googleUser == null) {
        throw Exception('Google Sign-In failed');
      }

      //リクエストから認証情報を取得する
      final googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw Exception('Failed to get authentication tokens');
      }

      //firebaseAuthで認証を行う為、credentialを作成
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      //作成したcredentialを元にfirebaseAuthで認証を行う
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      // 共通のサインイン後処理に委譲
      await _handlePostSignIn(userCredential, authContext, suspensionService);
    } catch (e) {
      debugPrint("SignIn Error: $e");
      setState(() {
        failed = true;
      });
    }
  }

  // Apple サインインハンドラ
  void signInWithApple(bool isExistUser) async {
    try {
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Appleサインイン不可'),
              content: const Text('この環境ではAppleサインインが利用できません。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final authContext = AuthContext();
      final suspensionService = AccountSuspensionService();

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (appleCredential.identityToken == null) {
        throw Exception('Apple identity token is null');
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      await _handlePostSignIn(userCredential, authContext, suspensionService);
    } catch (e) {
      debugPrint('Apple SignIn Error: $e');
      if (mounted) {
        setState(() {
          failed = true;
        });
      }
    }
  }

  void _showSuspensionDialog(String userId, String message, Map<String, dynamic>? suspensionInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 40, 40, 40),
          title: const Row(
            children: [
              Icon(Icons.pause_circle, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'アカウント停止中',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'アカウントを復旧しますか？',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // サインアウトしてログイン画面に戻る
                FirebaseAuth.instance.signOut();
                GoogleSignIn().signOut();
              },
              child: const Text(
                'キャンセル',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _reactivateAccount(userId);
              },
              child: const Text(
                '復旧する',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _reactivateAccount(String userId) async {
    try {
      final suspensionService = AccountSuspensionService();
      await suspensionService.reactivateAccount(userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('アカウントが復旧されました。ログインを続行します。'),
            backgroundColor: Colors.green,
          ),
        );
        
        // ログインを再試行
        signInWithGoogle(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('復旧に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  // String? _currentUuid;

  late final FirebaseMessaging _firebaseMessaging;

  @override
  void initState(){
    super.initState();
    initFirebase();
    WidgetsBinding.instance.addObserver(this);
    FlutterCallkitIncoming.requestFullIntentPermission();

    // アプリが開かれた時に通知を削除
    NotificationService.clearAllNotifications();

    FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event != null && event.event == Event.actionCallAccept) {
        final roomId = event.body["id"];
        final token = await getRoom(roomId);
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => VoiceChat(
              RoomInfo(
                token: token,
                displayName: "",
                userId:""
              )
            )
          ),
        );
      }
    });

    //Check call when open app from terminated
    checkAndNavigationCallingPage();
  }

  Future<dynamic> getCurrentCall() async {
    //check current call from pushkit if possible
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List) {
      if (calls.isNotEmpty) {
        print('DATA: $calls');
        // _currentUuid = calls[0]['id'];
        return calls[0];
      } else {
        // _currentUuid = "";
        return null;
      }
    }
  }

  Future<void> checkAndNavigationCallingPage() async {
    var currentCall = await getCurrentCall();
    if (currentCall != null) {
      // NavigationService.instance.pushNamedIfNotCurrent(AppRoute.callingPage, args: currentCall);
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    print("App lifecycle state changed: $state");
    if (state == AppLifecycleState.resumed) {
      //Check call when open app from background
      checkAndNavigationCallingPage();
      
      // アプリがフォアグラウンドに復帰した時に通知とバッジをクリア
      await NotificationService.clearAllNotifications();
    } else if (state == AppLifecycleState.paused) {
      // アプリがバックグラウンドに移行する時の処理
      debugPrint('App moved to background');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> initFirebase() async {
    await Firebase.initializeApp();
    _firebaseMessaging = FirebaseMessaging.instance;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Message title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');
      if(message.data["type"] == "call"){      
        showCallkitIncoming(message.data["room_id"],message.data["display_name"]);
      } else {
        // アプリがフォアグラウンドにある場合は通常バッジを増加させない
        // ただし、ユーザーが他の画面にいる可能性もあるので、必要に応じて増加
        debugPrint('Received foreground notification, not updating badge');
      }

    });
    _firebaseMessaging.getToken().then((token) {
      print('Device Token FCM: $token');
    });
  }

  @override
  Widget build(BuildContext context) {
    final instance = AuthContext();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null&&!failed && !instance.inHomeScreen) {
        signInWithGoogle(true);
      }
    });
    return Scaffold(
      body: DecoratedBox(
          decoration:
              const BoxDecoration(color: Color.fromARGB(255, 22, 22, 22)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset('assets/images/logo.png',
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width * 0.5 > 300 ? 300 : MediaQuery.of(context).size.width * 0.5) ,
                (FirebaseAuth.instance.currentUser == null || failed
                    ? Column(children: [
                        Container(
                          margin: const EdgeInsets.all(10),
                          child: const Text("Xero Talkで話そう､繋がろう!",
                              style: (TextStyle(
                                  color: Color.fromARGB(255, 240, 240, 240),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20))),
                        ),
                        Container(
                          margin: const EdgeInsets.all(16),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 231, 231, 231),
                              foregroundColor: Colors.black,
                              shape: const StadiumBorder(),
                              elevation: 0, // Shadow elevation
                              shadowColor: const Color.fromARGB(
                                  255, 255, 255, 255), // Shadow color
                            ),
                            onPressed: () {
                              try {
                                signInWithGoogle(false);
                              } catch (e) {
                                print(e);
                              }
                            },
                            icon: const ImageIcon(
                              AssetImage("assets/images/google_logo.png"),
                              color: Color.fromARGB(255, 22, 22, 22),
                            ),
                            label: const Text('Googleでログイン',
                                style: (TextStyle(
                                    color: Color.fromARGB(255, 22, 22, 22),
                                    fontSize: 16))),
                          ),
                        ),
                        // Show Apple Sign In button only on native Apple platforms (iOS/macOS) and not on web
                        if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS))
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 231, 231, 231),
                                foregroundColor: Colors.black,
                                shape: const StadiumBorder(),
                                elevation: 0,
                                shadowColor: const Color.fromARGB(255, 255, 255, 255),
                              ),
                              onPressed: () {
                                signInWithApple(false);
                              },
                              icon: const ImageIcon(
                                AssetImage("assets/images/apple_logo.png"),
                                color: Color.fromARGB(255, 22, 22, 22),
                              ),
                              label: const Text('Appleでログイン',
                                  style: (TextStyle(
                                      color: Color.fromARGB(255, 22, 22, 22),
                                      fontSize: 16))),
                            ),
                          ),
                      ])
                    : Container()
                )
              ],
            ),
          )),
    );
  }
}
