import 'package:googleapis/drive/v3.dart' as drive;
import 'dart:convert' as convert;
import 'dart:convert' show utf8;
import 'package:xero_talk/utils/auth_context.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatFileManager {
  final String? chatFileId;
  final AuthContext authContext = AuthContext();
  String storageType = "Firestore";
  String? _userId;
  final String? _friendId;

  ChatFileManager({
    required this.chatFileId,
    String? friendId,
  }) : _friendId = friendId;

  Future<void> _initializeStorageType() async {
    try {
      final profile = authContext.userCredential.additionalUserInfo?.profile;
      _userId = profile?["sub"];
      final doc = await FirebaseFirestore.instance
          .collection('user_account')
          .doc('$_userId')
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        storageType = data?['storage_type'] ?? "Firestore";
      }
    } catch (e) {
      print('Error initializing storage type: $e');
    }
  }

  String get _chatId {
    if (_userId == null || _friendId == null) return '';
    // ユーザーIDとフレンドIDを組み合わせて一意のチャットIDを生成
    // アルファベット順にソートして、同じペアのチャットが同じIDになるようにする
    final sortedIds = [_userId!, _friendId]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  Future<void> saveChatHistory(Map<String, dynamic> data) async {
    await _initializeStorageType();
    
    if (storageType == "Google Drive") {
      await _saveToGoogleDrive(data);
    } else {
      await _saveToFirestore(data);
    }
  }

  Future<void> updateMessage(String messageId, Map<String, dynamic> messageData) async {
    await _initializeStorageType();
    
    if (storageType == "Google Drive") {
      await _updateGoogleDriveMessage(messageId, messageData);
    } else {
      await _updateFirestoreMessage(messageId, messageData);
    }
  }

  Future<void> _updateFirestoreMessage(String messageId, Map<String, dynamic> messageData) async {
    try {
      if (_chatId.isEmpty) return;

      final docRef = FirebaseFirestore.instance
          .collection('chat_history')
          .doc(_chatId);
      
      // 既存のメッセージを更新
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data();
        if (data?['messages'] != null) {
          final List<dynamic> messages = List<dynamic>.from(data!['messages']);
          final index = messages.indexWhere((msg) => msg['id'] == messageId);
          
          if (index != -1) {
            messages[index] = {
              'id': messageId,
              ...messageData,
            };
            
            await docRef.update({
              'messages': messages,
              'lastUpdated': DateTime.now().millisecondsSinceEpoch,
            });
          }
        }
      }
    } catch (e) {
      print('Error updating message in Firestore: $e');
    }
  }

  Future<void> _updateGoogleDriveMessage(String messageId, Map<String, dynamic> messageData) async {
    try {
      if (chatFileId == null) return;

      final file = await authContext.googleDriveApi.files.get(
        chatFileId!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = await file.stream.toList();
      final content = utf8.decode(bytes.expand((x) => x).toList());
      final data = convert.jsonDecode(content);
      
      if (data['messages'] != null) {
        final List<dynamic> messages = List<dynamic>.from(data['messages']);
        final index = messages.indexWhere((msg) => msg['id'] == messageId);
        
        if (index != -1) {
          messages[index] = {
            'id': messageId,
            ...messageData,
          };
          
          data['messages'] = messages;
          data['lastUpdated'] = DateTime.now().millisecondsSinceEpoch;
          
          final updatedContent = convert.jsonEncode(data);
          final updatedBytes = utf8.encode(updatedContent);
          final media = drive.Media(
            Stream.value(updatedBytes),
            updatedBytes.length,
          );

          await authContext.googleDriveApi.files.update(
            drive.File()
              ..name = 'chat_history.json'
              ..mimeType = 'application/json; charset=utf-8',
            chatFileId!,
            uploadMedia: media,
          );
        }
      }
    } catch (e) {
      print('Error updating message in Google Drive: $e');
    }
  }

  Future<void> _saveToGoogleDrive(Map<String, dynamic> data) async {
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
      print('Error saving chat history to Google Drive: $e');
    }
  }

  Future<void> _saveToFirestore(Map<String, dynamic> data) async {
    try {
      if (_chatId.isEmpty) return;

      final docRef = FirebaseFirestore.instance
          .collection('chat_history')
          .doc(_chatId);
      
      // 新しいメッセージのみを追加
      if (data['messages'] is Map) {
        final messages = data['messages'] as Map;
        if (messages.isNotEmpty) {
          final lastMessage = messages.entries.last;
          final messageData = {
            'id': lastMessage.key,
            ...lastMessage.value,
          };
          
          // メッセージの送信者と受信者を検証
          final senderId = messageData['author'];
          // 現在のチャットの参加者と一致するか確認
          if (senderId != _userId && senderId != _friendId) return;
          
          // ドキュメントの存在確認
          final doc = await docRef.get();
          if (!doc.exists) {
            // 新規作成の場合
            await docRef.set({
              'messages': [messageData],
              'lastUpdated': DateTime.now().millisecondsSinceEpoch,
              'participants': [_userId, _friendId],
            });
          } else {
            // 更新の場合
            await docRef.update({
              'messages': FieldValue.arrayUnion([messageData]),
              'lastUpdated': DateTime.now().millisecondsSinceEpoch,
            });
          }
        }
      }
    } catch (e) {
      print('Error saving chat history to Firestore: $e');
    }
  }

  Future<String?> loadOrCreateChatFile() async {
    await _initializeStorageType();
    
    if (storageType == "Google Drive") {
      return await _loadOrCreateGoogleDriveFile();
    } else {
      return getChatStorageName();
    }
  }

  Future<String?> _loadOrCreateGoogleDriveFile() async {
    try {
      if (_chatId.isEmpty) return null;

      // ユーザー固有のフォルダを作成
      final folderName = 'chat_history_$_userId';
      final folderQuery = await authContext.googleDriveApi.files.list(
        spaces: 'appDataFolder',
        q: "name='$folderName' and mimeType='application/vnd.google-apps.folder'",
      );

      String folderId;
      if (folderQuery.files != null && folderQuery.files!.isNotEmpty) {
        folderId = folderQuery.files!.first.id!;
      } else {
        final folder = drive.File()
          ..name = folderName
          ..parents = ['appDataFolder']
          ..mimeType = 'application/vnd.google-apps.folder';
        final createdFolder = await authContext.googleDriveApi.files.create(folder);
        folderId = createdFolder.id!;
      }

      // フレンドとのチャット用のファイル名で検索
      final fileName = 'chat_history_$_chatId.json';
      final result = await authContext.googleDriveApi.files.list(
        spaces: 'appDataFolder',
        q: "name='$fileName' and '$folderId' in parents",
      );

      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first.id;
      } else {
        final file = drive.File()
          ..name = fileName
          ..parents = [folderId]
          ..mimeType = 'application/json';

        final createdFile = await authContext.googleDriveApi.files.create(file);
        
        // 初期データを保存
        final initialData = {
          'messages': [],
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          'participants': [_userId, _friendId],
        };
        await _saveToGoogleDrive(initialData);
        
        return createdFile.id;
      }
    } catch (e) {
      print('Error initializing Google Drive file: $e');
      return null;
    }
  }

  String? getChatStorageName() {
    try {
      if (_chatId.isEmpty) return null;
      return _chatId;
    } catch (e) {
      print('Error initializing Firestore file: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> loadChatHistory() async {
    await _initializeStorageType();
    
    if (storageType == "Google Drive") {
      return await _loadFromGoogleDrive();
    } else {
      return await _loadFromFirestore();
    }
  }

  Future<Map<String, dynamic>?> _loadFromGoogleDrive() async {
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
      print('Error loading chat history from Google Drive: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _loadFromFirestore() async {
    try {
      if (_chatId.isEmpty) return null;

      final doc = await FirebaseFirestore.instance
          .collection('chat_history')
          .doc(_chatId)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        if (data?['messages'] != null) {
          // List<dynamic> を Map<String, dynamic> に変換
          final List<dynamic> messagesList = data!['messages'];
          final Map<String, dynamic> messagesMap = {};
          for (var message in messagesList) {
            if (message is Map<String, dynamic> && message['id'] != null) {
              final String id = message['id'];
              final Map<String, dynamic> messageData = Map<String, dynamic>.from(message);
              messageData.remove('id'); // idはキーとして使用するので、値からは削除
              messagesMap[id] = messageData;
            }
          }
          return messagesMap;
        }
      }
      return null;
    } catch (e) {
      print('Error loading chat history from Firestore: $e');
      return null;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    await _initializeStorageType();
    
    if (storageType == "Google Drive") {
      await _deleteFromGoogleDrive(messageId);
    } else {
      await _deleteFromFirestore(messageId);
    }
  }

  Future<void> _deleteFromFirestore(String messageId) async {
    try {
      if (_chatId.isEmpty) return;

      final docRef = FirebaseFirestore.instance
          .collection('chat_history')
          .doc(_chatId);
      
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data();
        if (data?['messages'] != null) {
          final List<dynamic> messages = List<dynamic>.from(data!['messages']);
          final index = messages.indexWhere((msg) => msg['id'] == messageId);
          
          if (index != -1) {
            messages.removeAt(index);
            
            await docRef.update({
              'messages': messages,
              'lastUpdated': DateTime.now().millisecondsSinceEpoch,
            });
          }
        }
      }
    } catch (e) {
      print('Error deleting message from Firestore: $e');
    }
  }

  Future<void> _deleteFromGoogleDrive(String messageId) async {
    try {
      if (chatFileId == null) return;

      final file = await authContext.googleDriveApi.files.get(
        chatFileId!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = await file.stream.toList();
      final content = utf8.decode(bytes.expand((x) => x).toList());
      final data = convert.jsonDecode(content);
      
      if (data['messages'] != null) {
        final List<dynamic> messages = List<dynamic>.from(data['messages']);
        final index = messages.indexWhere((msg) => msg['id'] == messageId);
        
        if (index != -1) {
          messages.removeAt(index);
          
          data['messages'] = messages;
          data['lastUpdated'] = DateTime.now().millisecondsSinceEpoch;
          
          final updatedContent = convert.jsonEncode(data);
          final updatedBytes = utf8.encode(updatedContent);
          final media = drive.Media(
            Stream.value(updatedBytes),
            updatedBytes.length,
          );

          await authContext.googleDriveApi.files.update(
            drive.File()
              ..name = 'chat_history.json'
              ..mimeType = 'application/json; charset=utf-8',
            chatFileId!,
            uploadMedia: media,
          );
        }
      }
    } catch (e) {
      print('Error deleting message from Google Drive: $e');
    }
  }
} 