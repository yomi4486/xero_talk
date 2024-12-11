import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert' as convert;
// import 'package:rxdart/rxdart.dart';
List<Widget> returnWidget=[];
class MessageCard extends StatefulWidget {
  final WebSocket stream;
  final UserCredential userCredential;
  MessageCard({Key? key, required this.stream, required this.userCredential}) : super(key: key);

  @override
  _MessageCardState createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  late StreamController<dynamic> _streamController;
  late StreamSubscription subscription;
  @override
  void initState() {
    super.initState();
    _streamController = StreamController<dynamic>.broadcast();
    subscription = widget.stream.listen((data) { _streamController.add(data); });
  }

  @override
  void dispose() {
    subscription.cancel();
    _streamController.close();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _streamController.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        var displayName = "";
        var content = {};
        try {
          content = convert.json.decode(snapshot.data);
        } catch (e) {
          print("JSON decode error!: $e");
          return Container();
        }
        final a = FirebaseFirestore.instance
            .collection('user_account')
            .doc('${content["author"]}');
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
                              color: Color.fromARGB(200, 255, 255, 255),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            messageContent,
                            style: const TextStyle(
                              color: Color.fromARGB(200, 255, 255, 255),
                            ),
                            textAlign: TextAlign.left,
                          ),
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
