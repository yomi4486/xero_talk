import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert' as convert;

class chat extends StatelessWidget{
  
  chat(this.userCredential);
  UserCredential userCredential;
  Color defaultColor = const Color.fromARGB(255, 22, 22, 22);
  final WebSocketChannel channel = WebSocketChannel.connect(
    Uri.parse('wss://localhost:8765'), // WebSocketサーバーのURL
  );
  @override
  String? chat_text = "";
  
  final fieldText = TextEditingController();
  Widget build(BuildContext context) {
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
                    hintText: 'yomi4486にメッセージを送信',
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
                    chat_text = text;
                  },
                ),
              ),
              IconButton(
                style:ButtonStyle(backgroundColor:MaterialStateProperty.all<Color>(Color.fromARGB(255, 140, 206, 74))),
                onPressed: (){
                  if(chat_text!.isNotEmpty){
                    print(chat_text);
                    channel.sink.add(chat_text);
                  }


                  void sendMessage(chatText) async {
                    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
                    final response = await http.post(
                      Uri.parse('https://localhost:9000/send_message?content=$chatText&token=$token&channel_id=dm'),
                      headers: {"Content-Type": "application/json"},
                    );
                    print(chat_text);
                    print(response.body);
                  }

                  sendMessage(chat_text);
                  chat_text = "";
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
          margin: EdgeInsets.only(left:7),
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
                margin:EdgeInsets.only(left:10),
                child:const Text('yomi4486',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20,color:Color.fromARGB(200, 255, 255, 255)),),
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
          Stack(clipBehavior: Clip.none,
          
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
                          children:[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Column(
                                  children: <Widget>[
                                    StreamBuilder(
                                      stream: channel.stream,
                                      builder: (context,snapshot) {
                                        print(snapshot.data);
                                        var displayName="Loading...";
                                        var profile = userCredential.additionalUserInfo?.profile;
                                        var content = {};
                                        
                                        try{
                                          content = convert.json.decode(snapshot.data);
                                          print(content);
                                        }catch(e){
                                          print("JSON decode error!: $e");
                                          return Container();
                                        }
                                        // ドキュメント作成
                                        final a =FirebaseFirestore.instance
                                            .collection('user_account') // コレクションID
                                            .doc('${content["author"]}'); // ドキュメントID
                                        return FutureBuilder(
                                          future: a.get(),
                                          builder: (context, AsyncSnapshot<DocumentSnapshot> docSnapshot) {
                                            if (docSnapshot.connectionState == ConnectionState.waiting) {
                                              displayName = "Loading...(0)";
                                            } else if (docSnapshot.hasError) {
                                              displayName = "LoadError(1)";
                                            } else if (docSnapshot.hasData) { // successful
                                              displayName = (docSnapshot.data?.data() as Map<String, dynamic>)["display_name"] ?? "No description";
                                              print("data: ${docSnapshot.data?.data()}");
                                            } else {
                                              displayName = "Loading...(2)";
                                            }
                                            final chatWidget = 
                                            Container(
                                              margin: const EdgeInsets.only(bottom:10,top: 10),
                                              child: Row(
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
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      children:[
                                                        SizedBox(
                                                          child:Text(displayName,style:TextStyle(color:Color.fromARGB(200, 255, 255, 255),fontWeight: FontWeight.bold,),textAlign: TextAlign.left,),
                                                        ),
                                                        SizedBox(
                                                          
                                                          child:Text('${content["content"]}',style:TextStyle(color:Color.fromARGB(200, 255, 255, 255)),textAlign: TextAlign.left), 
                                                        )
                                                      ]
                                                    )
                                                  )
                                                ],
                                              ),
                                            );
                                            return chatWidget;
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ]
                        )
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