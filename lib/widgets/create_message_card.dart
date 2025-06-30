import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xero_talk/utils/message_tools.dart';

import 'package:xero_talk/widgets/message_screen.dart';
import 'package:xero_talk/widgets/user_icon.dart';
import 'dart:convert' as convert;
import '../utils/voice_chat.dart';
import '../voice_chat.dart';
import 'dart:io'; // Ensure dart:io is imported for HttpClient
import 'package:flutter/foundation.dart'; // Ensure flutter/foundation.dart is imported for consolidateHttpClientResponseBytes

Uint8List decodeBase64(String base64String) {
  return convert.base64Decode(base64String);
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

Widget getMessageCard(
    BuildContext context,
    MessageScreen widget,
    List<Color> textColor,
    String displayName,
    String displayTime,
    String author,
    String content,
    bool edited,
    List<dynamic> attachments,
    String messageId,
    {Function(Uint8List, bool)? showImage, bool isLocal = false}) {
  final Widget _chatWidget = Container(
    // メッセージウィジェットのUI部分
    margin: const EdgeInsets.only(bottom: 10, top: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2000000),
          child: UserIcon(userId: author, size: MediaQuery.of(context).size.height * 0.05)
        ),
        Container(
          margin: const EdgeInsets.only(left: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                  // 名前
                  displayName,
                  style: TextStyle(
                    color: textColor[2],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: Text(
                      // 時刻
                      displayTime,
                      style: TextStyle(
                        color: textColor[0],
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
              ]),
              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: content.isNotEmpty
                      ? RichText(
                          text: TextSpan(
                            children: getTextSpans(content, edited, textColor),
                            style:
                                TextStyle(color: textColor[1], fontSize: 16.0),
                          ),
                        )
                      : Container(),
                ),
                if (attachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Builder(
                      builder: (context) {
                        if (attachments.length == 1) {
                          // Single image case
                          final attachment = attachments[0];
                          if (attachment == null) return Container();
                          try {
                            return GestureDetector(
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.7,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: attachment.startsWith('http')
                                      ? Image.network(
                                          attachment,
                                          fit: BoxFit.fitWidth,
                                          errorBuilder: (context, error, stackTrace) {
                                            debugPrint('Error loading image: $error');
                                            return Container(
                                              color: Colors.grey[300],
                                              height: 150,
                                              child: const Icon(Icons.error),
                                            );
                                          },
                                        )
                                      : Image.memory(
                                          decodeBase64(attachment),
                                          fit: BoxFit.fitWidth,
                                          errorBuilder: (context, error, stackTrace) {
                                            debugPrint('Error loading image: $error');
                                            return Container(
                                              color: Colors.grey[300],
                                              height: 150,
                                              child: const Icon(Icons.error),
                                            );
                                          },
                                        ),
                                ),
                              ),
                              onTap: () async {
                                if (showImage != null) {
                                  if (attachment.startsWith('http')) {
                                    try {
                                      final response = await HttpClient().getUrl(Uri.parse(attachment));
                                      final receivedBytes = await consolidateHttpClientResponseBytes(await response.close());
                                      showImage(receivedBytes, true);
                                    } catch (e) {
                                      debugPrint('Failed to load image from URL: $e');
                                    }
                                  } else {
                                    showImage(decodeBase64(attachment), true);
                                  }
                                }
                              },
                            );
                          } catch (e) {
                            debugPrint('Error processing image: $e');
                            return Container(
                              color: Colors.grey[300],
                              height: 150,
                              child: const Icon(Icons.error),
                            );
                          }
                        } else {
                          // Multiple images case (GridView)
                          final double spacing = 4;
                          final int crossAxisCount = 2;
                          final double itemWidth = (MediaQuery.of(context).size.width * 0.7 - (crossAxisCount - 1) * spacing) / crossAxisCount;
                          final double itemHeight = itemWidth; // childAspectRatio is 1
                          
                          final int numRows = (attachments.length / crossAxisCount).ceil();
                          final double gridHeight = numRows * itemHeight + (numRows - 1) * spacing;

                          return Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: gridHeight,
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                                childAspectRatio: 1,
                              ),
                              itemCount: attachments.length,
                              itemBuilder: (context, index) {
                                final attachment = attachments[index];
                                if (attachment == null) return Container();
                                
                                try {
                                  return GestureDetector(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: attachment.startsWith('http')
                                          ? Image.network(
                                              attachment,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                debugPrint('Error loading image: $error');
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.error),
                                                );
                                              },
                                            )
                                          : Image.memory(
                                              decodeBase64(attachment),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                debugPrint('Error loading image: $error');
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.error),
                                                );
                                              },
                                            ),
                                    ),
                                    onTap: () async {
                                      if (showImage != null) {
                                        if (attachment.startsWith('http')) {
                                          try {
                                            final response = await HttpClient().getUrl(Uri.parse(attachment));
                                            final receivedBytes = await consolidateHttpClientResponseBytes(await response.close());
                                            showImage(receivedBytes, true);
                                          } catch (e) {
                                            debugPrint('Failed to load image from URL: $e');
                                          }
                                        } else {
                                          showImage(decodeBase64(attachment), true);
                                        }
                                      }
                                    },
                                  );
                                } catch (e) {
                                  debugPrint('Error processing image: $e');
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.error),
                                  );
                                }
                              },
                            ),
                          );
                        }
                      },
                    ),
                  )
              ]
              ),
            ],
          ),
        ),
      ],
    ),
  );

  final chatWidget = Opacity(
    opacity: isLocal ? 0.5 : 1.0,
    child: GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                ),
                height: MediaQuery.of(context).size.height * 0.4,
                child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ListView(
                      children: [
                        SimpleDialogOption(
                            // メッセージ削除ボタン
                            padding: const EdgeInsets.all(15),
                            child: const Row(children: [
                              Icon(Icons.delete),
                              Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text('メッセージを削除',
                                      style: TextStyle(fontSize: 16)))
                            ]),
                            onPressed: () async {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return SimpleDialog(
                                    title: const Text(
                                      'メッセージを削除',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    children: <Widget>[
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: _chatWidget,
                                          ),                  
                                        ],
                                      ),
                                      SimpleDialogOption(
                                        child: const Text(
                                          '削除',
                                          style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 255, 10, 10)),
                                        ),
                                        onPressed: () async {
                                          await deleteMessage(messageId,
                                              widget.channelInfo["id"]);
                                          Navigator.pop(context);
                                        },
                                      ),
                                      SimpleDialogOption(
                                        child: const Text('キャンセル'),
                                        onPressed: () async {
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            }),
                        SimpleDialogOption(
                            // メッセージ編集ボタン
                            padding: const EdgeInsets.all(15),
                            child: const Row(children: [
                              Icon(Icons.edit),
                              Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text('編集',
                                      style: TextStyle(fontSize: 16)))
                            ]),
                            onPressed: () async {
                              Navigator.pop(context);
                              widget.focusNode.requestFocus();
                              widget.fieldText.text = content;
                              widget.EditMode(messageId, true);
                            }),
                      
                      if (attachments.isNotEmpty)
                        SimpleDialogOption(
                            padding: const EdgeInsets.all(15),
                            child: const Row(children: [
                              Icon(Icons.download),
                              Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text('画像を保存',
                                      style: TextStyle(fontSize: 16)))
                            ]),
                            onPressed: () async {
                              await saveImageToGallery(attachments[0]);
                              Navigator.pop(context);
                            }),
                    ],
                  )));
          },
        );
      },
      child: _chatWidget,
    ),
  );
  return chatWidget;
}

