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
    final isGroup = widget.channelInfo['type'] == 'group';
    final String? id = widget.channelInfo['id'];
    chatFileManager = ChatFileManager(
      chatFileId: null,
      friendId: isGroup ? null : id,
      groupId: isGroup ? id : null,
    );
    chatFileId = await chatFileManager.loadOrCreateChatFile();
    chatFileManager = ChatFileManager(
      chatFileId: chatFileId,
      friendId: isGroup ? null : id,
      groupId: isGroup ? id : null,
    );
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
                debugPrint(e.toString());
              }
            } else {
              final Widget chatWidget = FutureBuilder<DocumentSnapshot>(
                key:ValueKey(entry.key),
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
                  if(entry.value['attachments'] == null && entry.value['message'] == null){
                    return Container();
                  }
                  return getMessageCard(
                    context,
                    widget,
                    instance.getTextColor(Color.lerp(instance.theme[0], instance.theme[1], .5)!),
                    displayName,
                    displayTime,
                    entry.value['author'] ?? "",
                    entry.value['content'] ?? "",
                    entry.value['edited'] ?? false,
                    entry.value['attachments'] ?? [],
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
      debugPrint('Error loading chat history: $e');
    }
  }

  void addWidget(Widget newWidget, double currentPosition, {bool shouldScroll = true}) {
    // すでに同じValueKeyを持つウィジェットが存在する場合は追加しない
    if (newWidget.key is ValueKey) {
      final newKeyValue = (newWidget.key as ValueKey).value;
      final exists = returnWidget.any((w) =>
        w.key is ValueKey && (w.key as ValueKey).value == newKeyValue
      );
      if (exists) return;
    }
    returnWidget.add(newWidget);
    if (shouldScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.scrollController.jumpTo(currentPosition);
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void removeWidget(String key, {bool isLocalDelete = false}) {
    try {
      // ウィジェットの削除
      returnWidget.removeWhere((widget) {
        if (widget.key == null) return false;

        try {
          return (widget.key as ValueKey).value == key;
        } catch (e) {
          debugPrint("Key type mismatch: ${widget.key.runtimeType}");
          return false;
        }
      });

      // チャット履歴からメッセージを削除
      if (chatHistory.containsKey(key)) {
        chatHistory.remove(key);
        // すべての削除イベントでDBを更新
        debugPrint('[DEBUG] calling chatFileManager.deleteMessage($key)');
        chatFileManager.deleteMessage(key);
      }
    } catch (e) {
      debugPrint("Delete failed: $e");
    }
  }

  void editWidget(String key, String content, {bool isLocalEdit = false}) {
    // 既存のメッセージデータを保持
    final existingMessage = chatHistory[key];
    if (existingMessage != null) {
      // 既存のデータを更新
      final updatedMessage = {
        ...Map<String, dynamic>.from(existingMessage),
        "content": content,
        "edited": true,
      };
      chatHistory[key] = updatedMessage;
      // すべての編集イベントでDBを更新
      chatFileManager.updateMessage(key, updatedMessage);
      // 表示を更新
      setState(() {
        returnWidget = [];
        for (var entry in chatHistory.entries) {
          if (entry.value["voice"] == true) {
            try {
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
              addWidget(voiceWidget, 0, shouldScroll: false);
            } catch(e) {
              debugPrint('Error creating voice widget: $e');
            }
          } else {
            final Widget chatWidget = FutureBuilder<DocumentSnapshot>(
              key:ValueKey(entry.key),
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
                  getTimeStringFormat(DateTime.fromMillisecondsSinceEpoch(entry.value['timeStamp'])),
                  entry.value['author'],
                  entry.value['content'],
                  entry.value['edited'] ?? false,
                  entry.value['attachments'] ?? [],
                  entry.key,
                  showImage: widget.ImageControler,
                );
              },
            );
            addWidget(chatWidget, 0, shouldScroll: false);
          }
        }
      });
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

  // 送信直後にローカルでメッセージを即時追加するためのpublicメソッド
  void addLocalMessage(Map message) {
    setState(() {
      final String messageId = message['id'];
      chatHistory[messageId] = message;
      final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(message['timeStamp']);
      final String displayTime = getTimeStringFormat(dateTime);
      final instance = Provider.of<AuthContext>(context, listen: false);
      final textColor = instance.getTextColor(Color.lerp(instance.theme[0], instance.theme[1], .5)!);
      final Widget chatWidget = FutureBuilder<DocumentSnapshot>(
        key: ValueKey(messageId),
        future: FirebaseFirestore.instance
            .collection('user_account')
            .doc(message["author"])
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
            message["author"],
            message["content"],
            false,
            message["attachments"] ?? [],
            messageId,
            showImage: widget.ImageControler,
          );
        },
      );
      addWidget(chatWidget, widget.scrollController.position.pixels);
      // Firestoreにも即時反映
      chatFileManager.saveChatHistory({
        'messages': chatHistory,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  void updateMessageAttachments(String messageId, List<String> urls) {
    setState(() {
      if (chatHistory.containsKey(messageId)) {
        chatHistory[messageId]['attachments'] = urls;
        // Firestoreにも即時反映
        chatFileManager.saveChatHistory({
          'messages': chatHistory,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    final instance = Provider.of<AuthContext>(context);
    final Color backgroundColor =
        Color.lerp(instance.theme[0], instance.theme[1], .5)!;
    final List<Color> textColor = instance.getTextColor(backgroundColor);
    if(widget.snapshot.data == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: returnWidget
      );
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
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: returnWidget
              );
            } else if (docSnapshot.hasError) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: returnWidget
              );
            } else if (docSnapshot.hasData) {
              final String type = content["type"];

              late String messageId;

              if (type == "call"){
                messageId = content["room_id"];
              }else{
                messageId = content["id"];
              }
              if (content["author"] != instance.id && content["author"]  != widget.channelInfo['id'] && widget.channelInfo["id"] != content['channel']){ 
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: returnWidget,
                );
              }
              
              final String? messageContent = content["content"];
              final int timestamp = content["timestamp"];
              final DateTime dateTime =
                  DateTime.fromMillisecondsSinceEpoch(timestamp);
              final String modifiedDateTime = getTimeStringFormat(dateTime);
              bool edited = false;
              if (type == "delete_message") {
                debugPrint('[DEBUG] delete_message event received for $messageId');
                // 自分の削除操作かどうかを確認
                final bool isLocalDelete = content["author"] == instance.id;
                removeWidget(messageId, isLocalDelete: isLocalDelete);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: returnWidget
                );
              }
              if (type == "edit_message") {
                // 自分のメッセージかどうかを確認
                final bool isLocalEdit = content["author"] == instance.id;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  editWidget(messageId, content["content"], isLocalEdit: isLocalEdit);
                });
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: returnWidget
                );
              }

              if ((type == "send_message" || type == "call") && lastMessageId == messageId) { //　同じストリームが流れてきた時は無視
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: returnWidget,
                );
              }  
              lastMessageId = messageId; // 最終受信を上書き
              if (type == "edit_message") {
                return Column(children: returnWidget);
              } else if(type == "call"){
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
                  final String accessToken = content["token"];
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
                  "attachments": content["attachments"] ?? [],
                  "voice": false
                };
                final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
                final String displayTime = getTimeStringFormat(dateTime);
                final Widget chatWidget = FutureBuilder<DocumentSnapshot>(
                  key:ValueKey(messageId),
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
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: returnWidget
            );
          },
        );
  }
}

// _MessageScreenStateを外部から型として使うためのエイリアス
typedef MessageScreenState = _MessageScreenState;
