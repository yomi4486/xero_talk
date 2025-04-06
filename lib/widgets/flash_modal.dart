// TODO: dangerous(error),warning,info,debugの4種類を用意。通知やネットワークエラー、その他ユーザーに伝えなければならないことなどをフラッシュメッセージで表示する、
// dangerous(error): ネットワークエラーやユーザーの操作が失敗した時など、アプリの動作に問題が発生した時に表示する。これはユーザーがアクションを起こすまで消えない。
// warnnig: エラーではないものの、重要度が比較的高いメッセージを表示。おそらくあまり使う機会はなさそう。
// info: アプリ内通知などに使うモーダル。一般的なレベルの情報は全てこれを使用。　進捗50％
// debug: debugモードを有効にしている場合により詳細な情報を表示する。
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash/flash.dart';
import 'package:flash/flash_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:xero_talk/utils/get_user_profile.dart';
import 'package:xero_talk/chat.dart';

Future<void> showInfoSnack(
    BuildContext context, {
    required Map<dynamic,dynamic> content
  }) async {
  // final instance = AuthContext();
  final userProfile = await getUserProfile(content['author']);
  context.showFlash<bool>(
    builder: (context, controller) => FlashBar(
      controller: controller,
      forwardAnimationCurve: Curves.easeInCirc,
      reverseAnimationCurve: Curves.bounceIn,
      position: FlashPosition.top,
      indicatorColor: const Color.fromARGB(255, 140, 206, 74),
      icon: ImageIcon(
        NetworkImage("https://${dotenv.env['BASE_URL']}/geticon?user_id=${content['author']}"),
      ),
      title: Text(userProfile['display_name']),
      content: Text(content['content']),
      actions: [
        TextButton(onPressed: controller.dismiss, child: Text('Cancel')),
        TextButton(
            onPressed: ()async{
              // final Map<String, dynamic>
              //     userData =
              //     await getUserProfile(content['author']);
              // final Widget openWidget =
              //     chat(channelInfo: userData,);
              // instance.lastOpenedChat =
              //     openWidget;
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //       builder: (context) =>
              //           openWidget),
              // );                             
            },
            child: Text('開く'))
      ],
    ),
  );
}