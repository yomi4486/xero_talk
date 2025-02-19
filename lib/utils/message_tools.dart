import 'package:xero_talk/utils/auth_context.dart';
import 'dart:convert' as convert;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

final AuthContext instance = AuthContext();

/// メッセージの送信を行います
void sendMessage(String? text,String channelId,{List<String>imageList=const []}) async {
  /// instanceで有効になっているソケット通信に対してメッセージを送信する
  if (text!.isNotEmpty||imageList.isNotEmpty) {
    final sendBody = {"type": "send_message", "content": text, "channel": channelId,"attachments":imageList};
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

/// メッセージの削除を行います。
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

/// 自分のメッセージを編集できます
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

Future<String?> pickImage() async {
  // 画像をスマホのギャラリーから取得
  final image = await ImagePicker().pickImage(source: ImageSource.gallery);
  String base64Data = "";
  // 画像を取得できた場合はクロップする
  if (image != null) {
    final bytesData = await image.readAsBytes();
    base64Data = base64Encode(bytesData);
    return base64Data;
  }
  return null;
}