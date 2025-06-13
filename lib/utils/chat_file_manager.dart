import 'package:googleapis/drive/v3.dart' as drive;
import 'dart:convert' as convert;
import 'dart:convert' show utf8;
import 'package:xero_talk/utils/auth_context.dart';

class ChatFileManager {
  final String? chatFileId;

  ChatFileManager({
    required this.chatFileId,
  });

  final AuthContext authContext = AuthContext();

  Future<void> saveChatHistory(Map<String, dynamic> data) async {
    try {
      if (chatFileId == null) return;

      final content = convert.jsonEncode(data);
      final bytes = utf8.encode(content);
      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
      );

      await authContext.googleDriveApi.files.update(
        drive.File()
          ..name = 'chat_history.json'
          ..mimeType = 'application/json; charset=utf-8',
        chatFileId!,
        uploadMedia: media,
      );
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  Future<String?> loadOrCreateChatFile() async {
    try {
      final result = await authContext.googleDriveApi.files.list(
        spaces: 'appDataFolder',
        q: "name='chat_history.json'",
      );

      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first.id;
      } else {
        final file = drive.File()
          ..name = 'chat_history.json'
          ..parents = ['appDataFolder']
          ..mimeType = 'application/json';

        final createdFile = await authContext.googleDriveApi.files.create(file);
        
        // 初期データを保存
        final initialData = {
          'messages': [],
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        };
        await saveChatHistory(initialData);
        
        return createdFile.id;
      }
    } catch (e) {
      print('Error initializing chat file: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> loadChatHistory() async {
    try {
      if (chatFileId == null) return null;

      final file = await authContext.googleDriveApi.files.get(
        chatFileId!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = await file.stream.toList();
      final content = utf8.decode(bytes.expand((x) => x).toList());
      final data = convert.jsonDecode(content);
      
      if (data['messages'] != null) {
        return Map<String, dynamic>.from(data['messages']);
      }
      return null;
    } catch (e) {
      print('Error loading chat history: $e');
      return null;
    }
  }
} 