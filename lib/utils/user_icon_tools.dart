import 'package:xero_talk/utils/auth_context.dart';
import 'dart:convert' as convert;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

final AuthContext instance = AuthContext();

Future<void> upload(String token, String imageData) async {
  try {
    // Base64デコード
    final Uint8List imageBytes = Uint8List.fromList(
      convert.base64Decode(imageData.split(',').last)
    );
    
    // 画像をデコード
    final img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      throw Exception('Failed to decode image');
    }
    
    // 1024x1024にリサイズ（アスペクト比を保持）
    final img.Image resizedImage = img.copyResize(
      originalImage,
      width: 1024,
      height: 1024,
      interpolation: img.Interpolation.cubic
    );
    
    // PNG形式でエンコード（圧縮）
    final Uint8List compressedImageBytes = Uint8List.fromList(
      img.encodePng(resizedImage, level: 6) // 圧縮レベル6（0-9、9が最高圧縮）
    );
    
    // Firebase Storage の参照を作成
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('icons/users/${instance.id}.png');
    
    // 画像をアップロード
    final uploadTask = storageRef.putData(
      compressedImageBytes,
      SettableMetadata(
        contentType: 'image/png',
        cacheControl: 'public, max-age=31536000', // 1年間キャッシュ
      ),
    );
    
    // アップロード完了を待つ
    await uploadTask;
  } catch (e) {
    print('アイコンアップロードに失敗：$e');
    rethrow;
  }
}
