import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xero_talk/models/friend.dart';
import 'package:xero_talk/screens/add_friend_screen.dart';
import 'package:xero_talk/services/friend_service.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:xero_talk/widgets/user_icon.dart';

class FriendsScreen extends StatelessWidget {
  final FriendService _friendService = FriendService();

  FriendsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authContext = Provider.of<AuthContext>(context);
    final userId = authContext.id;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 22, 22, 22),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFriendScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: const Color.fromARGB(255, 40, 40, 40),
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.white,
              tabs: [
                const Tab(text: 'フレンド一覧'),
                StreamBuilder<List<Friend>>(
                  stream: _friendService.getPendingRequests(userId),
                  builder: (context, snapshot) {
                    final requestCount = snapshot.hasData ? snapshot.data!.length : 0;
                    return Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('申請一覧'),
                          if (requestCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                requestCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // フレンド一覧
                StreamBuilder<List<Friend>>(
                  stream: _friendService.getFriends(userId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
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

                    return ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        final friendId = friend.senderId == userId
                            ? friend.receiverId
                            : friend.senderId;

                        return FutureBuilder<Map<String, dynamic>>(
                          future: _friendService.getUserInfo(friendId),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) {
                              return const ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Color.fromARGB(255, 40, 40, 40),
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(
                                  'Loading...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            final userInfo = userSnapshot.data!;
                            return ListTile(
                              leading: ClipRRect(
                                // アイコン表示（角丸）
                                borderRadius: BorderRadius.circular(1000),
                                child: UserIcon(userId: friendId),
                              ),
                              title: Text(
                                userInfo['display_name'] ?? 'Unknown User',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '@${userInfo['name']}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.white),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: const Color.fromARGB(255, 40, 40, 40),
                                      title: const Text(
                                        'フレンド解除',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: const Text(
                                        'フレンドを解除しますか？',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('キャンセル'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _friendService.removeFriend(friend.id);
                                            Navigator.pop(context);
                                          },
                                          child: const Text('解除'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                // 申請一覧
                StreamBuilder<List<Friend>>(
                  stream: _friendService.getPendingRequests(userId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final requests = snapshot.data!;
                    if (requests.isEmpty) {
                      return const Center(
                        child: Text(
                          '保留中の申請はありません',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return FutureBuilder<Map<String, dynamic>>(
                          future: _friendService.getUserInfo(request.senderId),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) {
                              return const ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Color.fromARGB(255, 40, 40, 40),
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(
                                  'Loading...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            final userInfo = userSnapshot.data!;
                            return ListTile(
                              leading: ClipRRect(
                                // アイコン表示（角丸）
                                borderRadius: BorderRadius.circular(1000),
                                child: UserIcon(userId: request.senderId),
                              ),
                              title: Text(
                                userInfo['display_name'] ?? 'Unknown User',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '@${userInfo['name']}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () {
                                      _friendService.acceptFriendRequest(request.id);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () {
                                      _friendService.rejectFriendRequest(request.id);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
} 