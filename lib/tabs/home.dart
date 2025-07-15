import 'package:flutter/material.dart';
import 'package:xero_talk/tabs.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:xero_talk/widgets/chat_list_widget.dart';
import 'package:provider/provider.dart';
import 'package:xero_talk/services/friend_service.dart';
import 'package:xero_talk/models/friend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xero_talk/widgets/user_icon.dart';

String lastMessageId = "";

class chatHome extends StatefulWidget {
  final AsyncSnapshot snapshot;
  const chatHome({Key? key, required this.snapshot}) : super(key: key);
  @override
  _chatHomeState createState() => _chatHomeState();
}

class _chatHomeState extends State<chatHome> with AutomaticKeepAliveClientMixin<chatHome> {
  Map<String, dynamic> userData = {};
  final Color defaultColor = const Color.fromARGB(255, 22, 22, 22);
  final FriendService _friendService = FriendService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Color darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final instance = Provider.of<AuthContext>(context,listen: true);
    final tabsProvider = Provider.of<TabsProvider>(context, listen: true);
    super.build(context);
    return WillPopScope(
      onWillPop: () async => false,
      child:DecoratedBox(                       
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: FractionalOffset.topLeft,
            end: FractionalOffset.bottomRight,
            colors: instance.theme,
            stops: const [0.0, 1.0],
          ),
        ),
        child: Stack(
          children:[
            Scaffold(
              appBar: AppBar(
                centerTitle: false,
                automaticallyImplyLeading: false,
                title: const Text(
                  'メッセージ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  )
                ),
                titleTextStyle: const TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255), fontSize: 20
                ),
                backgroundColor: darkenColor(const Color.fromARGB(255, 68, 68, 68),0.2).withOpacity(.1),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () async {
                  final selectedFriends = await showModalBottomSheet<List<Friend>>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => GroupSelectBottomSheet(
                      friendService: _friendService,
                      userId: instance.id,
                    ),
                  );
                  if (selectedFriends != null && selectedFriends.isNotEmpty) {
                    final memberIds = [
                      instance.id,
                      ...selectedFriends.map((f) => f.senderId == instance.id ? f.receiverId : f.senderId)
                    ];
                    final groupDoc = await FirebaseFirestore.instance.collection('groups').add({
                      'name': '新しいグループ',
                      'members': memberIds,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    final groupSnapshot = await groupDoc.get();
                    final groupData = groupSnapshot.data() as Map<String, dynamic>;
                    final channelInfo = {
                      'type': 'group',
                      'id': groupDoc.id,
                      'name': groupData['name'],
                      'members': groupData['members'],
                      'createdAt': groupData['createdAt'],
                    };
                    tabsProvider.userData = channelInfo;
                    tabsProvider.showChatScreen(id: groupDoc.id);
                  }
                },
                backgroundColor: instance.theme[1],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(128),
                ),
                child: const Icon(
                  Icons.add,
                  color: Color.fromARGB(200, 255, 255, 255),
                ),
              ),
              backgroundColor: Colors.transparent,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none, 
                      children: [
                        ListView(
                          children:[
                            Padding(
                              padding: const EdgeInsets.only(left: 95.0, right: 30.0, top: 30.0, bottom: 30.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // グループ一覧
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('groups')
                                        .where('members', arrayContains: instance.id)
                                        .snapshots(),
                                    builder: (context, groupSnapshot) {
                                      if (groupSnapshot.hasError) {
                                        return Center(child: Text('グループ取得エラー: ${groupSnapshot.error}'));
                                      }
                                      if (!groupSnapshot.hasData) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      final groups = groupSnapshot.data!.docs;
                                      if (groups.isEmpty) {
                                        return Container(); // グループがなければ何も表示しない
                                      }
                                      final parentContext = context;
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ...groups.map((doc) {
                                            final data = doc.data() as Map<String, dynamic>;
                                            return GestureDetector(
                                              onTap: () {
                                                final channelInfo = {
                                                  'type': 'group',
                                                  'id': doc.id,
                                                  'name': data['name'],
                                                  'members': data['members'],
                                                  'createdAt': data['createdAt'],
                                                };
                                                tabsProvider.userData = channelInfo;
                                                tabsProvider.showChatScreen(id: doc.id);
                                              },
                                              onLongPress: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  shape: const RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                                  ),
                                                  builder: (context) {
                                                    return SafeArea(
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          ListTile(
                                                            leading: const Icon(Icons.edit),
                                                            title: const Text('編集'),
                                                            onTap: () {
                                                              Navigator.pop(context); // まずボトムシートを閉じる
                                                              Future.delayed(const Duration(milliseconds: 200), () {
                                                                final TextEditingController nameController = TextEditingController(text: data['name'] ?? '');
                                                                showDialog(
                                                                  context: parentContext,
                                                                  builder: (context) {
                                                                    return AlertDialog(
                                                                      title: const Text('グループ名を編集'),
                                                                      content: TextField(
                                                                        controller: nameController,
                                                                        decoration: const InputDecoration(
                                                                          labelText: 'グループ名',
                                                                        ),
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () {
                                                                            Navigator.pop(context);
                                                                          },
                                                                          child: const Text('キャンセル'),
                                                                        ),
                                                                        ElevatedButton(
                                                                          onPressed: () async {
                                                                            final newName = nameController.text.trim();
                                                                            if (newName.isNotEmpty && newName != data['name']) {
                                                                              await FirebaseFirestore.instance.collection('groups').doc(doc.id).update({'name': newName});
                                                                            }
                                                                            Navigator.pop(context);
                                                                          },
                                                                          child: const Text('保存'),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                );
                                                              });
                                                            },
                                                          ),
                                                          ListTile(
                                                            leading: const Icon(Icons.delete, color: Colors.red),
                                                            title: const Text('削除', style: TextStyle(color: Colors.red)),
                                                            onTap: () async {
                                                              Navigator.pop(context);
                                                              final confirm = await showDialog<bool>(
                                                                context: context,
                                                                builder: (context) => AlertDialog(
                                                                  title: const Text('グループ削除'),
                                                                  content: const Text('本当にこのグループを削除しますか？'),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () => Navigator.pop(context, false),
                                                                      child: const Text('キャンセル'),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed: () => Navigator.pop(context, true),
                                                                      child: const Text('削除', style: TextStyle(color: Colors.red)),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                              if (confirm == true) {
                                                                await FirebaseFirestore.instance.collection('groups').doc(doc.id).delete();
                                                              }
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: ListTile(
                                                leading: CircleAvatar(
                                                  backgroundColor: Colors.white,
                                                  child: Icon(Icons.group, color: Colors.blue),
                                                ),
                                                title: Text(
                                                  data['name'] ?? 'グループ',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                              ),
                                            );
                                          }),
                                        ],
                                      );
                                    },
                                  ),
                                  // フレンド一覧
                                  StreamBuilder<List<Friend>>(
                                    stream: _friendService.getFriends(instance.id),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Center(child: Text('エラーが発生しました:  {snapshot.error}'));
                                      }

                                      if (!snapshot.hasData) {
                                        return const Center(child: CircularProgressIndicator());
                                      }

                                      final friends = snapshot.data!;
                                      if (friends.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            'フレンドがいません',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        );
                                      }

                                      return FutureBuilder<List<Map<String, dynamic>>>(
                                        future: Future.wait(friends.map((friend) async {
                                          final friendId = friend.senderId == instance.id
                                              ? friend.receiverId
                                              : friend.senderId;
                                          // チャットID生成
                                          final ids = [instance.id, friendId]..sort();
                                          final chatId = "${ids[0]}_${ids[1]}";
                                          final doc = await FirebaseFirestore.instance
                                              .collection('chat_history')
                                              .doc(chatId)
                                              .get();
                                          final lastUpdated = doc.data()?['lastUpdated'] ?? 0;
                                          String latestMessageText = '';
                                          final messages = doc.data()?['messages'];
                                          if (messages != null && messages is List && messages.isNotEmpty) {
                                            final sortedMessages = List<Map<String, dynamic>>.from(messages)
                                              ..sort((a, b) => (b['timeStamp'] ?? 0).compareTo(a['timeStamp'] ?? 0));
                                            final latestMessage = sortedMessages.first;
                                            final authorId = latestMessage['author']?.toString() ?? '';
                                            String authorName = '';
                                            if (authorId.isNotEmpty) {
                                              if(authorId != instance.id){
                                                final userDoc = await FirebaseFirestore.instance.collection('user_account').doc(authorId).get();
                                                authorName = userDoc.data()?['display_name']?.toString() ?? authorId;
                                              }else{
                                                authorName = "あなた";
                                              }
                                            }
                                            final content = latestMessage['content']?.toString() ?? '';
                                            latestMessageText = authorName.isNotEmpty ? '$authorName: $content' : content;
                                          }
                                          return {
                                            'friend': friend,
                                            'friendId': friendId,
                                            'lastUpdated': lastUpdated,
                                            'latestMessageText': latestMessageText,
                                          };
                                        }).toList()),
                                        builder: (context, chatSnapshot) {
                                          if (chatSnapshot.hasError) {
                                            return Center(
                                              child: Text(
                                                'An error occurred: ${chatSnapshot.error}',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            );
                                          }
                                          if (!chatSnapshot.hasData) {
                                            return const Center(child: CircularProgressIndicator());
                                          }
                                          final friendData = chatSnapshot.data!;
                                          friendData.sort((a, b) => (b['lastUpdated'] as int).compareTo(a['lastUpdated'] as int));
                                          return Column(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: friendData.map((data) {
                                              final friendId = data['friendId'];
                                              return GestureDetector(
                                                onTap: () {
                                                  tabsProvider.showChatScreen(id: friendId);
                                                },
                                                child: ChatListWidget(
                                                  userId: friendId,
                                                  latestMessageText: data['latestMessageText'] ?? '',
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ]
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: darkenColor(const Color.fromARGB(255, 68, 68, 68),0.2).withOpacity(.2)),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 95.0,
                              ),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.2,
                                height: MediaQuery.of(context).size.height,
                                child: Column(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.all(12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(1000),
                                        child: Container(
                                          color: instance.theme[0],
                                          child: Image.asset(
                                            "assets/images/chat.png",
                                            width: MediaQuery.of(context).size.width * 0.15,
                                          )
                                        ),
                                      )
                                    ),
                                    Container(
                                      margin: const EdgeInsets.all(12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(1000),
                                        child: Image.asset(
                                          "assets/images/logo.png",
                                          width: MediaQuery.of(context).size.width * 0.15,
                                        ),
                                      )
                                    ),
                                    Container(
                                      margin: const EdgeInsets.all(12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(1000),
                                        child: Image.asset(
                                          "assets/images/logo.png",
                                          width: MediaQuery.of(context).size.width * 0.15,
                                        ),
                                      )
                                    ),
                                  ],
                                )
                              ),
                            ),
                          ),
                        ),
                      ]
                    )
                  )
                ],
              )
            ),
          ]
        )
      )
    );
  }
}

