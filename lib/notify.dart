import 'dart:io';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:xero_talk/account_page.dart';
import 'package:xero_talk/home.dart';
import 'package:xero_talk/main.dart';

class NotifyPage extends StatelessWidget{
  NotifyPage({Key? key, required this.userCredential,required this.channel, required this.bloadCast}) : super(key: key);
  final WebSocket channel;
  final UserCredential userCredential;
  final Stream<dynamic> bloadCast;

  final Color defaultColor = const Color.fromARGB(255, 22, 22, 22);
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop:() async => false,
      child:Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        enableFeedback:false,
        currentIndex:1,
        onTap: (value) {
          if(value == 0){
            Navigator.push(context, PageRouteBuilder(
              pageBuilder: (_, __, ___)=>chatHome(userCredential:userCredential,channel:channel,bloadCast: bloadCast,googleDriveApi: googleDriveApi,),
                  transitionsBuilder: (context, animation, secondaryAnimation, child){
                    return FadeTransition(opacity: animation, child: child,);
              }
            ));
          }else if(value == 2){
            Navigator.push(context, PageRouteBuilder(
              pageBuilder: (_, __, ___)=>AccountPage(userCredential:userCredential,channel:channel,bloadCast: bloadCast,googleDriveApi: googleDriveApi,),
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
            label:'アカウント' ,
            
          ),
        ],
        backgroundColor: const Color.fromARGB(255, 40, 40, 40),
      ),
      appBar:AppBar(
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: const Text('通知',style: TextStyle(fontWeight: FontWeight.bold,)),
        titleTextStyle: const TextStyle(
          color:Color.fromARGB(255, 255, 255, 255),
          fontSize: 20
        ),
        backgroundColor: const Color.fromARGB(255, 40, 40, 40),
        
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
                            children:[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(context, PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) => chatHome(userCredential:userCredential,channel:channel,bloadCast: bloadCast,googleDriveApi: googleDriveApi,),
                                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                              return const FadeUpwardsPageTransitionsBuilder().buildTransitions(
                                                MaterialPageRoute(builder: (context)=>chatHome(userCredential:userCredential,channel: channel,bloadCast: bloadCast,googleDriveApi: googleDriveApi,)),
                                                context,
                                                animation,
                                                secondaryAnimation,
                                                child
                                              );
                                            },
                                          ));
                                        },
                                        child:Container(
                                          decoration: const BoxDecoration(color:Color.fromARGB(0, 255, 255, 255)),
                                          margin: const EdgeInsets.only(bottom:10),
                                          child: Row(
                                            children:[
                                              ClipRRect( // アイコン表示（角丸）
                                                borderRadius: BorderRadius.circular(2000000),
                                                  child:Image.network(
                                                    "https://xenfo.org:8092/geticon?user_id=106017943896753291176",
                                                    width: MediaQuery.of(context).size.height *0.05,
                                                  ),
                                              ),
                                              Container(
                                                margin: const EdgeInsets.only(left:10),
                                                child:const Column(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  children:[
                                                    SizedBox(
                                                        child:Text("yomi4486があなたをメンションしました",style:TextStyle(color:Color.fromARGB(200, 255, 255, 255),fontWeight: FontWeight.bold,),textAlign: TextAlign.left,),
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
                                      // Container(margin: const EdgeInsets.only(bottom:10,top: 10),
                                      //   child: Row(
                                      //     children: [
                                      //       ClipRRect( // アイコン表示（角丸）
                                      //         borderRadius: BorderRadius.circular(2000000),
                                      //           child:Image.network(
                                      //             "${userCredential.user!.photoURL}",
                                      //             width: MediaQuery.of(context).size.height *0.05,
                                      //           ),
                                      //       ),
                                      //       Container(
                                      //         margin: const EdgeInsets.only(left:10),
                                      //         child:const Column(
                                      //           mainAxisAlignment: MainAxisAlignment.start,
                                      //           children:[
                                      //             SizedBox(
                                      //               child:Text("yomi4486",style:TextStyle(color:Color.fromARGB(200, 255, 255, 255),fontWeight: FontWeight.bold,),textAlign: TextAlign.left,),
                                      //             ),
                                      //             // SizedBox(
                                      //             //   child:Text("あなた: こんにちは！",style:TextStyle(color:Color.fromARGB(200, 255, 255, 255)),textAlign: TextAlign.left), 
                                      //             // )
                                      //           ]
                                      //         )
                                      //       )
                                      //     ],
                                      //   ),
                                      // ),
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
    ));
  }
}