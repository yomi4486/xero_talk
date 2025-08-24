import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AccountDeletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// アカウントを完全に削除する
  Future<void> deleteAccount(String userId) async {
    print('AccountDeletionService: Starting account deletion for userId: $userId');
    
    try {
      // 1. フレンド関係を削除
      await _deleteUserFriendships(userId);
      
      // 2. ブロック関係を削除
      await _deleteUserBlocks(userId);
      
      // 3. チャットデータを削除
      await _deleteUserChats(userId);
      
      // 4. FCMトークンを削除
      await _deleteFCMToken(userId);
      
      // 5. ユーザーアカウント情報を削除
      await _deleteUserAccount(userId);
      
      // 6. Firebase Storageのユーザーファイルを削除
      await _deleteUserFiles(userId);
      
      // 7. 最後にFirebase Authenticationからユーザーを削除
      await _deleteAuthUser();
      
      print('AccountDeletionService: Account deletion completed successfully');
      
    } catch (e) {
      print('AccountDeletionService: Error during account deletion: $e');
      throw Exception('アカウント削除中にエラーが発生しました: ${e.toString()}');
    }
  }

  /// フレンド関係を削除
  Future<void> _deleteUserFriendships(String userId) async {
    print('AccountDeletionService: Deleting user friendships');
    
    // 自分が送信者のフレンド関係を削除
    final sentRequests = await _firestore
        .collection('friends')
        .where('senderId', isEqualTo: userId)
        .get();
    
    for (var doc in sentRequests.docs) {
      await doc.reference.delete();
    }
    
    // 自分が受信者のフレンド関係を削除
    final receivedRequests = await _firestore
        .collection('friends')
        .where('receiverId', isEqualTo: userId)
        .get();
    
    for (var doc in receivedRequests.docs) {
      await doc.reference.delete();
    }
    
    print('AccountDeletionService: User friendships deleted');
  }

  /// ブロック関係を削除
  Future<void> _deleteUserBlocks(String userId) async {
    print('AccountDeletionService: Deleting user blocks');
    
    // 自分がブロックしたユーザーの関係を削除
    final blockedByUser = await _firestore
        .collection('blocked_users')
        .where('blockerId', isEqualTo: userId)
        .get();
    
    for (var doc in blockedByUser.docs) {
      await doc.reference.delete();
    }
    
    // 自分をブロックしているユーザーの関係を削除
    final blockingUser = await _firestore
        .collection('blocked_users')
        .where('blockedId', isEqualTo: userId)
        .get();
    
    for (var doc in blockingUser.docs) {
      await doc.reference.delete();
    }
    
    print('AccountDeletionService: User blocks deleted');
  }

  /// チャットデータを削除
  Future<void> _deleteUserChats(String userId) async {
    print('AccountDeletionService: Deleting user chats');
    
    try {
      // ユーザーが参加しているチャットルームを検索
      final chatRooms = await _firestore
          .collection('chat_room')
          .where('members', arrayContains: userId)
          .get();
      
      for (var chatRoom in chatRooms.docs) {
        final chatRoomId = chatRoom.id;
        final members = List<String>.from(chatRoom.data()['members'] ?? []);
        
        if (members.length <= 2) {
          // 1対1のチャットの場合、チャットルーム全体を削除
          await _deleteChatRoom(chatRoomId);
        } else {
          // グループチャットの場合、メンバーリストからユーザーを削除
          members.remove(userId);
          await chatRoom.reference.update({'members': members});
          
          // このユーザーのメッセージを削除またはマスキング
          await _maskUserMessagesInChat(chatRoomId, userId);
        }
      }
      
      print('AccountDeletionService: User chats processed');
    } catch (e) {
      print('AccountDeletionService: Error deleting chats: $e');
      // チャット削除のエラーは警告として扱い、処理を続行
    }
  }

  /// チャットルーム全体を削除
  Future<void> _deleteChatRoom(String chatRoomId) async {
    // メッセージを削除
    final messages = await _firestore
        .collection('chat_room')
        .doc(chatRoomId)
        .collection('messages')
        .get();
    
    for (var message in messages.docs) {
      await message.reference.delete();
    }
    
    // チャットルームを削除
    await _firestore.collection('chat_room').doc(chatRoomId).delete();
  }

  /// 特定ユーザーのメッセージをマスキング
  Future<void> _maskUserMessagesInChat(String chatRoomId, String userId) async {
    final messages = await _firestore
        .collection('chat_room')
        .doc(chatRoomId)
        .collection('messages')
        .where('sender', isEqualTo: userId)
        .get();
    
    for (var message in messages.docs) {
      await message.reference.update({
        'message': '[削除されたユーザーのメッセージ]',
        'sender': '[削除済みユーザー]',
        'deleted': true,
      });
    }
  }

  /// FCMトークンを削除
  Future<void> _deleteFCMToken(String userId) async {
    print('AccountDeletionService: Deleting FCM token');
    
    try {
      await _firestore.collection('fcm_token').doc(userId).delete();
      print('AccountDeletionService: FCM token deleted');
    } catch (e) {
      print('AccountDeletionService: Error deleting FCM token: $e');
      // FCM トークンの削除エラーは警告として扱う
    }
  }

  /// ユーザーアカウント情報を削除
  Future<void> _deleteUserAccount(String userId) async {
    print('AccountDeletionService: Deleting user account document');
    
    await _firestore.collection('user_account').doc(userId).delete();
    print('AccountDeletionService: User account document deleted');
  }

  /// Firebase Storageのユーザーファイルを削除
  Future<void> _deleteUserFiles(String userId) async {
    print('AccountDeletionService: Deleting user files from Storage');
    
    try {
      // ユーザーのアイコン画像を削除
      final iconRef = _storage.ref().child('user_icons/$userId');
      await iconRef.delete();
      
      // その他のユーザー関連ファイルがあれば削除
      final userFolderRef = _storage.ref().child('users/$userId');
      final items = await userFolderRef.listAll();
      
      for (var item in items.items) {
        await item.delete();
      }
      
      print('AccountDeletionService: User files deleted from Storage');
    } catch (e) {
      print('AccountDeletionService: Error deleting user files: $e');
      // ストレージファイルの削除エラーは警告として扱う
    }
  }

  /// Firebase Authenticationからユーザーを削除
  Future<void> _deleteAuthUser() async {
    print('AccountDeletionService: Deleting Firebase Auth user');
    
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
      print('AccountDeletionService: Firebase Auth user deleted');
    } else {
      throw Exception('認証されたユーザーが見つかりません');
    }
  }

  /// アカウント削除前の確認用データ取得
  Future<Map<String, dynamic>> getAccountDeletionSummary(String userId) async {
    final summary = <String, dynamic>{};
    
    try {
      // フレンド数を取得
      final friends = await _firestore
          .collection('friends')
          .where('status', isEqualTo: 'accepted')
          .where(Filter.or(
            Filter('senderId', isEqualTo: userId),
            Filter('receiverId', isEqualTo: userId),
          ))
          .get();
      summary['friendsCount'] = friends.docs.length;
      
      // ブロック数を取得
      final blocks = await _firestore
          .collection('blocked_users')
          .where('blockerId', isEqualTo: userId)
          .get();
      summary['blockedUsersCount'] = blocks.docs.length;
      
      // チャット数を取得
      final chats = await _firestore
          .collection('chat_room')
          .where('members', arrayContains: userId)
          .get();
      summary['chatRoomsCount'] = chats.docs.length;
      
    } catch (e) {
      print('Error getting account summary: $e');
    }
    
    return summary;
  }
}
