import 'package:xero_talk/utils/auth_context.dart';
import 'dart:convert' as convert;
import 'package:mqtt_client/mqtt_client.dart' show MqttQos, MqttConnectionState;
import 'package:typed_data/typed_buffers.dart';

final AuthContext instance = AuthContext();

Future<void> upload(String token, String imageData) async {
  final sendBody = {
    "user_id": instance.id,
    "content": imageData,
  };
  final String data = convert.json.encode(sendBody);
  if (instance.mqttClient.connectionState != MqttConnectionState.connected) {
    await instance.restoreConnection();
  }
  try {
    Uint8Buffer buffer = Uint8Buffer();
    buffer.addAll(data.codeUnits);
    instance.mqttClient.publishMessage(
      'request/seticon',
      MqttQos.atMostOnce,
      buffer,
    );
  } catch (e) {
    print('送信に失敗：${e}');
    rethrow;
  }

  // レスポンスを待つ
  final response = await instance.mqttStream
      .where((msg) {
        try {
          final json = convert.json.decode(msg);
          return json["status"] == "ok" || json["status"] == "error";
        } catch (_) {
          return false;
        }
      })
      .first
      .timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception("seticon response timeout");
      });

  final json = convert.json.decode(response);
  if (json["status"] != "ok") {
    print('Request failed: [31m${json["message"]}[0m');
  }
}
