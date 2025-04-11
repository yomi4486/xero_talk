import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:xero_talk/widgets/user_icon.dart';

class NotifyPage extends StatelessWidget {
  final Color defaultColor = const Color.fromARGB(255, 22, 22, 22);
  final AuthContext instance = AuthContext();
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
            appBar: AppBar(
              centerTitle: false,
              automaticallyImplyLeading: false,
              title: const Text('通知',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  )),
              titleTextStyle: const TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255), fontSize: 20),
              backgroundColor: const Color.fromARGB(255, 40, 40, 40),
            ),
            backgroundColor: defaultColor,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(clipBehavior: Clip.none, children: [
                  DecoratedBox(
                      decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 22, 22, 22)),
                      child: Column(children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Container(
                              margin: const EdgeInsets.only(
                                  left: 30, top: 30, right: 30, bottom: 30),
                              child: Column(children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        GestureDetector(
                                          child: Container(
                                            decoration: const BoxDecoration(
                                                color: Color.fromARGB(
                                                    0, 255, 255, 255)),
                                            margin: const EdgeInsets.only(
                                                bottom: 10),
                                            child: Row(children: [
                                              ClipRRect(
                                                // アイコン表示（角丸）
                                                borderRadius:
                                                    BorderRadius.circular(1000),
                                                child: UserIcon(userId: "106017943896753291176",size:MediaQuery.of(context).size.height * 0.05)
                                              ),
                                              Container(
                                                  margin: const EdgeInsets.only(
                                                      left: 10),
                                                  child: const Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        SizedBox(
                                                          child: Text(
                                                            "yomi4486があなたをメンションしました",
                                                            style: TextStyle(
                                                              color: Color
                                                                  .fromARGB(
                                                                      200,
                                                                      255,
                                                                      255,
                                                                      255),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            textAlign:
                                                                TextAlign.left,
                                                          ),
                                                        ),
                                                      ]))
                                            ]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ])),
                        ),
                      ] //childlen 画面全体
                          )),
                ])
              ],
            )));
  }
}
