import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xero_talk/main.dart';
import 'package:xero_talk/services/account_deletion_service.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({Key? key}) : super(key: key);

  @override
  _AccountDeletionScreenState createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  final AccountDeletionService _accountDeletionService = AccountDeletionService();
  bool _isLoading = false;
  bool _confirmationChecked = false;
  Map<String, dynamic>? _deletionSummary;

  @override
  void initState() {
    super.initState();
    _loadDeletionSummary();
  }

  Future<void> _loadDeletionSummary() async {
    final authContext = Provider.of<AuthContext>(context, listen: false);
    try {
      final summary = await _accountDeletionService.getAccountDeletionSummary(authContext.id);
      setState(() {
        _deletionSummary = summary;
      });
    } catch (e) {
      print('Error loading deletion summary: $e');
    }
  }

  Future<void> _deleteAccount() async {
    if (!_confirmationChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('削除の確認をチェックしてください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authContext = Provider.of<AuthContext>(context, listen: false);
      
      // アカウント削除を実行
      await _accountDeletionService.deleteAccount(authContext.id);
      
      // AuthContextのクリーンアップを実行
      await authContext.cleanupForAccountDeletion();
      
      // ローカルデータをクリア
      await _clearLocalData();
      
      if (mounted) {
        // ログイン画面に戻る
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MyHomePage()),
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('アカウントが削除されました'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('アカウント削除に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _clearLocalData() async {
    try {
      // Hiveボックスをクリア
      final imageCache = await Hive.openBox('imageCache');
      await imageCache.clear();
      
      final userInfo = await Hive.openBox('userInfo');
      await userInfo.clear();
      
      // Google Sign-Inからサインアウト
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      
      // AuthContextをリセット
      final authContext = Provider.of<AuthContext>(context, listen: false);
      await authContext.logout();
      
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 22, 22, 22),
      appBar: AppBar(
        title: const Text(
          'アカウント削除',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 40, 40, 40),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'アカウントを削除しています...\nしばらくお待ちください',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 警告メッセージ
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red, width: 1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              '重要な警告',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'この操作は取り消すことができません。アカウントを削除すると以下のデータが完全に削除されます：',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 削除される内容の説明
                  const Text(
                    '削除される内容',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildDeletionItem(
                    Icons.person,
                    'プロフィール情報',
                    'ニックネーム、ユーザーID、自己紹介、アイコン画像',
                  ),
                  
                  _buildDeletionItem(
                    Icons.people,
                    'フレンド関係',
                    _deletionSummary != null 
                        ? '${_deletionSummary!['friendsCount'] ?? 0}人のフレンドとの関係'
                        : 'すべてのフレンド関係',
                  ),
                  
                  _buildDeletionItem(
                    Icons.chat,
                    'チャット履歴',
                    _deletionSummary != null 
                        ? '${_deletionSummary!['chatRoomsCount'] ?? 0}個のチャットルーム'
                        : 'すべてのチャット履歴',
                  ),
                  
                  _buildDeletionItem(
                    Icons.block,
                    'ブロック設定',
                    _deletionSummary != null 
                        ? '${_deletionSummary!['blockedUsersCount'] ?? 0}人のブロック設定'
                        : 'すべてのブロック設定',
                  ),
                  
                  _buildDeletionItem(
                    Icons.notifications,
                    '通知設定',
                    'FCMトークンと通知設定',
                  ),
                  
                  _buildDeletionItem(
                    Icons.cloud,
                    'ストレージデータ',
                    'アップロードした画像やファイル',
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // 確認チェックボックス
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 40, 40, 40),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: _confirmationChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              _confirmationChecked = value ?? false;
                            });
                          },
                          title: const Text(
                            '上記の内容を理解し、アカウントの完全削除に同意します',
                            style: TextStyle(color: Colors.white),
                          ),
                          checkColor: Colors.white,
                          activeColor: Colors.red,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // 削除ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmationChecked ? _deleteAccount : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'アカウントを完全に削除する',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 注意事項
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      border: Border.all(color: Colors.orange, width: 1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Text(
                      '注意: この操作は即座に実行され、元に戻すことはできません。削除後は同じユーザーIDでの再登録もできません。',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDeletionItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
