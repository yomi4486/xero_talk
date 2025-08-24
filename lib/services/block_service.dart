import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xero_talk/models/blocked_user.dart';

class BlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'blocked_users';

  // ユーザーをブロックする
  Future<void> blockUser(String blockerId, String blockedId) async {
    // 自分自身をブロックしようとしているかチェック
    if (blockerId == blockedId) {
      throw Exception('自分自身をブロックすることはできません');
    }

    // 既にブロックしているかチェック
    final existingBlock = await _firestore
        .collection(_collection)
        .where('blockerId', isEqualTo: blockerId)
        .where('blockedId', isEqualTo: blockedId)
        .get();

    if (existingBlock.docs.isNotEmpty) {
      throw Exception('このユーザーは既にブロックされています');
    }

    // ブロック関係を作成
    await _firestore.collection(_collection).add({
      'blockerId': blockerId,
      'blockedId': blockedId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ユーザーのブロックを解除する
  Future<void> unblockUser(String blockerId, String blockedId) async {
    final blockSnapshot = await _firestore
        .collection(_collection)
        .where('blockerId', isEqualTo: blockerId)
        .where('blockedId', isEqualTo: blockedId)
        .get();

    if (blockSnapshot.docs.isEmpty) {
      throw Exception('このユーザーはブロックされていません');
    }

    // ブロック関係を削除
    for (var doc in blockSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // ブロックしたユーザー一覧を取得
  Stream<List<BlockedUser>> getBlockedUsers(String blockerId) {
    print('BlockService.getBlockedUsers: blockerId = $blockerId');
    return _firestore
        .collection(_collection)
        .where('blockerId', isEqualTo: blockerId)
        .snapshots()
        .map((snapshot) {
      print('BlockService.getBlockedUsers: snapshot docs length = ${snapshot.docs.length}');
      final blockedUsers = snapshot.docs.map((doc) {
        print('BlockService.getBlockedUsers: doc.id = ${doc.id}, data = ${doc.data()}');
        return BlockedUser.fromFirestore(doc);
      }).toList();
      
      // クライアント側でソート（作成日時の降順）
      blockedUsers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('BlockService.getBlockedUsers: returning ${blockedUsers.length} blocked users');
      return blockedUsers;
    });
  }

  // 特定のユーザーがブロックされているかチェック
  Future<bool> isUserBlocked(String blockerId, String blockedId) async {
    final blockSnapshot = await _firestore
        .collection(_collection)
        .where('blockerId', isEqualTo: blockerId)
        .where('blockedId', isEqualTo: blockedId)
        .get();

    return blockSnapshot.docs.isNotEmpty;
  }

  // 相互にブロックされているかチェック（どちらかがブロックしているか）
  Future<bool> isBlockedByEither(String userId1, String userId2) async {
    final block1 = await isUserBlocked(userId1, userId2);
    final block2 = await isUserBlocked(userId2, userId1);
    
    return block1 || block2;
  }

  // 自分をブロックしているユーザー一覧を取得
  Stream<List<BlockedUser>> getUsersBlockingMe(String blockedId) {
    return _firestore
        .collection(_collection)
        .where('blockedId', isEqualTo: blockedId)
        .snapshots()
        .map((snapshot) {
      final blockedUsers = snapshot.docs.map((doc) => BlockedUser.fromFirestore(doc)).toList();
      
      // クライアント側でソート（作成日時の降順）
      blockedUsers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return blockedUsers;
    });
  }
}
