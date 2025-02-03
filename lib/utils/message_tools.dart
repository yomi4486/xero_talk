import 'package:xero_talk/utils/auth_context.dart';
import 'dart:convert' as convert;

final AuthContext instance = AuthContext();

void sendMessage(String? text,String channelId) async {
  /// instanceで有効になっているソケット通信に対してメッセージを送信する
  if (text!.isNotEmpty) {
    final sendBody = {"type": "send_message", "content": text, "channel": channelId};
    final String data = convert.json.encode(sendBody);
    if(instance.channel.readyState == 3){ // WebSocketが接続されていない場合
      await instance.restoreConnection();
      instance.channel.add(data);
      return;
    }
    try{
      instance.channel.add(data);
    }catch(e){
      print('送信に失敗：${e}');
    }
  }
}

Future deleteMessage(String messageId,String channelId) async {
  final sendBody = {"type": "delete_message","id": messageId,"channel":channelId};
  final String data = convert.json.encode(sendBody);
  if(instance.channel.readyState == 3){ // WebSocketが接続されていない場合
    await instance.restoreConnection().then((v){
      instance.channel.add(data);
    });
    return;
  }
  try{
    instance.channel.add(data);
  }catch(e){
    print('削除に失敗：${e}');
  }
}

Future editMessage(String messageId,String channelId,String content) async {
  if (content.isNotEmpty) {
    final sendBody = {"type": "edit_message","id": messageId,"channel":channelId,"content":content};
    final String data = convert.json.encode(sendBody);
    if(instance.channel.readyState == 3){ // WebSocketが接続されていない場合
      await instance.restoreConnection().then((v){
        instance.channel.add(data);
      });
      return;
    }
    try{
      instance.channel.add(data);
    }catch(e){
      print('編集に失敗：${e}');
    }
  }
}