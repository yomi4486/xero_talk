// TODO: dangerous(error),warning,info,debugの4種類を用意。通知やネットワークエラー、その他ユーザーに伝えなければならないことなどをフラッシュメッセージで表示する、
// dangerous(error): ネットワークエラーやユーザーの操作が失敗した時など、アプリの動作に問題が発生した時に表示する。これはユーザーがアクションを起こすまで消えない。
// warnnig: エラーではないものの、重要度が比較的高いメッセージを表示。おそらくあまり使う機会はなさそう。
// info: アプリ内通知などに使うモーダル。一般的なレベルの情報は全てこれを使用。　進捗50％
// debug: debugモードを有効にしている場合により詳細な情報を表示する。
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash/flash.dart';
import 'package:flash/flash_helper.dart';

class InfoSnack extends StatelessWidget {
  /// アプリ内通知などに使うモーダル。一般的なレベルの情報は全てこれを使用。
  InfoSnack(
      {Key? key,
      required this.userCredential,
      required this.title,
      required this.datail})
      : super(key: key);
  final UserCredential userCredential;
  final String title;
  final String datail;
  @override
  Widget build(BuildContext context) {
    final snack = ElevatedButton(
      child: const Text("通知(テスト)"),
      onPressed: () => context.showFlash<bool>(
        barrierDismissible: true,
        duration: const Duration(seconds: 3),
        builder: (context, controller) => FlashBar(
          // こいつが通知ウィジェット本体
          controller: controller,
          forwardAnimationCurve: Curves.easeInCirc,
          reverseAnimationCurve: Curves.bounceIn,
          position: FlashPosition.top,
          indicatorColor: const Color.fromARGB(255, 140, 206, 74),
          icon: ImageIcon(
            NetworkImage("${userCredential.user!.photoURL}"),
          ),
          title: Text(title),
          content: Text(datail),
          actions: [
            TextButton(onPressed: controller.dismiss, child: Text('Cancel')),
            TextButton(
                onPressed: () => controller.dismiss(true),
                child: Text('Ok')) // TODO:これがクリックされたら対象ユーザーのチャット画面に遷移する処理を書く
          ],
        ),
      ),
    );
    return snack;
  }
}
