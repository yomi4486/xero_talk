import 'dart:io';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:xero_talk/account_page.dart';
import 'package:xero_talk/chat.dart';
import 'package:xero_talk/notify.dart';
class chatHome extends StatelessWidget{
  chatHome({Key? key, required this.userCredential,required this.channel,required this.bloadCast}) : super(key: key);
  final WebSocket channel;
  final UserCredential userCredential;
  final Color defaultColor = const Color.fromARGB(255, 22, 22, 22);
  final Stream<dynamic> bloadCast;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop:() async => false,
      child:Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        enableFeedback:false,
        onTap: (value) {
          if(value == 1){
            Navigator.push(context, PageRouteBuilder(
              pageBuilder: (_, __, ___)=>NotifyPage(userCredential:userCredential,channel: channel,bloadCast: bloadCast,),
                  transitionsBuilder: (context, animation, secondaryAnimation, child){
                    return FadeTransition(opacity: animation, child: child,);
              }
            ));
          }else if(value == 2){
            Navigator.push(context, PageRouteBuilder(
              pageBuilder: (_, __, ___)=>accountPage(userCredential:userCredential,channel: channel,bloadCast: bloadCast,),
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
            icon: Icon(Icons.person,color: Color.fromARGB(255, 200, 200, 200),),
            label:'アカウント',
            
          ),
        ],
        backgroundColor: const Color.fromARGB(255, 40, 40, 40),
      ),
      appBar:AppBar(
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: const Text('メッセージ',style: TextStyle(fontWeight: FontWeight.bold,)),
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
                          margin: EdgeInsets.only(
                            left:MediaQuery.of(context).size.width * 0.25 > 120 ? 120 : MediaQuery.of(context).size.width * 0.25,
                            top: 30,
                            right: 30,
                            bottom: 30
                          ),
                          child:Column(
                            mainAxisAlignment:MainAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => chat(userCredential: userCredential,channelInfo:const {"channelId":"106017943896753291176","displayName":"yomi4486","name":"yomi4486"},channel: channel,bloadCast: bloadCast,)),
                                  );

                                },
                                child:Container(
                                  decoration: const BoxDecoration(color:Color.fromARGB(0, 255, 255, 255)),
                                  margin: const EdgeInsets.only(bottom:10),
                                  child: Row(
                                    children:[
                                      ClipRRect( // アイコン表示（角丸）
                                        borderRadius: BorderRadius.circular(2000000),
                                          child:Image.network(
                                            "${userCredential.user!.photoURL}",
                                            width: MediaQuery.of(context).size.height *0.05,
                                          ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(left:10),
                                        child:const Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children:[
                                            SizedBox(
                                                child:Text("yomi4486",style:TextStyle(color:Color.fromARGB(200, 255, 255, 255),fontWeight: FontWeight.bold,),textAlign: TextAlign.left,),
                                            ),
                                            // SizedBox(
                                            //   child:Text("あなた: こんにちは！",style:TextStyle(color:Color.fromARGB(200, 255, 255, 255)),textAlign: TextAlign.left), 
                                            // )
                                          ]
                                        )
                                      )
                                    ]
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async{
                                  print("onTap called.");
                                  Navigator.push(
                                    context,
                                    
                                    MaterialPageRoute(builder: (context) => chat(userCredential: userCredential,channelInfo:const {"channelId":"112905252227299870586","displayName":"太郎","name":"ta"},channel:channel,bloadCast: bloadCast,)),
                                  );
                                },
                                child:Container(
                                  decoration: const BoxDecoration(color:Color.fromARGB(0, 255, 255, 255)),
                                  margin: const EdgeInsets.only(bottom:10),
                                  child: Row(
                                    children:[
                                      ClipRRect( // アイコン表示（角丸）
                                        borderRadius: BorderRadius.circular(2000000),
                                          child:Image.network(
                                            "${userCredential.user!.photoURL}",
                                            width: MediaQuery.of(context).size.height *0.05,
                                          ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(left:10),
                                        child:const Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children:[
                                            SizedBox(
                                                child:Text("太郎",style:TextStyle(color:Color.fromARGB(200, 255, 255, 255),fontWeight: FontWeight.bold,),textAlign: TextAlign.left,),
                                            ),
                                            // SizedBox(
                                            //   child:Text("あなた: こんにちは！",style:TextStyle(color:Color.fromARGB(200, 255, 255, 255)),textAlign: TextAlign.left), 
                                            // )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            ]                          
                          ),
                        )
                      ),
                    ],
                  )
              ),
              Positioned(
                top: 0,
                left: 0,
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: Color.fromARGB(255, 68, 68, 68)),
                    child:ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 95.0,
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.2,
                        height: MediaQuery.of(context).size.height,
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.all(12),
                              child:ClipRRect( // アイコン表示（角丸）
                                borderRadius: BorderRadius.circular(2000000),
                                child:Container(
                                  color:const Color.fromARGB(255, 140, 206, 74),
                                  child:Image.asset(
                                    "assets/images/chat.png",
                                    width: MediaQuery.of(context).size.width *0.15,
                                  )
                                ),
                              )
                            ),
                            Container(
                              margin: const EdgeInsets.all(12),
                              child:ClipRRect( // アイコン表示（角丸）
                                borderRadius: BorderRadius.circular(2000000),
                                child:Image.asset(
                                  "assets/images/logo.png",
                                  width: MediaQuery.of(context).size.width *0.15,
                                ),
                              )
                            ),
                            Container(
                              margin: const EdgeInsets.all(12),
                              child:ClipRRect( // アイコン表示（角丸）
                                borderRadius: BorderRadius.circular(2000000),
                                child:Image.asset(
                                  "assets/images/logo.png",
                                  width: MediaQuery.of(context).size.width *0.15,
                                ),
                              )
                            ),
                          ],
                        )
                      ),
                    ),
                  ),
                ),
              ]
            )
          ],
        )
      )
    );
  }
}