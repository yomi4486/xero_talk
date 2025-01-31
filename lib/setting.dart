import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:xero_talk/widgets/setting_item.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SettingPage extends StatefulWidget {
  SettingPage();
  final Color defaultColor = const Color.fromARGB(255, 22, 22, 22);
  @override
  _SettingPage createState() => _SettingPage();
}

class _SettingPage extends State<SettingPage>{
  _SettingPage();
  bool _showFab = false; // falseなら未編集、trueなら編集済み
  final AuthContext instance = AuthContext();
  late List<String> theme;
  Color oneColor = const Color.fromARGB(204, 228, 169, 114);
  Color twoColor = const Color.fromARGB(204, 153, 65, 216);

  @override
  Widget build (BuildContext context) {
    var profile = instance.userCredential.additionalUserInfo?.profile;
    return Scaffold(
      body: FutureBuilder(
        future:FirebaseFirestore.instance
          .collection('user_account') // コレクションID
          .doc('${profile?["sub"]}') // ドキュメントID
          .get(),
        builder:(context, snapshot){
          if(!_showFab){
            if (snapshot.connectionState == ConnectionState.waiting) {
            } else if (snapshot.hasError) {
            } else if (snapshot.hasData) { // successful
              theme = (snapshot.data?.data() as Map<String, dynamic>)["color_theme"] ?? [];
            } else {
            }
          }
          return Scaffold(
            appBar:AppBar(
              centerTitle: false,
              automaticallyImplyLeading: false,
              title: const Text("設定",style: TextStyle(fontWeight: FontWeight.bold,)),
              titleTextStyle: const TextStyle(
                color:Color.fromARGB(255, 255, 255, 255),
                fontSize: 20
              ),
              backgroundColor: const Color.fromARGB(255, 40, 40, 40),
            ),
            floatingActionButton: _showFab ? FloatingActionButton( 
              onPressed: () async {
                if(_showFab){
                  // ドキュメント作成
                  FirebaseFirestore.instance
                    .collection('user_account') // コレクションID
                    .doc('${profile?["sub"]}') // ドキュメントID
                    .update(
                      {
                        'color_theme':[]
                      }
                    )
                    .then((value){
                      setState((){
                        _showFab = false;
                      });
                    })
                    .catchError((err){
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
            ) : null, 
            
            backgroundColor: widget.defaultColor,
            body: SafeArea(
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color.fromARGB(255, 22, 22, 22)),
                child:ListView( 
                  children: [
                    SettingItem(name: "テーマ", defaultValue: "", widget: AlertDialog(
                      title: Text('Pick a color!'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: oneColor,
                          onColorChanged: (Color color) {
                            setState(() {
                              oneColor = color;
                            });
                          },
                        ),
                      ),
                      actions: <Widget>[
                        ElevatedButton(
                          child: Text('Got it'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ))
                  ] //childlen 画面全体
                )
              ),
            ),
          );
        },
      ),
    );
  }
}