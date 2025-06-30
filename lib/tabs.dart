import 'package:flutter/material.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:xero_talk/tabs/notify.dart';
import 'package:xero_talk/tabs/account_page.dart';
import 'package:xero_talk/tabs/home.dart';
import 'package:xero_talk/widgets/flash_modal.dart';
import 'package:provider/provider.dart';
import 'package:xero_talk/chat.dart';
import 'package:xero_talk/utils/get_user_profile.dart';
import 'package:xero_talk/utils/chat_file_manager.dart';
import 'dart:convert' as convert;
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class TabsProvider with ChangeNotifier {
  final PageController pageController = PageController(keepPage: true,initialPage: 0);
  late ChatFileManager chatFileManager;
  String? chatFileId;
  Map<String,dynamic> userData = {};
  Map<String, dynamic> chatHistory = {};

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

  /// ユーザーが所属する全グループのresponse/{group_id}をsubscribe
  Future<void> subscribeAllGroupChannels(String userId) async {
    final groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: userId)
        .get();
    final authContext = AuthContext();
    for (final doc in groupSnapshot.docs) {
      final groupId = doc.id;
      authContext.mqttClient.subscribe('response/$groupId', MqttQos.atMostOnce);
    }
  }

  Future<void> showChatScreen({String? id})async{
    print("表示中:$id");
    if(id == null){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        pageController.animateToPage(
          0,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      });
      notifyListeners();
      return;
    }
    userData = await getUserProfile(id);
    // グループチャンネルもsubscribe
    final authContext = AuthContext();
    await subscribeAllGroupChannels(authContext.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pageController.animateToPage(
        1,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    });
    showId = id;
    notifyListeners();
  }

  Future<void> saveNotification(Map<dynamic, dynamic> content) async {
    try {
      chatFileManager = ChatFileManager(chatFileId: null);
      chatFileId = await chatFileManager.loadOrCreateChatFile();
      chatFileManager = ChatFileManager(chatFileId: chatFileId);

      final history = await chatFileManager.loadChatHistory();
      if(history != null){ 
        // 既存の履歴を保持
        chatHistory = Map<String, dynamic>.from(history);
        
        final String type = content['type'] as String;
        final String messageId = type == "call" ? content["room_id"] as String : content["id"] as String;
        final int timestamp = content["timestamp"] as int;

        // 新しいメッセージを追加
        chatHistory[messageId] = {
          "author": content["author"],
          "content": content["content"],
          "timeStamp": timestamp,
          "edited": false,
          "attachments": content["attachments"],
          "voice": type == "call"
        };

        await chatFileManager.saveChatHistory({
          'messages': chatHistory,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }
}

class PageViewTabsScreen extends StatefulWidget {
  @override
  TabsScreen createState() => TabsScreen();
}

class TabsScreen extends State<PageViewTabsScreen> with WidgetsBindingObserver {
  bool _isShowingDisconnectSnackBar = false;
  Timer? _connectionTimer;

  @override
  void initState() {
    super.initState();
    oneColor = instance.theme[0];
    twoColor = instance.theme[1];
    _startConnectionMonitoring();
    WidgetsBinding.instance.addObserver(this);
    // プッシュ通知からアプリを開いたときのイベント
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message)async {
      print('onMessageOpenedApp: [38;5;246m[48;5;236m${message.data}[0m');
      if(message.data["type"] == "send_message"){
        print("きた");
        final tabsProvider = Provider.of<TabsProvider>(context, listen: false);
        tabsProvider.showChatScreen(id: message.data["author"]);
      }
      // 他のtypeの場合もここで分岐可能
    });
  }

  void _startConnectionMonitoring() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final authContext = AuthContext();
      if (authContext.mqttClient.connectionState != MqttConnectionState.connected) {
        if (!_isShowingDisconnectSnackBar) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('サーバーとの接続が失われました。再接続を試みています...'),
              duration: Duration(days: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _isShowingDisconnectSnackBar = true;
        }
      } else if (_isShowingDisconnectSnackBar) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('再接続に成功しました！'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        _isShowingDisconnectSnackBar = false;
      }
    });
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    if (_isShowingDisconnectSnackBar) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
    super.dispose();
  }

  Color darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

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

  final GlobalKey _streamKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Selector<AuthContext,Stream<String>>(
      selector: (context,provider)=>provider.mqttStream,
      key:_streamKey,
      builder: (context,mqttStream,child){
        return StreamBuilder<String>(
          stream: mqttStream,
          builder:(context,snapshot){
            final provider = Provider.of<TabsProvider>(context,listen: true);
            var content = <String, dynamic>{};
            try {
              if (snapshot.data != null) {
                content = convert.json.decode(snapshot.data!);
                final String type = content['type'];
                late String messageId;

                if (type == "call"){
                  messageId = content["room_id"];
                }else{
                  messageId = content["id"];
                }
                if(type == 'send_message' && lastMessageId != messageId){
                  if((instance.id != content['author'])&&(content['author'] != provider.showId && content['channel'] != provider.showId || provider.pageController.page == 0)){
                    showInfoSnack(context, content: content);
                    provider.saveNotification(content);
                  }     
                }
                lastMessageId = messageId;
              }
            } catch (_) {}
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: FractionalOffset.topLeft,
                  end: FractionalOffset.bottomRight,
                  colors: instance.theme,
                  stops: const [0.0, 1.0],
                ),
              ),
              child: PageView(
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
                    unselectedLabelStyle: TextStyle(
                        color: instance.getTextColor(instance.theme[0])[1]),
                    unselectedItemColor: Colors.white70,
                    selectedLabelStyle: TextStyle(color: Colors.white),
                    selectedItemColor: Colors.white,
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
                    backgroundColor: darkenColor(instance.theme[1],.01)
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
            ));
          }
        );
      },
    );
  }
}