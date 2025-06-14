import 'package:flutter/material.dart';
import 'package:xero_talk/tabs.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:xero_talk/widgets/chat_list_widget.dart';
import 'package:provider/provider.dart';
import 'package:xero_talk/services/friend_service.dart';
import 'package:xero_talk/models/friend.dart';

String lastMessageId = "";

class chatHome extends StatefulWidget {
  final AsyncSnapshot snapshot;
  const chatHome({Key? key, required this.snapshot}) : super(key: key);
  @override
  _chatHomeState createState() => _chatHomeState();
}

class _chatHomeState extends State<chatHome> with AutomaticKeepAliveClientMixin<chatHome> {
  Map<String, dynamic> userData = {};
  final Color defaultColor = const Color.fromARGB(255, 22, 22, 22);
  final FriendService _friendService = FriendService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Color darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final instance = Provider.of<AuthContext>(context,listen: true);
    final tabsProvider = Provider.of<TabsProvider>(context, listen: true);
    super.build(context);
    return WillPopScope(
      onWillPop: () async => false,
      child:DecoratedBox(                       
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: FractionalOffset.topLeft,
            end: FractionalOffset.bottomRight,
            colors: instance.theme,
            stops: const [0.0, 1.0],
          ),
        ),
        child: Stack(
          children:[
            Scaffold(
              appBar: AppBar(
                centerTitle: false,
                automaticallyImplyLeading: false,
                title: const Text(
                  'メッセージ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  )
                ),
                titleTextStyle: const TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255), fontSize: 20
                ),
                backgroundColor: darkenColor(const Color.fromARGB(255, 68, 68, 68),0.2).withOpacity(.1),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                backgroundColor: instance.theme[1],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(128),
                ),
                child: const Icon(
                  Icons.add,
                  color: Color.fromARGB(200, 255, 255, 255),
                ),
              ),
              backgroundColor: Colors.transparent,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none, 
                      children: [
                        Column(
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: Container(
                                margin: EdgeInsets.only(
                                  left: MediaQuery.of(context).size.width * 0.25 > 120 ? 120: MediaQuery.of(context).size.width * 0.25,
                                  top: 30,
                                  right: 30,
                                  bottom: 30
                                ),
                                child: StreamBuilder<List<Friend>>(
                                  stream: _friendService.getFriends(instance.id),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
                                    }

                                    if (!snapshot.hasData) {
                                      return const Center(child: CircularProgressIndicator());
                                    }

                                    final friends = snapshot.data!;
                                    if (friends.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          'フレンドがいません',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      );
                                    }

                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: friends.map((friend) {
                                        final friendId = friend.senderId == instance.id
                                            ? friend.receiverId
                                            : friend.senderId;
                                        return GestureDetector(
                                          onTap: () {
                                            tabsProvider.showChatScreen(id: friendId);
                                          },
                                          child: ChatListWidget(
                                            userId: friendId,
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: darkenColor(const Color.fromARGB(255, 68, 68, 68),0.2).withOpacity(.2)),
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
                                        borderRadius: BorderRadius.circular(1000),
                                        child: Container(
                                          color: instance.theme[0],
                                          child: Image.asset(
                                            "assets/images/chat.png",
                                            width: MediaQuery.of(context).size.width * 0.15,
                                          )
                                        ),
                                      )
                                    ),
                                    Container(
                                      margin: const EdgeInsets.all(12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(1000),
                                        child: Image.asset(
                                          "assets/images/logo.png",
                                          width: MediaQuery.of(context).size.width * 0.15,
                                        ),
                                      )
                                    ),
                                    Container(
                                      margin: const EdgeInsets.all(12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(1000),
                                        child: Image.asset(
                                          "assets/images/logo.png",
                                          width: MediaQuery.of(context).size.width * 0.15,
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
                  )
                ],
              )
            ),
          ]
        )
      )
    );
  }
}
