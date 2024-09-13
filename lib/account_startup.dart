import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
class AccountStartup extends StatelessWidget{
  AccountStartup(this.userCredential);
  UserCredential userCredential;
  Color defaultColor = const Color.fromARGB(255, 22, 22, 22);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        automaticallyImplyLeading: false,
        title: const Text('すてきなプロフィールを作りましょう！'),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color:Color.fromARGB(255, 255, 255, 255),
          fontSize: 16
        ),
        backgroundColor: const Color.fromARGB(255, 40, 40, 40),
        
      ),
      backgroundColor: defaultColor,
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color.fromARGB(255, 22, 22, 22)),
          child:SizedBox(
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
                          child: TextField(
                            controller: TextEditingController(text: "${userCredential.user!.displayName}"),
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
                          )
                        )
                      ),
                    ],
                  ),
                ]
              )
            ),
          )
        )
      ),
    );
  }
}