import 'package:googleapis/drive/v3.dart' as drive;
import 'dart:convert' as convert;
import 'dart:convert' show utf8;
import 'package:xero_talk/utils/auth_context.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatFileManager {
  final String? chatFileId;
  final AuthContext authContext = AuthContext();
  String storageType = "Google Drive";

  ChatFileManager({
    required this.chatFileId,
  });

  Future<void> _initializeStorageType() async {
    try {
      final profile = authContext.userCredential.additionalUserInfo?.profile;
      final doc = await FirebaseFirestore.instance
          .collection('user_account')
          .doc('${profile?["sub"]}')
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        storageType = data?['storage_type'] ?? "Google Drive";
      }
    } catch (e) {
      print('Error initializing storage type: $e');
    }
  }

  Future<void> saveChatHistory(Map<String, dynamic> data) async {
    await _initializeStorageType();
    
    if (storageType == "Google Drive") {
      await _saveToGoogleDrive(data);
    } else {
      await _saveToFirestore(data);
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
      final profile = authContext.userCredential.additionalUserInfo?.profile;
      await FirebaseFirestore.instance
          .collection('chat_history')
          .doc('${profile?["sub"]}')
          .set(data);
    } catch (e) {
      print('Error saving chat history to Firestore: $e');
    }
  }

  Future<String?> loadOrCreateChatFile() async {
    await _initializeStorageType();
    
    if (storageType == "Google Drive") {
      return await _loadOrCreateGoogleDriveFile();
    } else {
      return await _loadOrCreateFirestoreFile();
    }
  }

  Future<String?> _loadOrCreateGoogleDriveFile() async {
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
        await _saveToGoogleDrive(initialData);
        
        return createdFile.id;
      }
    } catch (e) {
      print('Error initializing Google Drive file: $e');
      return null;
    }
  }

  Future<String?> _loadOrCreateFirestoreFile() async {
    try {
      final profile = authContext.userCredential.additionalUserInfo?.profile;
      final docRef = FirebaseFirestore.instance
          .collection('chat_history')
          .doc('${profile?["sub"]}');
      
      final doc = await docRef.get();
      if (!doc.exists) {
        // 初期データを保存
        final initialData = {
          'messages': [],
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        };
        await docRef.set(initialData);
      }
      
      return '${profile?["sub"]}';
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
      final profile = authContext.userCredential.additionalUserInfo?.profile;
      final doc = await FirebaseFirestore.instance
          .collection('chat_history')
          .doc('${profile?["sub"]}')
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        if (data?['messages'] != null) {
          return Map<String, dynamic>.from(data!['messages']);
        }
      }
      return null;
    } catch (e) {
      print('Error loading chat history from Firestore: $e');
      return null;
    }
  }
} 