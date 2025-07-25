import 'package:flutter/material.dart';
import 'package:xero_talk/widgets/user_icon.dart';
import '../utils/auth_context.dart';

final AuthContext instance = AuthContext();

class ChatListWidget extends StatelessWidget {
  final String userId;
  final String? latestMessageText;
  final int? lastUpdated;
  final String displayName;
  final String currentUserId;
  
  const ChatListWidget({
    Key? key, 
    required this.userId, 
    required this.displayName,
    required this.currentUserId,
    this.latestMessageText, 
    this.lastUpdated
  }) : super(key: key);

  String timeAgo(int? lastUpdated) {
    if (lastUpdated == null) return '';
    final now = DateTime.now();
    final updated = DateTime.fromMillisecondsSinceEpoch(lastUpdated);
    final diff = now.difference(updated);
    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${diff.inDays}日前';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color.fromARGB(0, 255, 255, 255)),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2000000),
          child: UserIcon(userId: userId, size: MediaQuery.of(context).size.height * 0.05)
        ),
        Container(
            margin: const EdgeInsets.only(left: 10),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (userId == currentUserId ? "$displayName (自分)" : displayName),
                        style: const TextStyle(
                          color: Color.fromARGB(200, 255, 255, 255),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "・${timeAgo(lastUpdated)}",
                        style: const TextStyle(
                          color: Color.fromARGB(120, 255, 255, 255),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (latestMessageText != null && latestMessageText!.isNotEmpty)
                    SizedBox(
                      child: Text(
                        latestMessageText!,
                        style: const TextStyle(
                          color: Color.fromARGB(120, 255, 255, 255),
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ])),
      ]),
    );
  }
}
