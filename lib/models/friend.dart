import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendStatus {
  pending,
  accepted,
  rejected
}

class Friend {
  final String id;
  final String senderId;
  final String receiverId;
  final FriendStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Friend({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Friend.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Friend(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      status: FriendStatus.values.firstWhere(
        (e) => e.toString() == 'FriendStatus.${data['status']}',
        orElse: () => FriendStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
} 