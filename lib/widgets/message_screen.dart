import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert' as convert;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:xero_talk/utils/auth_context.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:xero_talk/widgets/create_message_card.dart';
import 'dart:typed_data';

String lastMessageId = "";

class MessageScreen extends StatefulWidget {
  MessageScreen(
      {Key? key,
      required this.focusNode,
      required this.scrollController,
      required this.channelInfo,
      required this.fieldText,
      required this.EditMode,
      required this.ImageControler})
      : super(key: key);
  final FocusNode focusNode;

  /// チャット入力欄のフォーカスノード
  final ScrollController scrollController;
  final Map channelInfo;
  final TextEditingController fieldText;
  final Function(Uint8List, bool) ImageControler;
  final Function(String, bool) EditMode;
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  List<Widget> returnWidget = [];
  Map chatHistory = {};
  void addWidget(Widget newWidget, double currentPosition) {
    returnWidget.add(newWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.scrollController.jumpTo(currentPosition); // 再描画前の座標にScrollViewを戻す
      widget.scrollController.animateTo(
        // 最新のメッセージまでスクロール
        widget.scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void removeWidget(String key) {
    try {
      returnWidget
          .removeWhere((widget) => (widget.key as ValueKey).value == key);
      chatHistory.remove(key);
    } catch (e) {
      print(e);
    }
  }

  void editWidget(String key, String content) {
    try {
      chatHistory[key]["content"] = content;
      chatHistory[key]["edited"] = true;
    } catch (e) {
      print(e);
    }
  }

  String getTimeStringFormat(DateTime dateTime) {
    final DateTime nowDate = DateTime.now();
    late String today;
    if (dateTime.year == nowDate.year &&
        dateTime.month == nowDate.month &&
        dateTime.day == nowDate.day) {
      today = "今日";
    } else {
      today = "${dateTime.year}/${dateTime.month}/${dateTime.day}";
    }
    final String modifiedDateTime =
        "$today, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    return modifiedDateTime;
  }

  @override
  void initState() {
    super.initState();
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
    return StreamBuilder(
      stream: instance.bloadCast,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        var displayName = "";
        var content = {};
        try {
          if (snapshot.data != null) {
            content = convert.json.decode(snapshot.data);
          } else {
            return Column(children: returnWidget);
          }
        } catch (e) {
          print(e);
          return Column(children: returnWidget);
        }
        final a = FirebaseFirestore.instance
            .collection('user_account')
            .doc('${content["author"]}');
        () async {
          // 会話に変更があった場合ファイルに書き込み
          final uploadFile = drive.File();
          uploadFile.name = "testfile.txt";
          await instance.googleDriveApi.files.create(
            uploadFile,
          );
        };
        final _currentPosition = widget.scrollController.position.pixels;
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
              final String messageId = content["id"];
              bool edited = false;
              if (type == "delete_message") {
                removeWidget(messageId);
                return Column(children: returnWidget);
              }
              if (type == "edit_message") {
                editWidget(messageId, content["content"]);
                edited = true;
              }
              final String messageContent = content["content"];
              final int timestamp = content["timestamp"];
              final DateTime dateTime =
                  DateTime.fromMillisecondsSinceEpoch(timestamp);
              final String modifiedDateTime = getTimeStringFormat(dateTime);
              if (type == "send_message" && lastMessageId == messageId) {
                return Column(
                  children: returnWidget,
                );
              }
              lastMessageId = messageId; // 最終受信を上書き
              if (type == "edit_message") {
                chatHistory[messageId]["content"] = messageContent;
                chatHistory[messageId]["timeStamp"] = timestamp;
                chatHistory[messageId]["edited"] = edited;
                returnWidget = []; // IDの衝突を起こすため初期化
                for (var entry in chatHistory.entries) {
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
                  addWidget(chatWidget, _currentPosition);
                }
              } else {
                chatHistory[messageId] = {
                  "author": content["author"],
                  "content": messageContent,
                  "timeStamp": timestamp,
                  "display_time": modifiedDateTime,
                  "edited": edited,
                  "display_name": displayName,
                  "attachments": content["attachments"]
                };
                final Widget chatWidget = getMessageCard(
                    context,
                    widget,
                    textColor,
                    displayName,
                    modifiedDateTime,
                    content["author"],
                    messageContent,
                    edited,
                    content["attachments"],
                    messageId,
                    showImage: widget.ImageControler);
                addWidget(chatWidget, _currentPosition);
              }
            }
            return Column(children: returnWidget);
          },
        );
      },
    );
  }
}
