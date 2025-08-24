import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xero_talk/models/friend.dart';
import 'package:xero_talk/services/block_service.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'friends';
  final BlockService _blockService = BlockService();
  
  // ユーザー情報のキャッシュ
  static final Map<String, Map<String, dynamic>> _userInfoCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // ユーザー情報を取得（キャッシュ付き）
  Future<Map<String, dynamic>> getUserInfo(String userId) async {
    // キャッシュをチェック
    if (_userInfoCache.containsKey(userId)) {
      final timestamp = _cacheTimestamps[userId];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheExpiry) {
        return _userInfoCache[userId]!;
      }
    }

    // キャッシュにないか期限切れの場合、Firestoreから取得
    final doc = await _firestore.collection('user_account').doc(userId).get();
    Map<String, dynamic> userInfo;
    if (!doc.exists) {
      userInfo = {
        'name': 'Unknown User',
        'display_name': 'Unknown User',
      };
    } else {
      userInfo = doc.data() ?? {
        'name': 'Unknown User',
        'display_name': 'Unknown User',
      };
    }

    // キャッシュに保存
    _userInfoCache[userId] = userInfo;
    _cacheTimestamps[userId] = DateTime.now();

    return userInfo;
  }

  // キャッシュをクリア（必要に応じて）
  static void clearUserInfoCache() {
    _userInfoCache.clear();
    _cacheTimestamps.clear();
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

    // ブロック関係をチェック
    final isBlocked = await _blockService.isBlockedByEither(senderId, receiverId);
    if (isBlocked) {
      throw Exception('このユーザーとはフレンド申請を送受信できません');
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

  // フレンド一覧を取得（ブロックされていないユーザーのみ）
  Stream<List<Friend>> getFriends(String userId) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: FriendStatus.accepted.toString().split('.').last)
        .where(Filter.or(
          Filter('senderId', isEqualTo: userId),
          Filter('receiverId', isEqualTo: userId),
        ))
        .snapshots()
        .asyncMap((snapshot) async {
      List<Friend> friends = [];
      for (var doc in snapshot.docs) {
        final friend = Friend.fromFirestore(doc);
        final otherUserId = friend.senderId == userId ? friend.receiverId : friend.senderId;
        
        // ブロック関係をチェック
        final isBlocked = await _blockService.isBlockedByEither(userId, otherUserId);
        if (!isBlocked) {
          friends.add(friend);
        }
      }
      return friends;
    });
  }

  // 保留中のフレンド申請を取得（ブロックされていないユーザーのみ）
  Stream<List<Friend>> getPendingRequests(String userId) {
    return _firestore
        .collection(_collection)
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: FriendStatus.pending.toString().split('.').last)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Friend> requests = [];
      for (var doc in snapshot.docs) {
        final request = Friend.fromFirestore(doc);
        
        // ブロック関係をチェック
        final isBlocked = await _blockService.isBlockedByEither(userId, request.senderId);
        if (!isBlocked) {
          requests.add(request);
        }
      }
      return requests;
    });
  }

  // フレンド関係を解除
  Future<void> removeFriend(String requestId) async {
    await _firestore.collection(_collection).doc(requestId).delete();
  }
} 