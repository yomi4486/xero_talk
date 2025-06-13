import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:xero_talk/account_startup.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:xero_talk/chat.dart';
import 'package:xero_talk/tabs.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

late drive.DriveApi googleDriveApi;
bool failed = false;

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
    // iOS用のFirebase設定（既存のGoogleService-Info.plistを使用）
    await Firebase.initializeApp();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('imageCache');
  await initializeFirebase();
  await _initializeAndroidAudioSettings();
  await dotenv.load();
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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage();

  @override
  State<MyHomePage> createState() => _LoginPageState();
}

class _LoginPageState extends State<MyHomePage> {
  void signInWithGoogle(bool isExistUser) async {
    try {
      final authContext = AuthContext();
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
          drive.DriveApi.driveAppdataScope,
          'email',
          'profile',
        ],
        clientId: kIsWeb 
          ? "163114823018-qr93qqaflbhptq2eogas8ffhrlqnvaut.apps.googleusercontent.com" 
          : "163114823018-rufpd5iuiglp79b8rgteb35orb238ouu.apps.googleusercontent.com"
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
      final httpClient = (await googleSignIn.authenticatedClient())!;
      googleDriveApi = drive.DriveApi(httpClient);
      authContext.id = await userCredential.additionalUserInfo?.profile?['sub'];
      
      authContext.googleDriveApi = googleDriveApi;
      authContext.userCredential = userCredential;
      await authContext.getTheme();
      if (userCredential.additionalUserInfo!.isNewUser) {
        // 新規ユーザーの場合
        await authContext.startSession();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AccountStartup()),
        );
      } else if (!authContext.inHomeScreen) {
        //既存ユーザーの場合
        await authContext.startSession();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PageViewTabsScreen()),
        );
      }
      authContext.inHomeScreen = true;
      authContext.userCredential = userCredential;
    } catch (e) {
      print(e);
      setState(() {
        failed = true;
      });
    }
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
                    width: MediaQuery.of(context).size.width * 0.5),
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
                      ])
                    : Container())
              ],
            ),
          )),
    );
  }
}
