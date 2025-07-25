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

// 最適化されたグループリストアイテム
class OptimizedGroupListItem extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const OptimizedGroupListItem({
    Key? key,
    required this.doc,
    required this.data,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ListTile(
        leading: const CircleAvatar(
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
  }
}

// 最適化されたフレンドリスト
class OptimizedFriendsList extends StatefulWidget {
  final List<Friend> friends;
  final String currentUserId;
  final TabsProvider tabsProvider;

  const OptimizedFriendsList({
    Key? key,
    required this.friends,
    required this.currentUserId,
    required this.tabsProvider,
  }) : super(key: key);

  @override
  State<OptimizedFriendsList> createState() => _OptimizedFriendsListState();
}

class _OptimizedFriendsListState extends State<OptimizedFriendsList> with AutomaticKeepAliveClientMixin {
  Map<String, Map<String, dynamic>> _chatData = {};
  bool _isLoading = false;
  static final Map<String, Map<String, dynamic>> _globalChatCache = {};

  // キャッシュクリア機能
  static void clearChatCache() {
    _globalChatCache.clear();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // グローバルキャッシュから初期データを読み込み
    _loadFromCache();
    _loadChatData();
  }

  void _loadFromCache() {
    for (final friend in widget.friends) {
      final friendId = friend.senderId == widget.currentUserId
          ? friend.receiverId
          : friend.senderId;
      
      if (_globalChatCache.containsKey(friendId)) {
        _chatData[friendId] = Map<String, dynamic>.from(_globalChatCache[friendId]!);
      }
    }
    
    if (_chatData.isNotEmpty && mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(OptimizedFriendsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.friends.length != widget.friends.length) {
      _loadFromCache();
      _loadChatData();
    }
  }

  Future<void> _loadChatData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // 各フレンドのチャット履歴を段階的に取得
      for (final friend in widget.friends) {
        final friendId = friend.senderId == widget.currentUserId
            ? friend.receiverId
            : friend.senderId;

        // 既に最新データがある場合はスキップ
        if (_chatData.containsKey(friendId)) {
          final existingData = _chatData[friendId]!;
          // 1分以内のデータは再取得しない
          final cachedTime = existingData['cachedAt'] as int? ?? 0;
          if (DateTime.now().millisecondsSinceEpoch - cachedTime < 60000) {
            continue;
          }
        }

        try {
          final ids = [widget.currentUserId, friendId]..sort();
          final chatId = "${ids[0]}_${ids[1]}";
          final doc = await FirebaseFirestore.instance
              .collection('chat_history')
              .doc(chatId)
              .get();

          final lastUpdated = doc.data()?['lastUpdated'] ?? 0;
          String latestMessageText = '';
          String authorId = '';
          final messages = doc.data()?['messages'];
          
          if (messages != null && messages is List && messages.isNotEmpty) {
            final sortedMessages = List<Map<String, dynamic>>.from(messages)
              ..sort((a, b) => (b['timeStamp'] ?? 0).compareTo(a['timeStamp'] ?? 0));
            final latestMessage = sortedMessages.first;
            authorId = latestMessage['author']?.toString() ?? '';
            latestMessageText = latestMessage['content']?.toString() ?? '';
          }

          // 著者名を取得
          if (authorId.isNotEmpty && latestMessageText.isNotEmpty) {
            if (authorId == widget.currentUserId) {
              latestMessageText = 'あなた: $latestMessageText';
            } else {
              try {
                final userInfo = await FriendService().getUserInfo(authorId);
                final authorName = userInfo['display_name'] ?? authorId;
                latestMessageText = '$authorName: $latestMessageText';
              } catch (e) {
                latestMessageText = '$authorId: $latestMessageText';
              }
            }
          }

          final newData = {
            'friend': friend,
            'friendId': friendId,
            'lastUpdated': lastUpdated,
            'latestMessageText': latestMessageText,
            'cachedAt': DateTime.now().millisecondsSinceEpoch,
          };

          if (mounted) {
            setState(() {
              _chatData[friendId] = newData;
              _globalChatCache[friendId] = Map<String, dynamic>.from(newData);
            });
          }
        } catch (e) {
          // エラーの場合、既存のキャッシュがあればそれを使用
          if (!_chatData.containsKey(friendId)) {
            final fallbackData = {
              'friend': friend,
              'friendId': friendId,
              'lastUpdated': 0,
              'latestMessageText': '',
              'cachedAt': DateTime.now().millisecondsSinceEpoch,
            };
            
            if (mounted) {
              setState(() {
                _chatData[friendId] = fallbackData;
              });
            }
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 即座にフレンドリストを表示（チャットデータがなくても）
    final sortedFriends = widget.friends.map((friend) {
      final friendId = friend.senderId == widget.currentUserId
          ? friend.receiverId
          : friend.senderId;
      return _chatData[friendId] ?? {
        'friend': friend,
        'friendId': friendId,
        'lastUpdated': 0,
        'latestMessageText': '',
      };
    }).toList();

    sortedFriends.sort((a, b) => 
        (b['lastUpdated'] as int).compareTo(a['lastUpdated'] as int));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedFriends.length,
      itemBuilder: (context, index) {
        final data = sortedFriends[index];
        final friendId = data['friendId'];
        final friend = data['friend'] as Friend;
        return OptimizedChatListItem(
          key: ValueKey(friendId),
          friendId: friendId,
          friend: friend,
          latestMessageText: data['latestMessageText'] ?? '',
          lastUpdated: data['lastUpdated'] as int?,
          currentUserId: widget.currentUserId,
          onTap: () {
            final chatId = friendId;
            widget.tabsProvider.showChatScreen(id: chatId);
          },
        );
      },
    );
  }
}

// 最適化されたチャットリストアイテム
class OptimizedChatListItem extends StatefulWidget {
  final String friendId;
  final Friend friend;
  final String latestMessageText;
  final int? lastUpdated;
  final String currentUserId;
  final VoidCallback onTap;

  const OptimizedChatListItem({
    Key? key,
    required this.friendId,
    required this.friend,
    required this.latestMessageText,
    required this.lastUpdated,
    required this.currentUserId,
    required this.onTap,
  }) : super(key: key);

  @override
  State<OptimizedChatListItem> createState() => _OptimizedChatListItemState();
}

class _OptimizedChatListItemState extends State<OptimizedChatListItem> with AutomaticKeepAliveClientMixin {
  String? _displayName;
  static final Map<String, String> _userDisplayNameCache = {};

  // キャッシュクリア機能
  static void clearUserDisplayNameCache() {
    _userDisplayNameCache.clear();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // キャッシュから初期表示名を取得
    _displayName = _userDisplayNameCache[widget.friendId] ?? widget.friendId;
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      // FriendServiceのキャッシュを活用
      final userInfo = await FriendService().getUserInfo(widget.friendId);
      final displayName = userInfo['display_name'] ?? widget.friendId;
      
      if (mounted && displayName != _displayName) {
        setState(() {
          _displayName = displayName;
          _userDisplayNameCache[widget.friendId] = displayName;
        });
      } else if (mounted && !_userDisplayNameCache.containsKey(widget.friendId)) {
        // キャッシュに保存
        _userDisplayNameCache[widget.friendId] = displayName;
      }
    } catch (e) {
      if (mounted && _displayName == widget.friendId) {
        // エラーの場合でもキャッシュがあれば使用しない
        setState(() {
          _displayName = widget.friendId;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // キャッシュされた情報またはデフォルト情報を表示
    return GestureDetector(
      onTap: widget.onTap,
      child: ChatListWidget(
        userId: widget.friendId,
        displayName: _displayName ?? widget.friendId,
        currentUserId: widget.currentUserId,
        latestMessageText: widget.latestMessageText,
        lastUpdated: widget.lastUpdated,
      ),
    );
  }
}

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
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: FractionalOffset.topLeft,
            end: FractionalOffset.bottomRight,
            colors: instance.theme,
            stops: const [0.0, 1.0],
          ),
        ),
        child: Scaffold(
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
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
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
                                      
                                      // データがない場合も空のコンテナを表示（ローディングは表示しない）
                                      final groups = groupSnapshot.hasData ? groupSnapshot.data!.docs : <QueryDocumentSnapshot>[];
                                      
                                      if (groups.isEmpty) {
                                        return Container(); // グループがなければ何も表示しない
                                      }
                                      final parentContext = context;
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ...groups.map((doc) {
                                            final data = doc.data() as Map<String, dynamic>;
                                            return OptimizedGroupListItem(
                                              key: ValueKey(doc.id),
                                              doc: doc,
                                              data: data,
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
                                        return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
                                      }

                                      // データがない場合は空リストとして扱う（ローディングは表示しない）
                                      final friends = snapshot.hasData ? snapshot.data! : <Friend>[];
                                      
                                      if (friends.isEmpty && snapshot.hasData) {
                                        return const Center(
                                          child: Text(
                                            'フレンドがいません',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        );
                                      }

                                      // 空のフレンドリストでもウィジェットを表示
                                      return OptimizedFriendsList(
                                        friends: friends,
                                        currentUserId: instance.id,
                                        tabsProvider: tabsProvider,
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
              ),
            ],
          ),
        ),
      ),
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
