import 'dart:io';

import 'package:flutter/material.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:xero_talk/tabs/notify.dart';
import 'package:xero_talk/tabs/account_page.dart';
import 'package:xero_talk/tabs/home.dart';
import 'package:xero_talk/widgets/flash_modal.dart';
import 'package:provider/provider.dart';
import 'package:xero_talk/chat.dart';
import 'package:xero_talk/utils/get_user_profile.dart';
import 'dart:convert' as convert;

class TabsProvider with ChangeNotifier {
  final PageController pageController = PageController(keepPage: true,initialPage: 0);
  Map<String,dynamic> userData = {};

  int selectedIndex = 0;

  void setSelectedIndex(int index) {
    if(selectedIndex == index){
      // 二重クリックは無視
      return;
    }
    selectedIndex = index;
    notifyListeners();
  }

  String showId = "";

  Future<void> showChatScreen({String? id})async{
    if(id == null){
      pageController.animateToPage(
        0,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
      notifyListeners();
      return;
    }
    userData = await getUserProfile(id);
    pageController.animateToPage(        
        1,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    showId = id;
    notifyListeners();
  }
}

class PageViewTabsScreen extends StatefulWidget {
  @override
  TabsScreen createState() => TabsScreen();
}

class TabsScreen extends State<PageViewTabsScreen> {
  TabsScreen();
  final AuthContext instance = AuthContext();
  late List<dynamic> theme;
  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).toUpperCase().padLeft(8, '0')}';
  }

  Color hexToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  late Color oneColor;
  late Color twoColor;

  @override
  void initState() {
    super.initState();
    oneColor = instance.theme[0];
    twoColor = instance.theme[1];
  }

  @override
  void dispose() {
    super.dispose();
  }

  final GlobalKey _streamKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Selector<AuthContext,WebSocket>(
      selector: (context,provider)=>provider.channel,
      key:_streamKey,
      builder: (context,asyncProvider,child){
        return StreamBuilder(
          stream:asyncProvider,
          builder:(context,snapshot){
            final provider = Provider.of<TabsProvider>(context,listen: true);
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
            return PageView(
              controller: provider.pageController,
              scrollDirection: Axis.horizontal,
              physics: provider.selectedIndex == 0 && provider.userData.isNotEmpty ? ClampingScrollPhysics() : NeverScrollableScrollPhysics(),
              children:[
                Scaffold(
                  bottomNavigationBar:BottomNavigationBar(
                    currentIndex: provider.selectedIndex,
                    enableFeedback: false,
                    onTap: (value) {
                      provider.setSelectedIndex(value);
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
                        ),
                        label: 'アカウント',
                      ),
                    ],
                    backgroundColor: const Color.fromARGB(255, 40, 40, 40),
                  ),
                  body: IndexedStack(
                    key:GlobalKey(),
                    index:provider.selectedIndex,
                    children:[
                      chatHome(
                        snapshot: snapshot,
                      ),
                      NotifyPage(),
                      AccountPage(),
                    ]
                  ),
                ),
                chat(
                  channelInfo: provider.userData,
                  snapshot: snapshot,
                )
              ]
            );
          }
        );
      },
    );
  }
}