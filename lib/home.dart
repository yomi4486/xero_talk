import 'package:flutter/material.dart';
import 'package:xero_talk/account_page.dart';
import 'package:xero_talk/chat.dart';
import 'package:xero_talk/notify.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:xero_talk/widgets/chat_list_widget.dart';
import 'package:xero_talk/utils/get_user_profile.dart';
import 'dart:convert' as convert;
import 'package:xero_talk/widgets/flash_modal.dart';
import 'package:provider/provider.dart';

String lastMessageId = "";

class chatHome extends StatefulWidget {
  chatHome();
  @override
  _chatHomeState createState() => _chatHomeState();
}

class _chatHomeState extends State<chatHome> {
  Map<String, dynamic> userData = {};
  final Color defaultColor = const Color.fromARGB(255, 22, 22, 22);

  @override // 限界まで足掻いた人生は想像よりも狂っているらしい
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      final instance = Provider.of<AuthContext>(context);
      Future<void> showChatScreen({String? id})async{
        if(id == null){
          setState((){
            instance.visibleChatScreen = false;
          });
          return;
        }
        userData = await getUserProfile(id);
        setState((){
          instance.visibleChatScreen = !instance.visibleChatScreen;
          instance.showChatId = id;
        });
      }
      return WillPopScope(
        onWillPop: () async => false,
        child: StreamBuilder(
      stream: instance.bloadCast,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        var content = {};
        try {
          if (snapshot.data != null) {
            content = convert.json.decode(snapshot.data);
          }
          final String type = content['type'];
          late String messageId;

          if (type == "call"){
            messageId = content["room_id"];
          }else{
            messageId = content["id"];
          }

          if(type == 'send_message' && lastMessageId != messageId){
            if(instance.id != content['author']){
              showInfoSnack(context, content: content);
            }     
          }

          lastMessageId = messageId;
        } catch (e) {
          // print(e);
        }

        return GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                // try {
                //   Navigator.of(context).push(
                //     MaterialPageRoute(
                //         builder: (context) => instance.lastOpenedChat),
                //   );
                // } catch (e) {
                //   //初期化されてない場合
                //   print("前の会話はありません");
                // }
              }
            },
            child: Stack(children:[
              Scaffold(
                bottomNavigationBar: BottomNavigationBar(
                  enableFeedback: false,
                  onTap: (value) {
                    if (value == 1) {
                      Navigator.push(
                          context,
                          PageRouteBuilder(
                              pageBuilder: (_, __, ___) => NotifyPage(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              }));
                    } else if (value == 2) {
                      Navigator.push(
                          context,
                          PageRouteBuilder(
                              pageBuilder: (_, __, ___) => AccountPage(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              }));
                    }
                  },
                  unselectedLabelStyle: const TextStyle(
                      color: Color.fromARGB(255, 200, 200, 200)),
                  unselectedItemColor: const Color.fromARGB(255, 200, 200, 200),
                  selectedLabelStyle: TextStyle(color: instance.theme[1]),
                  selectedItemColor: instance.theme[1],
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
                      icon: Icon(
                        Icons.person,
                        color: Color.fromARGB(255, 200, 200, 200),
                      ),
                      label: 'アカウント',
                    ),
                  ],
                  backgroundColor: const Color.fromARGB(255, 40, 40, 40),
                ),
                appBar: AppBar(
                  centerTitle: false,
                  automaticallyImplyLeading: false,
                  title: const Text('メッセージ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      )),
                  titleTextStyle: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255), fontSize: 20),
                  backgroundColor: const Color.fromARGB(255, 40, 40, 40),
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: instance.theme[1],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(128), //角の丸み
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Color.fromARGB(200, 255, 255, 255),
                  ),
                ),
                backgroundColor: defaultColor,
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(clipBehavior: Clip.none, children: [
                      DecoratedBox(
                          decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 22, 22, 22)),
                          child: Column(
                            children: [
                              SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: Container(
                                    margin: EdgeInsets.only(
                                        left:
                                            MediaQuery.of(context).size.width *
                                                        0.25 >
                                                    120
                                                ? 120
                                                : MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.25,
                                        top: 30,
                                        right: 30,
                                        bottom: 30),
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                              onTap: () async {
                                                // final Map<String, dynamic>
                                                //     userData =
                                                //     await getUserProfile(
                                                //         '106017943896753291176');
                                                // final Widget openWidget =
                                                //     chat(channelInfo: userData,snapshot: snapshot,);
                                                // instance.lastOpenedChat =
                                                //     openWidget;
                                                // Navigator.push(
                                                //   context,
                                                //   MaterialPageRoute(
                                                //       builder: (context) =>
                                                //           openWidget),
                                                // );
                                                showChatScreen(id:'106017943896753291176');
                                              },
                                              child: ChatListWidget(
                                                userId: '106017943896753291176',
                                              )),
                                          GestureDetector(
                                              onTap: () async {
                                                // final Map<String, dynamic>
                                                //     userData =
                                                //     await getUserProfile(
                                                //         '112905252227299870586');
                                                // final Widget openWidget =
                                                //     chat(channelInfo: userData,snapshot: snapshot,);
                                                // instance.lastOpenedChat =
                                                //     openWidget;
                                                // Navigator.push(
                                                //   context,
                                                //   MaterialPageRoute(
                                                //       builder: (context) =>
                                                //           openWidget),
                                                // );
                                                showChatScreen(id:'112905252227299870586');
                                              },
                                              child: ChatListWidget(
                                                  userId:
                                                      '112905252227299870586')),
                                        ]),
                                  )),
                            ],
                          )),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 68, 68, 68)),
                          child: ConstrainedBox(
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
                                        child: ClipRRect(
                                          // アイコン表示（角丸）
                                          borderRadius:
                                              BorderRadius.circular(2000000),
                                          child: Container(
                                              color: instance.theme[0],
                                              child: Image.asset(
                                                "assets/images/chat.png",
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.15,
                                              )),
                                        )),
                                    Container(
                                        margin: const EdgeInsets.all(12),
                                        child: ClipRRect(
                                          // アイコン表示（角丸）
                                          borderRadius:
                                              BorderRadius.circular(2000000),
                                          child: Image.asset(
                                            "assets/images/logo.png",
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.15,
                                          ),
                                        )),
                                    Container(
                                        margin: const EdgeInsets.all(12),
                                        child: ClipRRect(
                                          // アイコン表示（角丸）
                                          borderRadius:
                                              BorderRadius.circular(2000000),
                                          child: Image.asset(
                                            "assets/images/logo.png",
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.15,
                                          ),
                                        )),
                                  ],
                                )),
                          ),
                        ),
                      ),
                    ])
                  ],
                )
                ),
                instance.visibleChatScreen ? chat(
                  channelInfo: userData,
                  snapshot: snapshot,
                  showChatScreen: showChatScreen,
                )
                :
                Container()
              ]
            )
          );
        },
      ),
    );
  }
}
