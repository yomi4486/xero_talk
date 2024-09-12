import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
class AccountStartup extends StatelessWidget{
  AccountStartup(this.message,this.userCredential);
  String message;
  UserCredential userCredential;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color.fromARGB(255, 22, 22, 22)),
          child:SizedBox(
            width:MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network("${userCredential.user!.photoURL}"),
                ),
                Container(
                  margin: const EdgeInsets.all(10),

                  child: Text(
                    "$message${userCredential.user!.displayName}さん!",
                    style:(
                      const TextStyle(
                        color: Color.fromARGB(255, 240, 240, 240),
                        fontWeight: FontWeight.bold,
                        fontSize: 20
                      )
                    )
                  ),
                
                ),
              ]
            )
          )
        ),
      )
    );
  }
}