Widget getVoiceWidget(BuildContext context,String roomId,Map<dynamic,dynamic> content,List<Color> textColor){
  bool isNavigating = false;
  final int timestamp = content["timestamp"];
  final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final String stringDateTime = getTimeStringFormat(dateTime);
  return GestureDetector(
    child: Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 5, top: 5),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color:Color.fromARGB(50, 255, 255, 255),
      ),
      child:Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:[
          Row(
            spacing: 10,
            children: [
              Icon(Icons.call,color: textColor[2],),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "通話に参加",
                    style: TextStyle(
                      color: textColor[2],
                    )
                  ),
                  Text(
                    stringDateTime,
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor[0],
                    ),
                  ),
                ],
              )
            ],
          ),
          ClipRRect(
          borderRadius: BorderRadius.circular(2000000),
          child: UserIcon(userId: content["author"], size: 30)
        ),
        ]
      ),
    ),
    onTap: () async {
      if (isNavigating) return; // 二回目以降のクリックを無視
      isNavigating = true;

      // 確認ダイアログを表示
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('通話に参加'),
            content: const Text('通話に参加しますか？'),
            actions: <Widget>[
              TextButton(
                child: const Text('キャンセル'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('参加'),
                onPressed: ()async {
                  final token = await getRoom(roomId);
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => VoiceChat(RoomInfo(
                          token: token,
                          displayName: "",
                          userId:content["author"] ?? ""))),
                  );
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      isNavigating = false;
    },
  );
}