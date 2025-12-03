import 'package:xero_talk/utils/auth_context.dart';
import 'dart:convert' as convert;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';

import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart' show MqttQos, MqttConnectionState;
import 'package:typed_data/typed_buffers.dart';
import 'package:image/image.dart' as img;

const Uuid uuid = Uuid();

/// メッセージの送信を行います
Future<List<String>> sendMessage(String? text, String channelId,
    {List<String> imageList = const [], String? id, bool isGroup = false}) async {
  /// instanceで有効になっているソケット通信に対してメッセージを送信する
  final instance = AuthContext();
  List<String> uploadedImageUrls = [];
  if(text!.isEmpty && imageList.isEmpty){throw Exception("メッセージが空です");}
  if (imageList.isNotEmpty) {
    for (String base64Image in imageList) {
      try {
        Uint8List imageData = base64Decode(base64Image);

        // 圧縮処理
        img.Image? decodedImage = img.decodeImage(imageData);
        if (decodedImage != null) {
          // 最大幅512pxにリサイズし、JPEGで80%品質で圧縮
          final compressed = img.encodeJpg(decodedImage, quality: 50);
          imageData = Uint8List.fromList(compressed);
        }

        String fileName = 'attachments/${uuid.v4()}.jpg'; // 拡張子もjpgに
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = storageRef.putData(imageData);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        uploadedImageUrls.add(downloadUrl);
      } catch (e) {
        debugPrint('画像のアップロードに失敗しました: $e');
        // Handle error, maybe show a snackbar to the user
      }
    }
  }

  if (text.isNotEmpty || uploadedImageUrls.isNotEmpty) {
    print("uploadedImageUrls: $uploadedImageUrls");
    final sendBody = {
      "user_id": instance.id,
      "type": "send_message",
      "content": text,
      "channel": channelId,
      "attachments": uploadedImageUrls,
      "is_group": isGroup,
      if (id != null) "id": id,
    };
    final String data = convert.json.encode(sendBody);
    if (instance.mqttClient.connectionState != MqttConnectionState.connected) {
      await instance.restoreConnection();
    }
    try {
      final bytes = utf8.encode(data);
      Uint8Buffer buffer = Uint8Buffer();
      buffer.addAll(bytes);
      instance.mqttClient.publishMessage(
        'request/send_message',
        MqttQos.atMostOnce,
        buffer,
      );
    } catch (e) {
      debugPrint('送信に失敗：${e}');
    }
  }
  return uploadedImageUrls;
}

/// メッセージの削除を行います。
Future<void> deleteMessage(String messageId, String channelId) async {
  final instance = AuthContext();
  final sendBody = {
    "user_id": instance.id,
    "type": "delete_message",
    "id": messageId,
    "channel": channelId
  };
  final String data = convert.json.encode(sendBody);
  if (instance.mqttClient.connectionState != MqttConnectionState.connected) {
    await instance.restoreConnection();
  }
  try {
    final bytes = utf8.encode(data); // ← ここが重要
    Uint8Buffer buffer = Uint8Buffer();
    buffer.addAll(bytes);
    instance.mqttClient.publishMessage(
      'request/delete_message',
      MqttQos.atMostOnce,
      buffer,
    );
  } catch (e) {
    debugPrint('削除に失敗：${e}');
  }
}

/// 自分のメッセージを編集できます
Future<void> editMessage(String messageId, String channelId, String content) async {
  final instance = AuthContext();
  if (content.isNotEmpty) {
    final sendBody = {
      "user_id": instance.id,
      "type": "edit_message",
      "id": messageId,
      "channel": channelId,
      "content": content
    };
    final String data = convert.json.encode(sendBody);
    if (instance.mqttClient.connectionState != MqttConnectionState.connected) {
      await instance.restoreConnection();
    }
    try {
      final bytes = utf8.encode(data);
      Uint8Buffer buffer = Uint8Buffer();
      buffer.addAll(bytes);
      instance.mqttClient.publishMessage(
        'request/edit_message',
        MqttQos.atMostOnce,
        buffer,
      );
    } catch (e) {
      debugPrint('編集に失敗：${e}');
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

Future<void> saveImageToGallery(String imageUrlOrBase64) async {
  try {
    Uint8List? imageData;
    if (imageUrlOrBase64.startsWith('http')) {
      final response = await HttpClient().getUrl(Uri.parse(imageUrlOrBase64));
      final receivedResponse = await response.close();
      imageData = await consolidateHttpClientResponseBytes(receivedResponse);
    } else {
      // Assume it's a base64 string
      imageData = base64Decode(imageUrlOrBase64);
    }

    // 一時ディレクトリを取得
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/${uuid.v4()}.png';

    // ファイルにデコードしたデータを書き込む
    final file = File(filePath);
    await file.writeAsBytes(imageData);

    // ギャラリーに保存
    await GallerySaver.saveImage(file.path);
  
  } catch (e) {
    debugPrint('Failed to save image to gallery: $e');
  }
}

String getTimeStringFormat(DateTime dateTime) {
  final DateTime nowDate = DateTime.now();
  late String today;
  if (dateTime.year == nowDate.year &&
      dateTime.month == nowDate.month &&
      dateTime.day == nowDate.day) {
    today = "今日";
  } else {
    today = "${dateTime.year}/${dateTime.month}/${dateTime.day}";
  }
  final String modifiedDateTime =
      "$today, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  return modifiedDateTime;
}