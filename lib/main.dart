import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:xero_talk/account_startup.dart';
import 'package:xero_talk/home.dart';
import 'dart:io';
import 'dart:async';
class MyHttpOverrides extends HttpOverrides{ // これがないとWSS通信ができない
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Xero Talk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 22, 22, 22)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Xero Talk'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _LoginPageState();
}

class _LoginPageState extends State<MyHomePage> {
  Future<WebSocket> getSession() async{
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final WebSocket channel = await WebSocket.connect(
      'wss://localhost:8000/v1?token=$token'
    );
    return channel;
  }
  void signInWithGoogle() async {
    try {
      //Google認証フローを起動する
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      //リクエストから認証情報を取得する
      final googleAuth = await googleUser?.authentication;
      //firebaseAuthで認証を行う為、credentialを作成
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      //作成したcredentialを元にfirebaseAuthで認証を行う
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      WebSocket channel = await getSession();
      if (userCredential.additionalUserInfo!.isNewUser) { // 新規ユーザーの場合
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AccountStartup(userCredential:userCredential,channel: channel,bloadCast:channel.asBroadcastStream())),
        );
      } else { //既存ユーザーの場合
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => chatHome(userCredential: userCredential,channel:channel,bloadCast:channel.asBroadcastStream())),
        );
      }
    } on FirebaseException catch (e) {
      print(e.message);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color.fromARGB(255, 22, 22, 22)),
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child:SizedBox(
          
          width:MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[

              Image.asset('assets/images/logo.png', fit: BoxFit.contain,width:MediaQuery.of(context).size.width *0.5),
              Container(
                margin: const EdgeInsets.all(10),
                child: const Text("Xero Talkで話そう､繋がろう!",
                  style:(
                    TextStyle(
                      color: Color.fromARGB(255, 240, 240, 240),
                      fontWeight: FontWeight.bold,
                      fontSize: 20
                    )
                  )
                ),
              ),

              Container(
                margin: const EdgeInsets.all(16),
                child:ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 231, 231, 231),
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                    elevation: 0, // Shadow elevation
                    shadowColor: const Color.fromARGB(255, 255, 255, 255), // Shadow color
                  ),
                  onPressed: () {
                    try{
                      signInWithGoogle();
                    }catch(e){
                      print(e);
                    }
                  },
                  icon: const ImageIcon(
                    AssetImage("assets/images/google_logo.png"),
                    color: Color.fromARGB(255, 22, 22, 22),
                  ),
                  label: const Text(
                    'Googleでログイン',
                    style:(
                      TextStyle(
                        color: Color.fromARGB(255, 22, 22, 22),
                        fontSize: 16
                      )
                    )
                  ),
                ),
              ) 
            ],
          ),
        )
      ),
    );
  }
}
