import 'dart:io';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:xero_talk/home.dart';
import 'package:xero_talk/notify.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class accountPage extends StatelessWidget{
  accountPage({Key? key, required this.userCredential,required this.channel, required this.bloadCast}) : super(key: key);
  final UserCredential userCredential;
  final WebSocket channel;
  final Stream<dynamic> bloadCast;
  final Color defaultColor = const Color.fromARGB(255, 22, 22, 22);

  @override
  Widget build (BuildContext context) {
    var description = "";
    var displayName = "";
    // var name = "";
    var profile = userCredential.additionalUserInfo?.profile;
    return WillPopScope(
      onWillPop:() async => false,
      child: FutureBuilder(
        future:FirebaseFirestore.instance
          .collection('user_account') // コレクションID
          .doc('${profile?["sub"]}') // ドキュメントID
          .get(),
        builder:(context, snapshot){
          if (snapshot.connectionState == ConnectionState.waiting) {
            displayName = "";
          } else if (snapshot.hasError) {
            displayName = "";
          } else if (snapshot.hasData) { // successful
            displayName = (snapshot.data?.data() as Map<String, dynamic>)["display_name"] ?? "No description";
            description = (snapshot.data?.data() as Map<String, dynamic>)["description"] ?? "";
          } else {
            displayName = "";
          }
          return Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              enableFeedback:false,
              currentIndex:2,
              onTap: (value) {
                if(value == 0){
                  Navigator.push(context, PageRouteBuilder(
                    pageBuilder: (_, __, ___)=>chatHome(userCredential:userCredential,channel: channel,bloadCast: bloadCast,),
                        transitionsBuilder: (context, animation, secondaryAnimation, child){
                          return FadeTransition(opacity: animation, child: child,);
                    }
                  ));
                }else if(value==1){
                  Navigator.push(context, PageRouteBuilder(
                    pageBuilder: (_, __, ___)=>NotifyPage(userCredential:userCredential,channel:channel,bloadCast: bloadCast,),
                        transitionsBuilder: (context, animation, secondaryAnimation, child){
                          return FadeTransition(opacity: animation, child: child,);
                    }
                  ));
                }
              },
              unselectedLabelStyle: const TextStyle(color: Color.fromARGB(255, 200, 200, 200)),
              unselectedItemColor: const Color.fromARGB(255, 200, 200, 200),
              selectedLabelStyle: const TextStyle(color: Color.fromARGB(255, 140, 206, 74)),
              selectedItemColor: const Color.fromARGB(255, 140, 206, 74),
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'ホーム',
                  
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications),
                  label: '通知',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person,),
                  label:'アカウント' ,
                  
                ),
              ],
              backgroundColor: const Color.fromARGB(255, 40, 40, 40),
            ),
            appBar:AppBar(
              centerTitle: false,
              automaticallyImplyLeading: false,
              title: const Text("アカウント",style: TextStyle(fontWeight: FontWeight.bold,)),
              titleTextStyle: const TextStyle(
                color:Color.fromARGB(255, 255, 255, 255),
                fontSize: 20
              ),
              backgroundColor: const Color.fromARGB(255, 40, 40, 40),
              
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
              },
              backgroundColor: const Color.fromARGB(255, 140, 206, 74),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(128), //角の丸み
              ),
              child: const Icon(Icons.add,color: Color.fromARGB(200, 255, 255, 255),),

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
                                            hintText: 'ニックネーム',
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
                          controller: TextEditingController(text: description),
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
                            description = text;
                          },
                        ),
                      )
                    )
                  ] //childlen 画面全体
                )
              ),
            ),
          );
        },
      ),
    );
  }
}