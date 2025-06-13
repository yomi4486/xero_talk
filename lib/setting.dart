import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xero_talk/main.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:xero_talk/widgets/setting_item.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SettingPage extends StatefulWidget {
  SettingPage();
  final Color defaultColor = const Color.fromARGB(255, 22, 22, 22);
  @override
  _SettingPage createState() => _SettingPage();
}

class _SettingPage extends State<SettingPage> {
  _SettingPage();
  bool _showFab = false; // falseなら未編集、trueなら編集済み
  final AuthContext instance = AuthContext();
  late List<dynamic> theme;

  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).toUpperCase().padLeft(8, '0')}';
  }

  Color hexToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  bool init = false;
  late Color oneColor;
  late Color twoColor;
  @override
  Widget build(BuildContext context) {
    if (!init) {
      init = true;
      oneColor = instance.theme[0];
      twoColor = instance.theme[1];
    }
    var profile = instance.userCredential.additionalUserInfo?.profile;
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('user_account') // コレクションID
          .doc('${profile?["sub"]}') // ドキュメントID
          .get(),
      builder: (context, snapshot) {
        if (!_showFab) {
          if (snapshot.connectionState == ConnectionState.waiting) {
          } else if (snapshot.hasError) {
          } else if (snapshot.hasData) {
            // successful
            final data = snapshot.data?.data();
            if (data != null && data.containsKey("color_theme")) {
              theme = data["color_theme"];
              if (theme.isNotEmpty) {
                oneColor = hexToColor(theme[0]);
                twoColor = hexToColor(theme[1]);
              }
            }
          } else {}
        }
        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            automaticallyImplyLeading: false,
            title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const Text("設定",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      )),
                ]),
            titleTextStyle: const TextStyle(
                color: Color.fromARGB(255, 255, 255, 255), fontSize: 20),
            backgroundColor: const Color.fromARGB(255, 40, 40, 40),
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
                        'color_theme': [
                          colorToHex(oneColor),
                          colorToHex(twoColor)
                        ]
                      }).then((value) {
                        setState(() {
                          _showFab = false;
                          instance.theme = [oneColor, twoColor];
                        });
                      }).catchError((err) {
                        print(err);
                      });
                    }
                  },
                  backgroundColor: const Color.fromARGB(255, 140, 206, 74),
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
                decoration: BoxDecoration(color: widget.defaultColor),
                child: ListView(children: [
                  TitleBar(
                    name: "基本設定",
                  ),
                  SettingItem(
                      name: "テーマ",
                      defaultValue: "",
                      widget: Row(spacing: 10, children: [
                        GestureDetector(
                          // theme[0]
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: oneColor,
                                border: Border.all(
                                    color: const Color.fromARGB(
                                        255, 255, 255, 255),
                                    width: 2)),
                            width: 30,
                            height: 30,
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('色を選択してください'),
                                  content: SingleChildScrollView(
                                    child: ColorPicker(
                                      pickerColor: oneColor,
                                      onColorChanged: (Color color) {
                                        setState(() {
                                          oneColor = color;
                                          _showFab = true;
                                        });
                                      },
                                    ),
                                  ),
                                  actions: <Widget>[
                                    IconButton(
                                      icon: const Icon(Icons.check),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        GestureDetector(
                            // theme[1]
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: twoColor,
                                  border: Border.all(
                                      color: const Color.fromARGB(
                                          255, 255, 255, 255),
                                      width: 2)),
                              width: 30,
                              height: 30,
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('色を選択してください'),
                                    content: SingleChildScrollView(
                                      child: ColorPicker(
                                        pickerColor: twoColor,
                                        onColorChanged: (Color color) {
                                          setState(() {
                                            twoColor = color;
                                            _showFab = true;
                                          });
                                        },
                                      ),
                                    ),
                                    actions: <Widget>[
                                      IconButton(
                                        icon: const Icon(Icons.check),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            })
                      ])),
                  SettingItem(
                    name: "デバイス情報",
                    defaultValue: "",
                    widget: Text(
                      instance.deviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SettingItem(
                    name: "メッセージの保存先",
                    defaultValue: "",
                    widget: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('user_account')
                          .doc('${profile?["sub"]}')
                          .get(),
                      builder: (context, snapshot) {
                        String storageType = "Firestore";
                        if (snapshot.hasData && snapshot.data != null) {
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          storageType = data?['storage_type'] ?? "Firestore";
                        }
                        return DropdownButton<String>(
                          value: storageType == "Firestore" ? "サーバー" : storageType,
                          dropdownColor: const Color.fromARGB(255, 40, 40, 40),
                          style: const TextStyle(color: Colors.white),
                          underline: Container(
                            height: 2,
                            color: Colors.white,
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              // 表示用の値を内部値に変換
                              final internalValue = newValue == "サーバー" ? "Firestore" : newValue;
                              FirebaseFirestore.instance
                                  .collection('user_account')
                                  .doc('${profile?["sub"]}')
                                  .update({
                                'storage_type': internalValue
                              });
                              setState(() {
                                _showFab = true;
                              });
                            }
                          },
                          items: <String>['Google Drive', 'サーバー']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  CenterButton(
                      name: "キャッシュを削除",
                      fontColor: Colors.white,
                      function: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return SimpleDialog(
                              title: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 3,
                                children:[
                                  const Text(
                                    'キャッシュを削除しますか？',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const Text(
                                    'ログイン状態は保持されます',
                                    style: TextStyle(fontSize: 13,color: Color.fromARGB(170, 0, 0, 0)),
                                  ),
                                ]
                              ),
                              children: <Widget>[
                                SimpleDialogOption(
                                    child: const Text(
                                      'はい',
                                      style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 255, 10, 10)),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      instance.deleteImageCache();
                                    }),
                                SimpleDialogOption(
                                    child: const Text('キャンセル'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    }),
                              ],
                            );
                          },
                        );
                      }),
                      CenterButton(
                      name: "ログアウト",
                      fontColor: Colors.redAccent,
                      function: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return SimpleDialog(
                              title: const Text(
                                'ログアウトしますか？',
                                style: TextStyle(fontSize: 16),
                              ),
                              children: <Widget>[
                                SimpleDialogOption(
                                    child: const Text(
                                      'はい',
                                      style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 255, 10, 10)),
                                    ),
                                    onPressed: () async {
                                      await instance.logout();
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const MyHomePage()),
                                        (route) => false,
                                      );
                                    }),
                                SimpleDialogOption(
                                    child: const Text('キャンセル'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    }),
                              ],
                            );
                          },
                        );
                      })
                ] //childlen 画面全体
                    )),
          ),
        );
      },
    );
  }
}
