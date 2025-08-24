import 'package:cloud_firestore/cloud_firestore.dart';

class BlockedUser {
  final String id;
  final String blockerId; // ブロックした人
  final String blockedId; // ブロックされた人
  final DateTime createdAt;

  BlockedUser({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    required this.createdAt,
  });

  factory BlockedUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BlockedUser(
      id: doc.id,
      blockerId: data['blockerId'] ?? '',
      blockedId: data['blockedId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blockerId': blockerId,
      'blockedId': blockedId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
