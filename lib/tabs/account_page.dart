import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xero_talk/setting.dart';
import 'dart:convert';
import 'package:xero_talk/utils/user_icon_tools.dart' as uit;
import 'package:image_cropper/image_cropper.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:provider/provider.dart';
import 'package:xero_talk/widgets/user_icon.dart';
import 'package:xero_talk/screens/friends_screen.dart';

class AccountPage extends StatefulWidget {
  AccountPage();
  final Color defaultColor = const Color.fromARGB(255, 22, 22, 22);
  @override
  _AccountPage createState() => _AccountPage();
}

class _AccountPage extends State<AccountPage> {
  _AccountPage();
  bool _showFab = false; // falseなら未編集、trueなら編集済み
  String description = "";
  String displayName = "";
  String userName = "";

  @override
  void dispose() {
    super.dispose();
  }

  Color darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
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
      }
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    final instance = Provider.of<AuthContext>(context);
    return WillPopScope(
      key: GlobalKey(),
      onWillPop: () async => true,
      child: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('user_account') // コレクションID
            .doc('${instance.id}') // ドキュメントID
            .get(),
        builder: (context, snapshot) {
          if (!_showFab) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              displayName = "";
              description = "";
              userName = "";
            } else if (snapshot.hasError) {
              displayName = "";
              description = "";
              userName = "";
            } else if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists && snapshot.data!.data() != null) {
              final res = snapshot.data!.data() as Map<String, dynamic>;
              // successful
              final displayNameValue = res["display_name"];
              displayName = (displayNameValue is String) ? displayNameValue : "-";
              final descriptionValue = res["description"];
              description = (descriptionValue is String) ? descriptionValue : "";
              final nameValue = res["name"];
              userName = (nameValue is String) ? nameValue : "";
            } else {
              displayName = "";
              description = "";
              userName = "";
            }
          }
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: FractionalOffset.topLeft,
                end: FractionalOffset.bottomRight,
                colors: instance.theme,
                stops: const [0.0, 1.0],
              ),
            ),
            child:Scaffold(
            appBar: AppBar(
              centerTitle: false,
              automaticallyImplyLeading: false,
              title: const Text("アカウント",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  )),
              titleTextStyle: const TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255), fontSize: 20),
              backgroundColor: darkenColor(const Color.fromARGB(255, 68, 68, 68),0.2).withOpacity(.1),
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
                      // ドキュメント作成
                      FirebaseFirestore.instance
                          .collection('user_account') // コレクションID
                          .doc('${instance.id}') // ドキュメントID
                          .update({
                        'description': description,
                        'display_name': displayName,
                      }).then((value) {
                        setState(() {
                          _showFab = false;
                        });
                      }).catchError((err) {
                        debugPrint(err);
                      });
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
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
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
                                      await upload('$token');
                                      instance.deleteImageCache(id:instance.id);
                                      setState((){});
                                    },
                                    child:
                                    Stack(children:[
                                    ClipRRect(
                                      // アイコン表示（角丸）
                                      borderRadius:
                                          BorderRadius.circular(1000),
                                      child: UserIcon(userId: instance.id,size:MediaQuery.of(context).size.width * 0.2)
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
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:[
                                  SizedBox(
                                    // ニックネーム設定フォーム
                                    child: Container(
                                      width:MediaQuery.of(context).size.width * 0.6,
                                      margin: const EdgeInsets.only(left: 10),
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: TextEditingController(
                                              text: displayName
                                            ),
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
                                              )
                                            ),
                                            onChanged: (text) {
                                              displayName = text;
                                              if (!_showFab) {
                                                _showFab = true;
                                              }
                                            },
                                            onTapOutside: (f) {
                                              FocusScope.of(context).unfocus();
                                            },
                                          ),      
                                        ]
                                      )
                                    )
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 10,top: 7),
                                    child:Text("@$userName",style: TextStyle(color: Colors.white70),)
                                  )
                                ]
                              )
                            ],
                          ),
                        ]
                      )
                    ),
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
                            _showFab = true;
                          }
                        },
                        onTapOutside: (f) {
                          FocusScope.of(context).unfocus();
                        },),
                  )),
                  GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext context) {
                            return Container(
                              height: MediaQuery.of(context).size.height * 0.9,
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 22, 22, 22),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20.0),
                                  topRight: Radius.circular(20.0),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Color.fromARGB(255, 40, 40, 40),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          onPressed: () => Navigator.pop(context),
                                          icon: const Icon(Icons.close, color: Colors.white),
                                        ),
                                        const Text(
                                          'フレンド',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 40), // バランスを取るための空のスペース
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: FriendsScreen(),
                                  ),
                                ],
                              ),
                            );
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
                                  )))))
                ] //childlen 画面全体
                    )),
          )));
        },
      ),
    );
  }
}
