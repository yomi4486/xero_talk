import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert' as convert;
import 'package:googleapis/drive/v3.dart' as drive;

List<Widget> returnWidget = [];

class MessageCard extends StatefulWidget {
  final Stream<dynamic> bloadCast;
  final UserCredential userCredential;
  final drive.DriveApi googleDriveApi;
  MessageCard({Key? key, required this.bloadCast, required this.userCredential,required this.googleDriveApi}) : super(key: key);

  @override
  _MessageCardState createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.bloadCast,
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
          await widget.googleDriveApi.files.create(
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
                        "${widget.userCredential.user!.photoURL}",
                        width: MediaQuery.of(context).size.height * 0.05,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Color.fromARGB(200, 55, 55, 55),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width*0.7,
                            child:Text(
                              messageContent,
                              style: const TextStyle(
                                color: Color.fromARGB(200, 55, 55, 55),
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
              returnWidget = [chatWidget];
              return Column(children: returnWidget);
            } else {
              return const Column();
            }
          },
        );
      },
    );
  }
}
