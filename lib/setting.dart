import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xero_talk/main.dart';
import 'package:xero_talk/screens/account_deletion_screen.dart';
import 'package:xero_talk/screens/account_suspension_screen.dart';
import 'package:xero_talk/screens/blocked_users_screen.dart';
import 'package:xero_talk/services/google_drive_permission_service.dart';
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
    // アルファ値を255（FF）に固定し、RGB値のみを取得
    final rgb = color.withAlpha(255);
    return '#${rgb.value.toRadixString(16).toUpperCase().padLeft(8, '0')}';
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
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('user_account') // コレクションID
          .doc(instance.id) // ドキュメントID
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
                          .doc(instance.id) // ドキュメントID
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
                        debugPrint(err);
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
                          .doc(instance.id)
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
                          onChanged: (String? newValue) async {
                            if (newValue != null) {
                              // Google Driveが選択された場合、権限を要求
                              if (newValue == "Google Drive") {
                                final hasPermission = await GoogleDrivePermissionService.requestDrivePermissionAndInitialize();
                                if (!hasPermission) {
                                  // 権限が拒否された場合、選択を元に戻す
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Google Driveの権限が必要です。設定は変更されませんでした。'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Google Driveの権限が付与されました。メッセージはGoogle Driveに保存されます。'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                // サーバーが選択された場合、Google Driveの権限を無効化
                                GoogleDrivePermissionService.revokeDrivePermission();
                              }
                              
                              // 表示用の値を内部値に変換
                              final internalValue = newValue == "サーバー" ? "Firestore" : newValue;
                              await FirebaseFirestore.instance
                                  .collection('user_account')
                                  .doc(instance.id)
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
                  SettingItem(
                    name: "ブロック済みユーザー",
                    defaultValue: "",
                    widget: GestureDetector(
                      onTap: () {
                        print('SettingPage: ブロック済みユーザーボタンがタップされました');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlockedUsersScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 40, 40, 40),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: const Color.fromARGB(255, 100, 100, 100),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.block,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '管理',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
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
                      }),
                  const SizedBox(height: 20),
                  CenterButton(
                    name: "アカウント一時停止",
                    fontColor: Colors.orange,
                    function: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountSuspensionScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  CenterButton(
                    name: "アカウント削除",
                    fontColor: Colors.red,
                    function: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountDeletionScreen(),
                        ),
                      );
                    },
                  ),
                ] //childlen 画面全体
                    )),
          ),
        );
      },
    );
  }
}