class GroupSelectBottomSheet extends StatefulWidget {
  final FriendService friendService;
  final String userId;
  const GroupSelectBottomSheet({required this.friendService, required this.userId, Key? key}) : super(key: key);

  @override
  State<GroupSelectBottomSheet> createState() => _GroupSelectBottomSheetState();
}

class _GroupSelectBottomSheetState extends State<GroupSelectBottomSheet> {
  List<Friend> friends = [];
  Set<Friend> selected = {};

  @override
  void initState() {
    super.initState();
    widget.friendService.getFriends(widget.userId).first.then((f) {
      setState(() => friends = f);
    });
  }

  @override
  Widget build(BuildContext context) {
    final instance = Provider.of<AuthContext>(context, listen: false);
    final height = MediaQuery.of(context).size.height * 0.7;
    final Color backgroundColor = instance.theme[0];
    final List<Color> textColor = instance.getTextColor(backgroundColor);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'グループに追加するフレンドを選択',
                  style: TextStyle(color: textColor[0], fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: friends.map((friend) {
                      final friendId = friend.senderId == widget.userId ? friend.receiverId : friend.senderId;
                      return FutureBuilder<Map<String, dynamic>>(
                        future: widget.friendService.getUserInfo(friendId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return CheckboxListTile(
                              value: selected.contains(friend),
                              title: Text(friendId, style: TextStyle(color: textColor[0])),
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    selected.add(friend);
                                  } else {
                                    selected.remove(friend);
                                  }
                                });
                              },
                              activeColor: textColor[0],
                              checkColor: backgroundColor,
                            );
                          }
                          final userInfo = snapshot.data!;
                          return CheckboxListTile(
                            value: selected.contains(friend),
                            title: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(1000),
                                  child: UserIcon(userId: friendId, size: 32)
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  (userInfo['display_name'] ?? friendId).length > 14
                                    ? (userInfo['display_name'] ?? friendId).substring(0, 12) + '...'
                                    : (userInfo['display_name'] ?? friendId),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(color: textColor[0]),
                                ),
                              ],
                            ),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  selected.add(friend);
                                } else {
                                  selected.remove(friend);
                                }
                              });
                            },
                            activeColor: textColor[0],
                            checkColor: backgroundColor,
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text('キャンセル', style: TextStyle(color: textColor[0])),
              ),
              ElevatedButton(
                onPressed: selected.isNotEmpty ? () => Navigator.pop(context, selected.toList()) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: textColor[0],
                  foregroundColor: backgroundColor,
                ),
                child: Text('グループ作成', style: TextStyle(color: backgroundColor)),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
