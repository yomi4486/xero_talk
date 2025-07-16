import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xero_talk/widgets/user_icon.dart';
import '../utils/auth_context.dart';

final AuthContext instance = AuthContext();

class ChatListWidget extends StatefulWidget {
  final String userId;
  final String? latestMessageText;
  final int? lastUpdated;
  ChatListWidget({Key? key, required this.userId, this.latestMessageText, this.lastUpdated}) : super(key: key);

  @override
  _chatLiatWidgetState createState() => _chatLiatWidgetState();
}

class _chatLiatWidgetState extends State<ChatListWidget> {
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
          child: UserIcon(userId: widget.userId, size: MediaQuery.of(context).size.height * 0.05)
        ),
        FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('user_account')
                .doc(widget.userId)
                .get(),
            builder: (context, snapshot) {
              late String displayName = "";
              if (snapshot.connectionState == ConnectionState.waiting) {
                displayName = "";
              } else if (snapshot.hasError) {
                displayName = "";
              } else if (snapshot.hasData) {
                displayName = (snapshot.data?.data() as Map<String, dynamic>)["display_name"] ?? "No description";
              } else {
                displayName = "";
              }
              return Container(
                  margin: const EdgeInsets.only(left: 10),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                (widget.userId == instance.id ? "$displayName (自分)" : displayName),
                                style: const TextStyle(
                                  color: Color.fromARGB(200, 255, 255, 255),
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              timeAgo(widget.lastUpdated),
                              style: const TextStyle(
                                color: Color.fromARGB(120, 255, 255, 255),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (widget.latestMessageText != null && widget.latestMessageText!.isNotEmpty)
                          SizedBox(
                            child: Text(
                              widget.latestMessageText!,
                              style: const TextStyle(
                                color: Color.fromARGB(120, 255, 255, 255),
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ]));
            }),
      ]),
    );
  }
}
