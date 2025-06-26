import 'package:firebase_auth/firebase_auth.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'dart:convert' as convert;
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart' show MqttQos, MqttConnectionState;
import 'package:typed_data/typed_buffers.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

final AuthContext instance = AuthContext();
const Uuid uuid = Uuid();

void call(String to_user_id, bool isGroup) async {
  final sendBody = {
    "type": "call",
    "author": instance.id,
    "channel": to_user_id,
    "isGroup": isGroup
  };
  final String data = convert.json.encode(sendBody);
  if (instance.mqttClient.connectionState != MqttConnectionState.connected) {
    await instance.restoreConnection();
  }
  try {
    Uint8Buffer buffer = Uint8Buffer();
    buffer.addAll(data.codeUnits);
    instance.mqttClient.publishMessage(
      'request/call',
      MqttQos.atMostOnce,
      buffer,
    );
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
        'authorization':"Bearer $token",
        'roomId':roomId
      }
  );
  print(response.body);
  if (response.statusCode != 200) {
    print('Request failed with status: ${response.statusCode}');
  }
  return convert.json.decode(response.body)["token"].toString();
}