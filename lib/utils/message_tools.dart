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

const Uuid uuid = Uuid();

/// メッセージの送信を行います
Future<void> sendMessage(String? text, String channelId,
    {List<String> imageList = const []}) async {
  /// instanceで有効になっているソケット通信に対してメッセージを送信する
  final instance = AuthContext();
  List<String> uploadedImageUrls = [];

  if (imageList.isNotEmpty) {
    for (String base64Image in imageList) {
      try {
        Uint8List imageData = base64Decode(base64Image);
        String fileName = 'attachments/${uuid.v4()}.png'; // Unique filename for Firebase Storage
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = storageRef.putData(imageData);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        uploadedImageUrls.add(downloadUrl);
      } catch (e) {
        print('画像のアップロードに失敗しました: $e');
        // Handle error, maybe show a snackbar to the user
      }
    }
  }

  if (text!.isNotEmpty || uploadedImageUrls.isNotEmpty) {
    final sendBody = {
      "type": "send_message",
      "content": text,
      "channel": channelId,
      "attachments": uploadedImageUrls
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
}

/// メッセージの削除を行います。
Future<void> deleteMessage(String messageId, String channelId) async {
  final instance = AuthContext();
  final sendBody = {
    "type": "delete_message",
    "id": messageId,
    "channel": channelId
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
    print('削除に失敗：${e}');
  }
}

/// 自分のメッセージを編集できます
Future<void> editMessage(String messageId, String channelId, String content) async {
  final instance = AuthContext();
  if (content.isNotEmpty) {
    final sendBody = {
      "type": "edit_message",
      "id": messageId,
      "channel": channelId,
      "content": content
    };
    final String data = convert.json.encode(sendBody);
    if (instance.channel.readyState == 3) {
      // WebSocketが接続されていない場合
      await instance.restoreConnection().then((v) {
        instance.channel.add(data);
      });
      return;
    }
    try {
      instance.channel.add(data);
    } catch (e) {
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

    if (imageData != null) {
      // 一時ディレクトリを取得
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${uuid.v4()}.png';

      // ファイルにデコードしたデータを書き込む
      final file = File(filePath);
      await file.writeAsBytes(imageData);

      // ギャラリーに保存
      await GallerySaver.saveImage(file.path);
    }
  } catch (e) {
    print('Failed to save image to gallery: $e');
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