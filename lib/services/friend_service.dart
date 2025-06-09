import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xero_talk/models/friend.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'friends';

  // ユーザー情報を取得
  Future<Map<String, dynamic>> getUserInfo(String userId) async {
    final doc = await _firestore.collection('user_account').doc(userId).get();
    if (!doc.exists) {
      return {
        'name': 'Unknown User',
        'display_name': 'Unknown User',
      };
    }
    return doc.data() ?? {
      'name': 'Unknown User',
      'display_name': 'Unknown User',
    };
  }

  // ユーザー名からユーザーIDを検索
  Future<String?> findUserIdByUsername(String username) async {
    final querySnapshot = await _firestore
        .collection('user_account')
        .where('name', isEqualTo: username)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return querySnapshot.docs.first.id;
  }

  // フレンド申請を送信
  Future<void> sendFriendRequest(String senderId, String receiverUsername) async {
    // ユーザー名からユーザーIDを検索
    final receiverId = await findUserIdByUsername(receiverUsername);
    if (receiverId == null) {
      throw Exception('指定されたユーザー名が見つかりません');
    }

    // 自分自身への申請を防ぐ
    if (senderId == receiverId) {
      throw Exception('自分自身にフレンド申請を送ることはできません');
    }

    // 既存の申請がないか確認
    final existingRequest = await _firestore
        .collection(_collection)
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .get();

    if (existingRequest.docs.isNotEmpty) {
      throw Exception('既にフレンド申請を送信しています');
    }

    // 新しい申請を作成
    await _firestore.collection(_collection).add({
      'senderId': senderId,
      'receiverId': receiverId,
      'status': FriendStatus.pending.toString().split('.').last,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // フレンド申請を承認
  Future<void> acceptFriendRequest(String requestId) async {
    await _firestore.collection(_collection).doc(requestId).update({
      'status': FriendStatus.accepted.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // フレンド申請を拒否
  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore.collection(_collection).doc(requestId).update({
      'status': FriendStatus.rejected.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // フレンド一覧を取得
  Stream<List<Friend>> getFriends(String userId) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: FriendStatus.accepted.toString().split('.').last)
        .where(Filter.or(
          Filter('senderId', isEqualTo: userId),
          Filter('receiverId', isEqualTo: userId),
        ))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Friend.fromFirestore(doc)).toList();
    });
  }

  // 保留中のフレンド申請を取得
  Stream<List<Friend>> getPendingRequests(String userId) {
    return _firestore
        .collection(_collection)
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: FriendStatus.pending.toString().split('.').last)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Friend.fromFirestore(doc)).toList();
    });
  }

  // フレンド関係を解除
  Future<void> removeFriend(String requestId) async {
    await _firestore.collection(_collection).doc(requestId).delete();
  }
} 