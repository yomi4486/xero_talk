import 'package:firebase_auth/firebase_auth.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert' as convert;
List<Widget> returnWidget=[];
class MessageCard extends StatelessWidget {
  /// Socket
  final WebSocketChannel stream;
  final UserCredential userCredential;
  MessageCard({Key? key, required this.stream, required this.userCredential}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        // 指定したstreamにデータが流れてくると再描画される
        stream: stream.stream,
        builder: (BuildContext context,AsyncSnapshot<dynamic> snapshot) {
          var displayName="";
          var content = {};
          try{
            content = convert.json.decode(snapshot.data);
          }catch(e){
            print("JSON decode error!: $e");
            return Container();
          }
          final a =FirebaseFirestore.instance
            .collection('user_account') // コレクションID
            .doc('${content["author"]}'); // ドキュメントID
          return FutureBuilder(
            future: a.get(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> docSnapshot) {
              if (docSnapshot.connectionState == ConnectionState.waiting) {
                displayName = "Loading...(0)";
                return const Column();
              } else if (docSnapshot.hasError) {
                return const Column();
              } else if (docSnapshot.hasData) { // successful
                displayName = (docSnapshot.data?.data() as Map<String, dynamic>)["display_name"] ?? "No Name";
                final String message_content = content["content"];
                final chatWidget = Container(
                  margin: const EdgeInsets.only(bottom:10,top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ClipRRect( // アイコン表示（角丸）
                        borderRadius: BorderRadius.circular(2000000),
                          child:Image.network(
                            "${userCredential.user!.photoURL}",
                            width: MediaQuery.of(context).size.height *0.05,
                          ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left:10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[
                            Text( // 名前
                              displayName,
                              style:const TextStyle(
                                color:Color.fromARGB(200, 255, 255, 255),
                                fontWeight: FontWeight.bold,
                                fontSize: 16
                              ),textAlign: TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),    
                            Text( // メッセージの内容
                              message_content,
                              style: const TextStyle(
                                color:Color.fromARGB(200, 255, 255, 255)
                              ),
                              textAlign: TextAlign.left,
                            ), 
                          ]
                        )
                      )
                    ],
                  ),
                );
                // returnWidget.add(chatWidget);
                returnWidget = [chatWidget];
                return Column(children:returnWidget);
              } else {
                return const Column();
              }

            },
          );
        },
      );
  }
}