import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xero_talk/main.dart';
import 'package:xero_talk/services/account_suspension_service.dart';
import 'package:xero_talk/utils/auth_context.dart';

class AccountSuspensionScreen extends StatefulWidget {
  const AccountSuspensionScreen({Key? key}) : super(key: key);

  @override
  _AccountSuspensionScreenState createState() => _AccountSuspensionScreenState();
}

class _AccountSuspensionScreenState extends State<AccountSuspensionScreen> {
  final AccountSuspensionService _suspensionService = AccountSuspensionService();
  bool _isLoading = false;
  bool _confirmationChecked = false;
  String _selectedReason = '休暇のため';
  final TextEditingController _customReasonController = TextEditingController();

  final List<String> _predefinedReasons = [
    '休暇のため',
    '勉強・仕事に集中するため',
    'プライバシーの理由',
    'アプリの使いすぎを防ぐため',
    'その他',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _suspendAccount() async {
    if (!_confirmationChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('一時停止の確認をチェックしてください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String reason = _selectedReason;
    if (_selectedReason == 'その他' && _customReasonController.text.isNotEmpty) {
      reason = _customReasonController.text;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authContext = Provider.of<AuthContext>(context, listen: false);
      
      // アカウントを一時停止
      await _suspensionService.suspendAccount(authContext.id, reason);
      
      // AuthContextのクリーンアップを実行
      await authContext.logout();
      
      if (mounted) {
        // ログイン画面に戻る
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MyHomePage()),
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('アカウントが一時停止されました。再度ログインすることで復旧できます。'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
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
            content: Text('アカウント停止に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 22, 22, 22),
      appBar: AppBar(
        title: const Text(
          'アカウント一時停止',
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
                    'アカウントを一時停止しています...',
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
                  // 説明メッセージ
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      border: Border.all(color: Colors.orange, width: 1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.pause_circle, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'アカウント一時停止について',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'アカウントを一時停止すると、再度ログインするまでアプリを使用できなくなります。データは保持され、いつでも復旧できます。',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 一時停止の効果
                  const Text(
                    '一時停止中の制限',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildSuspensionEffect(
                    Icons.notifications_off,
                    '通知の停止',
                    'すべての通知が停止されます',
                  ),
                  
                  _buildSuspensionEffect(
                    Icons.chat_bubble_outline,
                    'チャットの無効化',
                    '新しいメッセージの送受信ができません',
                  ),
                  
                  _buildSuspensionEffect(
                    Icons.people_outline,
                    'フレンド機能の停止',
                    'フレンド申請の送受信ができません',
                  ),
                  
                  _buildSuspensionEffect(
                    Icons.visibility_off,
                    'プロフィールの非表示',
                    '他のユーザーからあなたが見つけられません',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 停止理由の選択
                  const Text(
                    '停止理由（任意）',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 40, 40, 40),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      children: [
                        ..._predefinedReasons.map((reason) => RadioListTile<String>(
                          value: reason,
                          groupValue: _selectedReason,
                          onChanged: (String? value) {
                            setState(() {
                              _selectedReason = value!;
                            });
                          },
                          title: Text(
                            reason,
                            style: const TextStyle(color: Colors.white),
                          ),
                          activeColor: Colors.orange,
                        )),
                        
                        if (_selectedReason == 'その他') ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _customReasonController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: '理由を入力してください',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.orange),
                              ),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 確認チェックボックス
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 40, 40, 40),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: CheckboxListTile(
                      value: _confirmationChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          _confirmationChecked = value ?? false;
                        });
                      },
                      title: const Text(
                        '上記の内容を理解し、アカウントの一時停止に同意します',
                        style: TextStyle(color: Colors.white),
                      ),
                      checkColor: Colors.white,
                      activeColor: Colors.orange,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // 停止ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmationChecked ? _suspendAccount : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'アカウントを一時停止する',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 復旧方法の説明
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      border: Border.all(color: Colors.blue, width: 1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              '復旧方法',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'アカウントを復旧するには、再度アプリにログインするだけです。すべてのデータとフレンド関係が復元されます。',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSuspensionEffect(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange, size: 24),
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
