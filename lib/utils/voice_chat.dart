import 'package:firebase_auth/firebase_auth.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'dart:convert' as convert;
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

final AuthContext instance = AuthContext();
const Uuid uuid = Uuid();

void call(String to_user_id) async {
  final sendBody = {
    "type": "call",
    "author": instance.id,
    "channel": to_user_id
  };
  final String data = convert.json.encode(sendBody);
  if (instance.channel.readyState == 3) {
    // WebSocketが接続されていない場合
    await instance.restoreConnection();
    instance.channel.add(data);
    return;
  }
  try {
    instance.channel.add(data);
  } catch (e) {
    print('送信に失敗：${e}');
  }
}

Future<String> getRoom(String roomId) async {
  print(roomId);
  String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
  final response = await http.get(
      Uri.parse("https://${dotenv.env['BASE_URL']}/voiceclient"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'token':token!,
        'roomId':roomId
      }
  );
  if (response.statusCode != 200) {
    print('Request failed with status: ${response.statusCode}');
  }
  return response.body.toString();
}