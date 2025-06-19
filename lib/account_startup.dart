import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xero_talk/tabs.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:xero_talk/widgets/user_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:xero_talk/utils/user_icon_tools.dart' as uit;
import 'package:image_cropper/image_cropper.dart';

class AccountStartup extends StatefulWidget {
  @override
  _AccountStartupState createState() => _AccountStartupState();
}

class _AccountStartupState extends State<AccountStartup> {
  final AuthContext instance = AuthContext();
  final Color defaultColor = const Color.fromARGB(255, 22, 22, 22);
  final nowDt = DateTime.now().millisecondsSinceEpoch;
  String name = "";
  String displayName = "";
  String description = "";
  bool isUserIdAvailable = true;
  bool isCheckingUserId = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _displayNameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    name = instance.userCredential.user!.email!
        .replaceAll('@gmail.com', '')
        .replaceAll('@icloud.com', '');
    displayName = "${instance.userCredential.user!.displayName}";
    _nameController.text = name;
    _displayNameController.text = displayName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _nameFocusNode.dispose();
    _displayNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> checkUserIdAvailability(String userId) async {
    if (userId.isEmpty) {
      setState(() {
        isUserIdAvailable = false;
        isCheckingUserId = false;
      });
      return;
    }

    if (userId.contains(' ')) {
      setState(() {
        isUserIdAvailable = false;
        isCheckingUserId = false;
      });
      return;
    }

    setState(() {
      isCheckingUserId = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user_account')
          .where('name', isEqualTo: userId)
          .get();

      setState(() {
        isUserIdAvailable = querySnapshot.docs.isEmpty;
        isCheckingUserId = false;
      });
    } catch (e) {
      setState(() {
        isUserIdAvailable = false;
        isCheckingUserId = false;
      });
    }
  }

  Future<void> upload(String token) async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          compressFormat: ImageCompressFormat.png,
          maxHeight: 512,
          maxWidth: 512,
          compressQuality: 0,
          aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0));

      if (croppedFile != null) {
        final bytesData = await croppedFile.readAsBytes();
        final base64Data = base64Encode(bytesData);
        await uit.upload(token, base64Data);
        instance.deleteImageCache(id: instance.id);
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('すてきなプロフィールを作りましょう🎉'),
        centerTitle: true,
        titleTextStyle: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255), fontSize: 16),
        backgroundColor: const Color.fromARGB(255, 40, 40, 40),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (!isUserIdAvailable || name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ユーザーIDが無効です'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            var profile = instance.userCredential.additionalUserInfo?.profile;
            FirebaseFirestore.instance
                .collection('user_account')
                .doc('${profile?["sub"]}')
                .set({
              'description': description,
              'display_name': displayName,
              'name': name,
            }).then((value) {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => PageViewTabsScreen()));
            }).catchError((err) {
              debugPrint(err);
            });
          },
          backgroundColor: instance.theme[1],
          child: const Icon(
            Icons.arrow_forward_ios_sharp,
            color: Color.fromARGB(200, 255, 255, 255),
          )),
      backgroundColor: defaultColor,
      body: SafeArea(
        child: DecoratedBox(
            decoration:
                const BoxDecoration(color: Color.fromARGB(255, 22, 22, 22)),
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
                                },
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(1000),
                                      child: UserIcon(
                                          userId: instance.id,
                                          size: MediaQuery.of(context).size.width * 0.2),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Material(
                                        color: Colors.black,
                                        elevation: 4,
                                        shape: const CircleBorder(),
                                        child: Container(
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              child: Container(
                                  width: MediaQuery.of(context).size.width * 0.6,
                                  margin: const EdgeInsets.only(left: 10),
                                  child: Column(children: [
                                    TextField(
                                      controller: _displayNameController,
                                      focusNode: _displayNameFocusNode,
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 255, 255, 255),
                                        fontSize: 16,
                                      ),
                                      decoration: const InputDecoration(
                                          hintText: '',
                                          labelText: 'ニックネーム',
                                          labelStyle: TextStyle(
                                            color: Color.fromARGB(255, 255, 255, 255),
                                            fontSize: 16,
                                          ),
                                          hintStyle: TextStyle(
                                            color: Color.fromARGB(255, 255, 255, 255),
                                            fontSize: 16,
                                          )),
                                      onChanged: (text) {
                                        displayName = text;
                                      },
                                    ),
                                    TextField(
                                      controller: _nameController,
                                      focusNode: _nameFocusNode,
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 255, 255, 255),
                                        fontSize: 16,
                                      ),
                                      decoration: InputDecoration(
                                          hintText: '',
                                          labelText: 'ユーザーID(英数字のみ)',
                                          labelStyle: const TextStyle(
                                            color: Color.fromARGB(255, 255, 255, 255),
                                            fontSize: 16,
                                          ),
                                          hintStyle: const TextStyle(
                                            color: Color.fromARGB(255, 255, 255, 255),
                                            fontSize: 16,
                                          ),
                                          errorText: isCheckingUserId
                                              ? null
                                              : name.isEmpty
                                                  ? 'ユーザーIDを入力してください'
                                                  : name.contains(' ')
                                                      ? 'スペースは使用できません'
                                                      : !isUserIdAvailable
                                                          ? 'このユーザーIDは使用できません'
                                                          : null,
                                          helperText: isCheckingUserId ? '' : null,
                                          helperStyle: const TextStyle(
                                            color: Color.fromARGB(255, 255, 255, 255),
                                          )),
                                      onChanged: (text) {
                                        name = text;
                                        checkUserIdAvailability(text);
                                      },
                                    )
                                  ]))),
                        ],
                      ),
                    ])),
              ),
              SizedBox(
                  child: Container(
                margin: const EdgeInsets.only(left: 30, right: 30),
                child: TextField(
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
                  },
                ),
              ))
            ])),
      ),
    );
  }
}
