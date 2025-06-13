import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert' as convert;
import 'package:xero_talk/utils/auth_context.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:xero_talk/widgets/create_message_card.dart';
import 'dart:typed_data';
import '../voice_chat.dart';
import 'package:xero_talk/utils/voice_chat.dart';
import 'package:xero_talk/utils/message_tools.dart';
import 'package:xero_talk/utils/chat_file_manager.dart';

String lastMessageId = "";

class MessageScreen extends StatefulWidget {
  MessageScreen(
      {Key? key,
      required this.focusNode,
      required this.scrollController,
      required this.channelInfo,
      required this.fieldText,
      required this.EditMode,
      required this.ImageControler,
      required this.snapshot})
      : super(key: key);
  final FocusNode focusNode;

  /// チャット入力欄のフォーカスノード
  final ScrollController scrollController;
  final Map channelInfo;
  final TextEditingController fieldText;
  final Function(Uint8List, bool) ImageControler;
  final Function(String, bool) EditMode;
  final AsyncSnapshot snapshot;
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  List<Widget> returnWidget = [];
  Map chatHistory = {};
  late ChatFileManager chatFileManager;
  String? chatFileId;

  @override
  void initState() {
    super.initState();
    _initializeChatFileManager();
  }

  Future<void> _initializeChatFileManager() async {
    chatFileManager = ChatFileManager(chatFileId: null);
    chatFileId = await chatFileManager.loadOrCreateChatFile();
    chatFileManager = ChatFileManager(chatFileId: chatFileId);
    await _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await chatFileManager.loadChatHistory();
      if (history != null) {
        setState(() {
          chatHistory = history;
          // 履歴を時系列順に並び替えて表示
          final sortedMessages = chatHistory.entries.toList()
            ..sort((a, b) => (a.value['timeStamp'] as int).compareTo(b.value['timeStamp'] as int));
          
          returnWidget = [];
          for (var entry in sortedMessages) {
            final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(entry.value['timeStamp']);
            final String displayTime = getTimeStringFormat(dateTime);
            
            if (entry.value['voice'] == true) {
              try{
                final voiceWidget = getVoiceWidget(
                  context,
                  entry.key,
                  {
                    'author': entry.value['author'],
                    'room_id': entry.key,
                    'timestamp': entry.value['timeStamp'],
                  },
                  instance.getTextColor(Color.lerp(instance.theme[0], instance.theme[1], .5)!),
                );
                addWidget(voiceWidget, 0);
              }catch(e){
                print(e);
              }
            } else {
              final Widget chatWidget = FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('user_account')
                    .doc(entry.value['author'])
                    .get(),
                builder: (context, snapshot) {
                  String displayName = "Unknown";
                  if (snapshot.hasData && snapshot.data != null) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    displayName = data?['display_name'] ?? "Unknown";
                  }
                  return getMessageCard(
                    context,
                    widget,
                    instance.getTextColor(Color.lerp(instance.theme[0], instance.theme[1], .5)!),
                    displayName,
                    displayTime,
                    entry.value['author'],
                    entry.value['content'],
                    entry.value['edited'] ?? false,
                    entry.value['attachments'],
                    entry.key,
                    showImage: widget.ImageControler,
                  );
                },
              );
              addWidget(chatWidget, 0);
            }
          }
        });
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  void addWidget(Widget newWidget, double currentPosition) {
    returnWidget.add(newWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.scrollController.jumpTo(currentPosition);
      widget.scrollController.animateTo(
        widget.scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void removeWidget(String key) {
    try {
      returnWidget.removeWhere((widget) => (widget.key as ValueKey).value == key);
      chatHistory.remove(key);
      chatFileManager.saveChatHistory({
        'messages': chatHistory,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print(e);
    }
  }

  void editWidget(String key, String content) {
    try {
      chatHistory[key]["content"] = content;
      chatHistory[key]["edited"] = true;
      chatFileManager.saveChatHistory({
        'messages': chatHistory,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    // チャット入力欄のフォーカスを無視する
    widget.focusNode.dispose();
    super.dispose();
  }

  void launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  ///　メッセージのテキストに適切な装飾を行います。（URLが含まれていたらクリック可能に、編集済みかどうか。）
  List<TextSpan> getTextSpans(String text, bool edited, List<Color> textColor) {
    final RegExp urlRegExp = RegExp(
      r'(http|https):\/\/([\w.]+\/?)\S*',
      caseSensitive: false,
    );

    final List<TextSpan> spans = [];
    final matches = urlRegExp.allMatches(text);

    int lastMatchEnd = 0;
    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }
      final url = match.group(0);
      spans.add(
        TextSpan(
          text: url,
          style: const TextStyle(
              color: Colors.blue, decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              if (await canLaunch(url!)) {
                await launch(url);
              }
            },
        ),
      );
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }
    if (edited) {
      spans.add(
        TextSpan(
          text: " (編集済み)",
          style: TextStyle(color: textColor[0], fontSize: 10),
        ),
      );
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final instance = Provider.of<AuthContext>(context);
    final Color backgroundColor =
        Color.lerp(instance.theme[0], instance.theme[1], .5)!;
    final List<Color> textColor = instance.getTextColor(backgroundColor);
    late String displayName;
    if(widget.snapshot.data == null) {
      return Column(children: returnWidget);
    }
    final content = convert.json.decode(widget.snapshot.data);
    final a = FirebaseFirestore.instance
            .collection('user_account')
            .doc('${content["author"]}');
    final currentPosition = widget.scrollController.position.pixels;
    return FutureBuilder(
          future: a.get(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> docSnapshot) {
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              //　取得中
            } else if (docSnapshot.hasError) {
              // エラー
            } else if (docSnapshot.hasData) {
              displayName = (docSnapshot.data?.data()
                      as Map<String, dynamic>)["display_name"] ??
                  "No Name";
              final String type = content["type"];

              late String messageId;

              if (type == "call"){
                messageId = content["room_id"];
              }else{
                messageId = content["id"];
              }
              
              final String? messageContent = content["content"];
              final int timestamp = content["timestamp"];
              final DateTime dateTime =
                  DateTime.fromMillisecondsSinceEpoch(timestamp);
              final String modifiedDateTime = getTimeStringFormat(dateTime);
              bool edited = false;
              if (type == "delete_message") {
                removeWidget(messageId);
                return Column(children: returnWidget);
              }
              if (type == "edit_message") {
                editWidget(messageId, content["content"]);
                edited = true;
              }

              if ((type == "send_message" || type == "call") && lastMessageId == messageId) { //　同じストリームが流れてきた時は無視
                return Column(
                  children: returnWidget,
                );
              }
              lastMessageId = messageId; // 最終受信を上書き
              if (type == "edit_message") {
                try{
                  chatHistory[messageId]["content"] = messageContent;
                  chatHistory[messageId]["timeStamp"] = timestamp;
                  chatHistory[messageId]["edited"] = edited;
                  returnWidget = []; // IDの衝突を起こすため初期化
                  for (var entry in chatHistory.entries) {
                    if (entry.value["voice"] == true){
                      final voiceWidget = getVoiceWidget(context, entry.key,content,textColor);
                      addWidget(voiceWidget, currentPosition);
                    }else{
                      final Widget chatWidget = getMessageCard(
                          context,
                          widget,
                          textColor,
                          entry.value["display_name"],
                          entry.value["display_time"],
                          entry.value["author"],
                          entry.value["content"],
                          entry.value["edited"],
                          entry.value["attachments"],
                          entry.key,
                          showImage: widget.ImageControler);
                      addWidget(chatWidget, currentPosition);
                    }
                  }
                  chatFileManager.saveChatHistory({
                    'messages': chatHistory,
                    'lastUpdated': DateTime.now().millisecondsSinceEpoch,
                  });
                }catch(e){
                  chatHistory={};
                  return Column(children: returnWidget);
                }
                
              }else if(type == "call"){
                chatHistory[messageId] = {
                  "author": content["author"],
                  "timeStamp": timestamp,
                  "display_time": modifiedDateTime,
                  "voice":true
                };
                final Widget chatWidget = getVoiceWidget(
                  context,
                  messageId,
                  content,
                  textColor
                );
                addWidget(chatWidget, currentPosition);
                chatFileManager.saveChatHistory({
                  'messages': chatHistory,
                  'lastUpdated': DateTime.now().millisecondsSinceEpoch,
                });
                rootChange() async {
                  final String accessToken = await getRoom(content["room_id"]);
                  if(content["author"]! == instance.id){
                    await Future.delayed(Duration(milliseconds: 0), () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                        builder: (context) => VoiceChat(RoomInfo(
                            token: accessToken,
                            displayName: "",
                            userId:"${content["author"]}"))),
                      );
                    });
                  }
                }
                rootChange();
              } else {
                chatHistory[messageId] = {
                  "author": content["author"],
                  "content": messageContent,
                  "timeStamp": timestamp,
                  "edited": edited,
                  "attachments": content["attachments"],
                  "voice": false
                };
                final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
                final String displayTime = getTimeStringFormat(dateTime);
                final Widget chatWidget = FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('user_account')
                      .doc(content["author"])
                      .get(),
                  builder: (context, snapshot) {
                    String displayName = "Unknown";
                    if (snapshot.hasData && snapshot.data != null) {
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      displayName = data?['display_name'] ?? "Unknown";
                    }
                    return getMessageCard(
                      context,
                      widget,
                      textColor,
                      displayName,
                      displayTime,
                      content["author"],
                      messageContent!,
                      edited,
                      content["attachments"],
                      messageId,
                      showImage: widget.ImageControler,
                    );
                  },
                );
                addWidget(chatWidget, currentPosition);
                chatFileManager.saveChatHistory({
                  'messages': chatHistory,
                  'lastUpdated': DateTime.now().millisecondsSinceEpoch,
                });
              }
            }
            return Column(children: returnWidget);
          },
        );
  }
}
