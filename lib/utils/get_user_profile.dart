import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestoreから指定したIDのユーザープロファイルを取得
Future<Map<String, dynamic>> getUserProfile(String id) async {
  try {
    // まずユーザーとして探す
    final userDoc = await FirebaseFirestore.instance.collection('user_account').doc(id).get();
    if (userDoc.exists) {
      final userProfile = userDoc.data() as Map<String, dynamic>;
      userProfile["id"] = id;
      return userProfile;
    }
    // ユーザーでなければグループとして探す
    final groupDoc = await FirebaseFirestore.instance.collection('groups').doc(id).get();
    if (groupDoc.exists) {
      final groupData = groupDoc.data() as Map<String, dynamic>;
      return {
        'id': id,
        'type': 'group',
        'name': groupData['name'] ?? 'グループ',
        'members': groupData['members'] ?? [],
        'createdAt': groupData['createdAt'],
      };
    }
    // どちらもなければunknown
    return {
      'id': '0',
      'name': 'unknown',
      'display_name': 'unknown'
    };
  } catch (e) {
    return {
      'id': '0',
      'name': 'unknown',
      'display_name': 'unknown'
    };
  }
}
