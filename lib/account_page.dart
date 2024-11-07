import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:xero_talk/chat.dart';
import 'package:xero_talk/home.dart';
import 'package:xero_talk/notify.dart';

class accountPage extends StatelessWidget{
  accountPage(this.userCredential);
  UserCredential userCredential;
  Color defaultColor = const Color.fromARGB(255, 22, 22, 22);
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop:() async => false,
      child:Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        enableFeedback:false,
        currentIndex:2,
        onTap: (value) {
          print(value);
          if(value == 0){
            Navigator.push(context, PageRouteBuilder(
              pageBuilder: (_, __, ___)=>chatHome(userCredential),
                  transitionsBuilder: (context, animation, secondaryAnimation, child){
                    return FadeTransition(opacity: animation, child: child,);
              }
            ));
          }else if(value==1){
            Navigator.push(context, PageRouteBuilder(
              pageBuilder: (_, __, ___)=>notifyPage(userCredential),
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
                          margin:const EdgeInsets.only(left:30,top: 30,right: 30,bottom: 30),
                          child:Column(
                            children:[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          print("onTap called.");
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