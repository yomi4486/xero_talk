import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/auth_context.dart';

final AuthContext instance = AuthContext();

class ChatListWidget extends StatefulWidget {
  final String userId;
  ChatListWidget({Key? key, required this.userId}) : super(key: key);

  @override
  _chatLiatWidgetState createState() => _chatLiatWidgetState();
}

class _chatLiatWidgetState extends State<ChatListWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color.fromARGB(0, 255, 255, 255)),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        ClipRRect(
          // アイコン表示（角丸）
          borderRadius: BorderRadius.circular(2000000),
          child: Image.network(
            "https://${dotenv.env['BASE_URL']}/geticon?user_id=${widget.userId}",
            width: MediaQuery.of(context).size.height * 0.05,
            loadingBuilder: (BuildContext context, Widget child,
                ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) {
                return child;
              } else {
                return Image.asset(
                  'assets/images/default_user_icon.png',
                  width: MediaQuery.of(context).size.height * 0.05,
                );
              }
            },
          ),
        ),
        FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('user_account') // コレクションID
                .doc(widget.userId) // ドキュメントID
                .get(),
            builder: (context, snapshot) {
              late String displayName = "";
              if (snapshot.connectionState == ConnectionState.waiting) {
                displayName = "";
              } else if (snapshot.hasError) {
                displayName = "";
              } else if (snapshot.hasData) {
                // successful
                displayName = (snapshot.data?.data()
                        as Map<String, dynamic>)["display_name"] ??
                    "No description";
              } else {
                displayName = "";
              }
              return Container(
                  margin: const EdgeInsets.only(left: 10),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          child: Text(
                            (widget.userId == instance.id
                                ? "$displayName (自分)"
                                : displayName),
                            style: const TextStyle(
                              color: Color.fromARGB(200, 255, 255, 255),
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        // SizedBox(
                        //   child:Text("あなた: こんにちは！",style:TextStyle(color:Color.fromARGB(200, 255, 255, 255)),textAlign: TextAlign.left),
                        // )
                      ]));
            }),
      ]),
    );
  }
}
