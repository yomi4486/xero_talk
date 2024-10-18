import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xero_talk/chat_main.dart';

class AccountStartup extends StatelessWidget{
  AccountStartup(this.userCredential);
  UserCredential userCredential;
  Color defaultColor = const Color.fromARGB(255, 22, 22, 22);
  @override
  Widget build(BuildContext context) {
    String name =  "${userCredential.user!.email!.replaceAll('@gmail.com', '').replaceAll('@icloud.com', '')}";
    String displayName= "${userCredential.user!.displayName}";
    String discription="";
    return Scaffold(
      appBar:AppBar(
        automaticallyImplyLeading: false,
        title: const Text('すてきなプロフィールを作りましょう🎉'),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color:Color.fromARGB(255, 255, 255, 255),
          fontSize: 16
        ),
        backgroundColor: const Color.fromARGB(255, 40, 40, 40),
        
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {

          var profile = userCredential.additionalUserInfo?.profile;
          // ドキュメント作成
          FirebaseFirestore.instance
              .collection('user_account') // コレクションID
              .doc('${profile?["sub"]}') // ドキュメントID
              .set(
                {
                  'discription': discription,
                  'display_name': displayName,
                  'name':name, 
                }
              )
              .then((value){
                print("ok!!!");
                Navigator.push(context,
                  MaterialPageRoute(builder: (context) => chatMain(userCredential))
                );
              })
              .catchError((err){
                print(err);
              });
        },
        backgroundColor: const Color.fromARGB(255, 85, 128, 203),
        child: const Icon(Icons.arrow_forward_ios_sharp,color: Color.fromARGB(200, 255, 255, 255),)
      ),
      
      backgroundColor: defaultColor,
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color.fromARGB(255, 22, 22, 22)),
          child:Column( 
            children: [
              SizedBox(
                width:MediaQuery.of(context).size.width,
                child: Container(
                  margin: const EdgeInsets.all(30),
                  child:Column(
                    children:[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              ClipRRect( // アイコン表示（角丸）
                                borderRadius: BorderRadius.circular(2000000),
                                  child:Image.network(
                                    "${userCredential.user!.photoURL}",
                                    width: MediaQuery.of(context).size.width *0.2,
                                  ),
                              ),
                              ElevatedButton.icon( // アイコン変更ボタン
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 231, 231, 231),
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(0, 0),
                                  maximumSize: Size.fromWidth(MediaQuery.of(context).size.width *0.2,)
                                ),
                                onPressed: () {},
                                label: const Text(
                                  '変更',
                                  style:(
                                    TextStyle(
                                      color: Colors.black,
                                      fontSize: 15
                                    )
                                  )
                                ),
                              ),
                            ], 
                          ),
                          SizedBox( // ニックネーム設定フォーム
                            child:Container(
                              width: MediaQuery.of(context).size.width *0.6,
                              margin:const EdgeInsets.only(left: 10),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: TextEditingController(text: displayName),
                                    style:const TextStyle(                            
                                      color: Color.fromARGB(255, 255, 255, 255),
                                      fontSize: 16,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '',
                                      labelText:'ニックネーム',
                                      labelStyle: TextStyle(
                                        color: Color.fromARGB(255, 255, 255, 255),
                                        fontSize: 16,
                                      ),
                                      hintStyle: TextStyle(
                                        color: Color.fromARGB(255, 255, 255, 255),
                                        fontSize: 16,
                                      )
                                      
                                    ),
                                  ),
                                  TextField(
                                    controller: TextEditingController(text: name),
                                    style:const TextStyle(                            
                                      color: Color.fromARGB(255, 255, 255, 255),
                                      fontSize: 16,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '',
                                      labelText:'ユーザーID(英数字のみ)',
                                      labelStyle: TextStyle(
                                        color: Color.fromARGB(255, 255, 255, 255),
                                        fontSize: 16,
                                      ),
                                      hintStyle: TextStyle(
                                        color: Color.fromARGB(255, 255, 255, 255),
                                        fontSize: 16,
                                      )
                                    ),
                                    onChanged: (text){
                                      name = text;
                                    },
                                  )
                                ]
                              )
                            )
                          ),
                        ],
                      ),
                    ]
                  )
                ),
              ),
              SizedBox(
                child:Container(
                  margin: const EdgeInsets.only(left: 30,right: 30),
                  child: TextField(
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    style:const TextStyle(                            
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '',
                      labelText:'自己紹介',
                      labelStyle: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 16,
                      ),
                      hintStyle: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: Color.fromARGB(16, 255, 255, 255),
                      
                    ),
                    onChanged: (text){
                      discription = text;
                    },
                  ),
                )
              )
            ] //childlen 画面全体
          )
        ),
      ),
    );
  }
}