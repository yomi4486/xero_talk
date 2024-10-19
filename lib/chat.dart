import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
class chat extends StatelessWidget{
  chat(this.userCredential);
  UserCredential userCredential;
  Color defaultColor = const Color.fromARGB(255, 22, 22, 22);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomSheet: BottomAppBar(
        height: MediaQuery.of(context).size.height*0.1,
        notchMargin:4.0,
        color:const Color.fromARGB(255, 40, 40, 40),
        child:SizedBox(
          width: MediaQuery.of(context).size.width,
          child:Column(
            children: [
              TextField(

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
                  hintText: '',
                  labelText:'yomi4486にメッセージを送信',
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

                },
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
          margin: EdgeInsets.only(left:20),
          child:Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children:[
              SizedBox(
                height: 36,
                width: 36,
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
                                  children: [
                                    Container(
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
                                    Container(margin: const EdgeInsets.only(bottom:10,top: 10),
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
                                        ],
                                      ),
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