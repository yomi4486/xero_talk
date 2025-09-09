import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシーポリシー', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 40, 40, 40),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color.fromARGB(255, 22, 22, 22),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'プライバシーポリシー',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'ユーザー情報の取得・利用目的',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                '本アプリでは、ユーザーの識別のためにSUB（Subject）と呼ばれる一意のID情報のみを取得・利用します。その他の個人情報は取得いたしません。',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const Text(
                '第三者提供について',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                '当アプリは、ユーザーの同意がある場合、または法令に基づく公的機関からの正式な要請があった場合を除き、ユーザー情報を第三者に提供することはありません。',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const Text(
                '外部サービス連携について',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                '本アプリは、サービスの提供・認証のためにFirebaseおよびGoogle認証（GoogleAuth）と連携しています。これら以外の外部サービスとは連携いたしません。',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const Text(
                'お問い合わせ先',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'ご不明な点やご質問がございましたら、下記メールアドレスまでお気軽にお問い合わせください。\n\nsupport@xerotalk.com',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
