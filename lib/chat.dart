import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert' as convert;
import 'package:xero_talk/widgets/message_card.dart';

class chat extends StatelessWidget{
  chat({Key? key, required this.userCredential, required this.channelInfo}) : super(key: key);
  UserCredential userCredential;
  Map channelInfo;
  Color defaultColor = const Color.fromARGB(255, 22, 22, 22);
  String? chatText = "";
  final fieldText = TextEditingController();
  final WebSocketChannel channel = WebSocketChannel.connect(
    Uri.parse('wss://localhost:8000/send_message')
  );
  
  @override
  Widget build(BuildContext context) {
    final String displayName = channelInfo["displayName"];
    return Scaffold(
      bottomSheet: BottomAppBar(
        height: MediaQuery.of(context).size.height*0.12,
        notchMargin:4.0,
        color:const Color.fromARGB(255, 40, 40, 40),
        child:Container(
          margin: const EdgeInsets.only(bottom:20),
          width: MediaQuery.of(context).size.width,
          child:Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width*0.75,
                child:TextField(
                  controller: fieldText,
                  onTapOutside:(_)=>FocusScope.of(context).unfocus(), // テキスト入力欄以外をタップしたらフォーカスを外す
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  style: const TextStyle(                            
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    hintText: '$displayNameにメッセージを送信',
                    // labelText:'yomi4486にメッセージを送信',
                    labelStyle: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 16,
                    ),
                    hintStyle: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 16,
                    ),
                    filled: false,
                    fillColor: const Color.fromARGB(16, 255, 255, 255),
                  ),
                  onChanged: (text){
                    chatText = text;
                  },
                ),
              ),
              IconButton(
                style:ButtonStyle(backgroundColor:MaterialStateProperty.all<Color>(const Color.fromARGB(255, 140, 206, 74))),
                onPressed: () async {
                  void sendMessage(String? text) async {
                    if(text!.isNotEmpty){
                      String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
                      final channelId = channelInfo["channelId"];
                      final sendBody = {"token":"$token","content":text,"channel":channelId};
                      channel.sink.add(convert.json.encode(sendBody));
                    }
                  }
                  sendMessage(chatText);
                  chatText = "";
                  fieldText.clear();
                },
                icon: const ImageIcon(
                  AssetImage("assets/images/send.png"),
                  color: Color.fromARGB(255, 255, 255, 255),
                )
              ),
            ],
          )
        )
      ),
      appBar:AppBar(
        centerTitle: false,
        automaticallyImplyLeading: false,
        
        titleTextStyle: const TextStyle(
          color:Color.fromARGB(200, 255, 255, 255),
          fontSize: 20
        ),
        backgroundColor: const Color.fromARGB(255, 40, 40, 40),
        leading: Container(
          margin: const EdgeInsets.only(left:7),
          child:Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children:[
              SizedBox(
                child: ClipRRect( // アイコン表示（角丸）
                    borderRadius: BorderRadius.circular(30),
                    child:Container(
                      color:const Color.fromARGB(0, 255, 255, 255),
                      child:IconButton(
                        onPressed: ()async{
                          Navigator.of(context).pop();
                          await channel.sink.close(1000);
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color.fromARGB(128, 255, 255, 255)
                        )
                      )
                    ),
                ),
              ),
              SizedBox(
                height: 34,
                width: 34,
                child:ClipRRect( // アイコン表示（角丸）
                borderRadius: BorderRadius.circular(2000000),
                child:Image.network(
                  "${userCredential.user!.photoURL}",
                  fit:BoxFit.contain
                ),
                ),
              ),
              Container(
                width: 200,
                margin:const EdgeInsets.only(left:10),
                child:Text(displayName,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20,color:Color.fromARGB(200, 255, 255, 255)),),
              )
            ]
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16,bottom:10),
            child:Wrap(
              spacing: 10,
              runSpacing: 10,
              children:[
                FittedBox( 
                fit:BoxFit.cover,
                  child:ClipRRect( // アイコン表示（角丸）
                    borderRadius: BorderRadius.circular(30),
                    child:Container(
                      color:const Color.fromARGB(0, 255, 255, 255),
                      child:IconButton(
                        onPressed: (){},
                        icon: const Icon(
                          Icons.phone,
                          color: Color.fromARGB(128, 255, 255, 255)
                        )
                      )
                    ),
                  ),
                ),
                FittedBox(
                  child:ClipRRect( // アイコン表示（角丸）
                    borderRadius: BorderRadius.circular(30),
                    child:Container(
                      color:const Color.fromARGB(0, 255, 255, 255),
                      child:IconButton(
                        onPressed: (){},
                        icon: const Icon(Icons.search,color: Color.fromARGB(128, 255, 255, 255))
                      )
                    ),
                  ),
                ),
              ]
            )
          )
        ],
      ),
      backgroundColor: defaultColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Stack(
            clipBehavior: Clip.none,
            children:[
              DecoratedBox(
                decoration: const BoxDecoration(color: Color.fromARGB(255, 22, 22, 22)),
                child:Column( 
                  children: [
                    SizedBox(
                      width:MediaQuery.of(context).size.width,
                      child: Container(
                        margin: const EdgeInsets.only(left:30,top: 30,right: 30,bottom: 30),
                        child:Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children:[
                            SingleChildScrollView(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 800),
                                reverseDuration: const Duration(milliseconds: 800),
                                child:MessageCard(stream: channel, userCredential: userCredential)
                              ),
                            )
                          ]
                        ),
                      ),
                    ),
                  ] //childlen 画面全体
                )
              ),
            ] 
          )
        ],
      )
    );
  }  
}