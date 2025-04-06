import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:xero_talk/home.dart';
import 'package:xero_talk/notify.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xero_talk/setting.dart';
import 'dart:convert';
import 'package:xero_talk/utils/user_icon_tools.dart' as uit;
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  AccountPage();
  final Color defaultColor = const Color.fromARGB(255, 22, 22, 22);
  @override
  _AccountPage createState() => _AccountPage();
}

class _AccountPage extends State<AccountPage> {
  _AccountPage();
  bool _showFab = false; // falseなら未編集、trueなら編集済み
  var description = "";
  var displayName = "";

  @override
  void dispose() {
    super.dispose();
  }

  final nowDt = DateTime.now().millisecondsSinceEpoch;

  Future upload(String token) async {
    // 画像をスマホのギャラリーから取得
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);

    // 画像を取得できた場合はクロップする
    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          compressFormat: ImageCompressFormat.png,
          maxHeight: 512,
          maxWidth: 512,
          compressQuality: 0,
          aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0) // 正方形
          );

      if (croppedFile != null) {
        final bytesData = await croppedFile.readAsBytes();
        final base64Data = base64Encode(bytesData);
        await uit.upload(token, base64Data);
        setState(() {});
      }
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    final instance = Provider.of<AuthContext>(context);
    var profile = instance.userCredential.additionalUserInfo?.profile;
    return WillPopScope(
      onWillPop: () async => true,
      child: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('user_account') // コレクションID
            .doc('${profile?["sub"]}') // ドキュメントID
            .get(),
        builder: (context, snapshot) {
          if (!_showFab) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              displayName = "";
            } else if (snapshot.hasError) {
              displayName = "";
            } else if (snapshot.hasData) {
              // successful
              displayName = (snapshot.data?.data()
                      as Map<String, dynamic>)["display_name"] ??
                  "-";
              description = (snapshot.data?.data()
                      as Map<String, dynamic>)["description"] ??
                  "";
            } else {
              displayName = "";
            }
          }
          return Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              enableFeedback: false,
              currentIndex: 2,
              onTap: (value) {
                if (value == 0) {
                  Navigator.push(
                      context,
                      PageRouteBuilder(
                          pageBuilder: (_, __, ___) => chatHome(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          }));
                } else if (value == 1) {
                  Navigator.push(
                      context,
                      PageRouteBuilder(
                          pageBuilder: (_, __, ___) => NotifyPage(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          }));
                }
              },
              unselectedLabelStyle:
                  const TextStyle(color: Color.fromARGB(255, 200, 200, 200)),
              unselectedItemColor: const Color.fromARGB(255, 200, 200, 200),
              selectedLabelStyle: TextStyle(color: instance.theme[1]),
              selectedItemColor: instance.theme[1],
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'ホーム',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications),
                  label: '通知',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.person,
                  ),
                  label: 'アカウント',
                ),
              ],
              backgroundColor: const Color.fromARGB(255, 40, 40, 40),
            ),
            appBar: AppBar(
              centerTitle: false,
              automaticallyImplyLeading: false,
              title: const Text("アカウント",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  )),
              titleTextStyle: const TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255), fontSize: 20),
              backgroundColor: const Color.fromARGB(255, 40, 40, 40),
              actions: [
                Container(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    // アイコン表示（角丸）
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                        color: const Color.fromARGB(0, 255, 255, 255),
                        child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SettingPage()),
                              );
                            },
                            icon: const Icon(Icons.settings,
                                color: Color.fromARGB(128, 255, 255, 255)))),
                  ),
                ),
              ],
            ),
            floatingActionButton: _showFab
                ? FloatingActionButton(
                    onPressed: () async {
                      if (_showFab) {
                        // ドキュメント作成
                        FirebaseFirestore.instance
                            .collection('user_account') // コレクションID
                            .doc('${profile?["sub"]}') // ドキュメントID
                            .update({
                          'description': description,
                          'display_name': displayName,
                        }).then((value) {
                          setState(() {
                            _showFab = false;
                          });
                        }).catchError((err) {
                          print(err);
                        });
                      }
                    },
                    backgroundColor: instance.theme[1],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(128),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color.fromARGB(200, 255, 255, 255),
                    ),
                  )
                : null,
            backgroundColor: widget.defaultColor,
            body: SafeArea(
              child: DecoratedBox(
                  decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 22, 22, 22)),
                  child: Column(children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Container(
                          margin: const EdgeInsets.all(30),
                          child: Column(children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        String? token = await FirebaseAuth
                                            .instance.currentUser
                                            ?.getIdToken();
                                        upload('$token');
                                      },
                                      child:
                                      Stack(children:[
                                      ClipRRect(
                                        // アイコン表示（角丸）
                                        borderRadius:
                                            BorderRadius.circular(2000000),
                                        child: Image.network(
                                          "https://${dotenv.env['BASE_URL']}/geticon?user_id=${profile?['sub']}&t=$nowDt",
                                          width:
                                              MediaQuery.of(context).size.width *
                                                  0.2,
                                          loadingBuilder: (BuildContext context,
                                              Widget child,
                                              ImageChunkEvent? loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            } else {
                                              return Image.asset(
                                                'assets/images/default_user_icon.png',
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.2,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Material(
                                        color:Colors.black,
                                        elevation:4,
                                        shape: CircleBorder(),
                                        child:Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color.fromARGB(255, 222, 222, 222),
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              color: Color.fromARGB(255, 0, 0, 0),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                    // ニックネーム設定フォーム
                                    child: Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.6,
                                        margin: const EdgeInsets.only(left: 10),
                                        child: Column(children: [
                                          TextField(
                                              controller: TextEditingController(
                                                  text: displayName),
                                              style: const TextStyle(
                                                color: Color.fromARGB(
                                                    255, 255, 255, 255),
                                                fontSize: 16,
                                              ),
                                              decoration: const InputDecoration(
                                                  hintText: 'ニックネーム',
                                                  labelStyle: TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 255, 255, 255),
                                                    fontSize: 16,
                                                  ),
                                                  hintStyle: TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 255, 255, 255),
                                                    fontSize: 16,
                                                  )),
                                              onChanged: (text) {
                                                displayName = text;
                                                if (!_showFab) {
                                                  setState(() {
                                                    _showFab = true;
                                                  });
                                                }
                                              },
                                              onTapOutside: (f) {
                                                FocusScope.of(context)
                                                    .unfocus();
                                              }),
                                        ]))),
                              ],
                            ),
                          ])),
                    ),
                    SizedBox(
                        child: Container(
                      margin: const EdgeInsets.only(left: 30, right: 30),
                      child: TextField(
                          controller: TextEditingController(text: description),
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '',
                            labelText: '自己紹介',
                            labelStyle: TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                              fontSize: 16,
                            ),
                            hintStyle: TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: Color.fromARGB(16, 255, 255, 255),
                          ),
                          onChanged: (text) {
                            description = text;
                            if (!_showFab) {
                              setState(() {
                                _showFab = true;
                              });
                            }
                          },
                          onTapOutside: (f) {
                            FocusScope.of(context).unfocus();
                          }),
                    )),
                    GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            scrollControlDisabledMaxHeightRatio: 1,
                            context: context,
                            builder: (BuildContext context) {
                              return Container(
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20.0),
                                      topRight: Radius.circular(20.0),
                                    ),
                                  ),
                                  height:
                                      MediaQuery.of(context).size.height * 0.9,
                                  child: Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Column(children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 5),
                                                child: IconButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    icon: const Icon(
                                                        Icons.close))),
                                            const Padding(
                                                padding:
                                                    EdgeInsets.only(right: 20),
                                                child: Icon(Icons.person_add))
                                          ],
                                        ),
                                      ])));
                            },
                          );
                        },
                        child: Container(
                            margin: const EdgeInsets.all(30),
                            child: GestureDetector(
                                child: Container(
                                    decoration: const BoxDecoration(
                                        color: Color.fromARGB(
                                          16,
                                          255,
                                          255,
                                          255,
                                        ),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    padding: const EdgeInsets.only(
                                        left: 14, right: 14,top:12,bottom:12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("フレンド",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            )),
                                        Icon(
                                          Icons.arrow_forward,
                                          color: Colors.white.withOpacity(.5),
                                        )
                                      ],
                                    ))))),
                  ] //childlen 画面全体
                      )),
            ),
          );
        },
      ),
    );
  }
}
