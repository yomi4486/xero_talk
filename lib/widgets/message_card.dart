import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert' as convert;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:xero_talk/utils/auth_context.dart';

class MessageCard extends StatefulWidget {
  MessageCard({Key? key, required this.focusNode}) : super(key: key);
  final FocusNode focusNode;
  @override
  _MessageCardState createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  List<Widget> returnWidget = [];
  void addWidget(Widget newWidget) {
    returnWidget.add(newWidget); 
  }

  @override 
  void initState() {
    super.initState();
  }
  @override void dispose() { 
    widget.focusNode.dispose(); 
    super.dispose();
  }


  final AuthContext instance = AuthContext();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: instance.bloadCast,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        var displayName = "";
        var content = {};
        try {
          content = convert.json.decode(snapshot.data);
        } catch (e) {
          return Container();
        }
        final a = FirebaseFirestore.instance
          .collection('user_account')
          .doc('${content["author"]}');
        ()async{ // 会話に変更があった場合ファイルに書き込み
          final uploadFile = drive.File();
          uploadFile.name = "testfile.txt";
          await instance.googleDriveApi.files.create(
            uploadFile,
          );
        };
        return FutureBuilder(
          future: a.get(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> docSnapshot) {
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              displayName = "Loading...(0)";
              return const Column();
            } else if (docSnapshot.hasError) {
              return const Column();
            } else if (docSnapshot.hasData) {
              displayName = (docSnapshot.data?.data() as Map<String, dynamic>)["display_name"] ?? "No Name";
              final String messageContent = content["content"];
              final chatWidget = Container(
                margin: const EdgeInsets.only(bottom: 10, top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2000000),
                      child: Image.network(
                        "https://${dotenv.env['BASE_URL']}:8092/geticon?user_id=${content['author']}",
                        width: MediaQuery.of(context).size.height * 0.05,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text( // 名前
                            displayName,
                            style: const TextStyle(
                              color: Color.fromARGB(200, 55, 55, 55),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox( // コンテンツ
                            width: MediaQuery.of(context).size.width*0.7,
                            child:Text(
                              messageContent,
                              style: const TextStyle(
                                color: Color.fromARGB(200, 33, 33, 33),
                                fontSize: 16.0
                              ),
                              textAlign: TextAlign.left,
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
              addWidget(chatWidget);
            }
            return Column(children: returnWidget);
          },
        );
      },
    );
  }
}
