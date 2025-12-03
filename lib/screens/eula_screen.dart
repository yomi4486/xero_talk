import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EulaScreen extends StatefulWidget {
  const EulaScreen({super.key});

  @override
  State<EulaScreen> createState() => _EulaScreenState();
}

class _EulaScreenState extends State<EulaScreen> {
  bool _agreeing = false;

  Future<void> _accept() async {
    setState(() => _agreeing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('user_account')
            .doc(user.uid)
            .set({'eula_agreed': true}, SetOptions(merge: true));
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _agreeing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('同意エラー: ${e.toString()}')),
      );
    }
  }

  void _decline() {
    // Decline: return false to caller
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('利用規約（EULA）'),
        backgroundColor: const Color.fromARGB(255, 40, 40, 40),
      ),
      backgroundColor: const Color.fromARGB(255, 22, 22, 22),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'このアプリはユーザーが生成したコンテンツ（テキスト、画像、音声など）を許可しています。\n\n'
                  '以下の内容に同意してください:\n\n'
                  '1) 他者への暴力、差別、わいせつ、嫌がらせ、脅迫を含む投稿は禁止されています。\n'
                  '2) 違法行為や著作権を侵害する行為を助長する投稿は禁止されています。\n'
                  '3) 規約違反のコンテンツを見つけた場合はフラグ機能で報告してください。運営は報告を受けて対処します。\n'
                  '4) 本サービスはユーザーコンテンツを監視しますが、すべてを事前に確認することはできません。\n\n'
                  '違反があった場合、アカウント停止や削除などの措置を行う場合があります。\n\n'
                  'この利用規約に同意する場合は「同意する」を押してください。同意しない場合はアプリを利用できません。',
                  style: TextStyle(color: Colors.white, height: 1.6),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      onPressed: _decline,
                      child: const Text('同意しない', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _agreeing ? null : _accept,
                      child: _agreeing
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('同意する'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
