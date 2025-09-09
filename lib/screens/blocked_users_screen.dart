import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xero_talk/models/blocked_user.dart';
import 'package:xero_talk/services/block_service.dart';
import 'package:xero_talk/services/friend_service.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:xero_talk/widgets/user_icon.dart';

class BlockedUsersScreen extends StatelessWidget {
  final BlockService _blockService = BlockService();
  final FriendService _friendService = FriendService();

  BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authContext = Provider.of<AuthContext>(context);
    final userId = authContext.id;
    
    print('BlockedUsersScreen: userId = $userId');

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 22, 22, 22),
      appBar: AppBar(
        title: const Text(
          'ブロック済みユーザー',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 40, 40, 40),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [],
      ),
      body: StreamBuilder<List<BlockedUser>>(
        stream: _blockService.getBlockedUsers(userId),
        builder: (context, snapshot) {
          print('BlockedUsersScreen: connectionState = ${snapshot.connectionState}');
          print('BlockedUsersScreen: hasError = ${snapshot.hasError}');
          if (snapshot.hasError) {
            print('BlockedUsersScreen: error = ${snapshot.error}');
          }
          print('BlockedUsersScreen: hasData = ${snapshot.hasData}');
          if (snapshot.hasData) {
            print('BlockedUsersScreen: data length = ${snapshot.data!.length}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'エラーが発生しました',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'データベースの設定を確認してください',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // 画面を再読み込み
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlockedUsersScreen(),
                        ),
                      );
                    },
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.block,
                    color: Colors.grey,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'ブロック済みユーザーはいません',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final blockedUsers = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              final blockedUser = blockedUsers[index];
              
              return FutureBuilder<Map<String, dynamic>>(
                future: _friendService.getUserInfo(blockedUser.blockedId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const Card(
                      color: Color.fromARGB(255, 40, 40, 40),
                      child: ListTile(
                        leading: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                        title: Text(
                          'Loading...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }

                  final userInfo = userSnapshot.data!;
                  final userName = userInfo['name'] ?? 'Unknown User';
                  final displayName = userInfo['display_name'] ?? userName;

                  return Card(
                    color: const Color.fromARGB(255, 40, 40, 40),
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      leading: UserIcon(
                        userId: blockedUser.blockedId,
                        size: 40,
                      ),
                      title: Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@$userName',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ブロック日時: ${_formatDate(blockedUser.createdAt)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _showUnblockDialog(
                          context,
                          userId,
                          blockedUser.blockedId,
                          displayName,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('ブロック解除'),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showUnblockDialog(
    BuildContext context,
    String blockerId,
    String blockedId,
    String userName,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 40, 40, 40),
          title: const Text(
            'ブロック解除',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '$userName のブロックを解除しますか？\n\nブロックを解除すると、このユーザーから再びフレンド申請やメッセージを受け取る可能性があります。',
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'キャンセル',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _blockService.unblockUser(blockerId, blockedId);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$userName のブロックを解除しました'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('エラー: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'ブロック解除',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
