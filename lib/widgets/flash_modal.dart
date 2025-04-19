// TODO: dangerous(error),warning,info,debugの4種類を用意。通知やネットワークエラー、その他ユーザーに伝えなければならないことなどをフラッシュメッセージで表示する、
// dangerous(error): ネットワークエラーやユーザーの操作が失敗した時など、アプリの動作に問題が発生した時に表示する。これはユーザーがアクションを起こすまで消えない。
// warnnig: エラーではないものの、重要度が比較的高いメッセージを表示。おそらくあまり使う機会はなさそう。
// info: アプリ内通知などに使うモーダル。一般的なレベルの情報は全てこれを使用。　進捗50％
// debug: debugモードを有効にしている場合により詳細な情報を表示する。
import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash/flash.dart';
import 'package:flash/flash_helper.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:xero_talk/utils/get_user_profile.dart';
import 'package:xero_talk/widgets/user_icon.dart';
import 'package:xero_talk/widgets/create_message_card.dart';
// import 'package:xero_talk/chat.dart';

Future<void> showInfoSnack(
    BuildContext context, {
    required Map<dynamic,dynamic> content
  }) async {
  // final instance = AuthContext();
  final userProfile = await getUserProfile(content['author']);
  context.showFlash<bool>(
    duration: Duration(seconds: 5),
    builder: (context, controller){
      return Flash(
        controller: controller,
        position: FlashPosition.top,
        child: Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.up, // 上方向のみ許可
          onDismissed: (_) => controller.dismiss(),
          child:ProgressFlash(
            controller: controller,
            content: content,
            userProfile: userProfile,
          ),
        )
      );
    }
  );
}

class ProgressFlash extends StatefulWidget {
  final FlashController controller;
  final Map<dynamic,dynamic> content;
  final Map<String,dynamic> userProfile;
  ProgressFlash({required this.controller,required this.content,required this.userProfile});

  @override
  _ProgressFlashState createState() => _ProgressFlashState();
}

class _ProgressFlashState extends State<ProgressFlash> {
  final instance = AuthContext();
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startProgress();
  }

  void _startProgress() {
    Future.delayed(Duration(milliseconds: 100), () async {
      for (int i = 0; i <= 100; i++) {
        await Future.delayed(Duration(milliseconds: 50));
        if (!mounted) return;
        setState(() => _progress = i / 100);
      }
      widget.controller.dismiss(); // バーが最大になったら閉じる
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> textColor = instance.getTextColor(Color.fromARGB(255, 22, 22, 22));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children:[
        Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 22, 22, 22),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5), // 影の色と透明度
                spreadRadius: 2, // 影の広がり
                blurRadius: 5, // ぼかしの強さ
                offset: Offset(3, 3), // 影の位置 (x, y)
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.3,
          ),
          margin: EdgeInsets.only(top: 60,left: 20,right: 20),
          child:Wrap(
            children: [
              Container(      
                width: MediaQuery.of(context).size.width * 0.9,
                padding: EdgeInsets.all(22),
                child: Row(
                  spacing: 10,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          // アイコン表示（角丸）
                          borderRadius: BorderRadius.circular(1000),
                          child: UserIcon(userId: widget.content['author'],size:MediaQuery.of(context).size.width * 0.1)
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DefaultTextStyle(
                          style: TextStyle(),
                          child: Text(
                            widget.userProfile['display_name'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        SizedBox(
                          child:
                        DefaultTextStyle(
                          overflow: TextOverflow.fade,
                          style: TextStyle(),
                          child: RichText(
                          text: TextSpan(
                            children: getTextSpans(widget.content["content"], false, textColor),
                            style:
                                TextStyle(color: textColor[1], fontSize: 16.0),
                          ),
                        )
                        ),),
                      ],
                  ),
                ]
              )),
              LinearProgressIndicator(
                minHeight: 5,
                value: _progress,
                backgroundColor: Color.fromARGB(0, 22, 22, 22),
                valueColor: AlwaysStoppedAnimation<Color>(instance.theme[0]),
              ),
            ],
          )
        ),
      ]
    );
  }
}