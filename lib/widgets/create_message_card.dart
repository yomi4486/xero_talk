import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xero_talk/utils/message_tools.dart';

import 'package:xero_talk/widgets/message_screen.dart';
import 'dart:typed_data';
import 'dart:convert' as convert;
import 'dart:ui' as ui;
import '../utils/voice_chat.dart';
import '../voice_chat.dart';

Uint8List decodeBase64(String base64String) {
  return convert.base64Decode(base64String);
}

class Base64ImageWidget extends StatefulWidget {
  final List<dynamic>? base64Strings;

  Base64ImageWidget({required this.base64Strings});

  @override
  _Base64ImageWidgetState createState() => _Base64ImageWidgetState();
}

class _Base64ImageWidgetState extends State<Base64ImageWidget> {
  double? imageHeight;
  double? imageWidth;

  @override
  void initState() {
    super.initState();
    if (widget.base64Strings != null && widget.base64Strings!.isNotEmpty) {
      decodeImageSize(widget.base64Strings![0]);
    }
  }

  Future<void> decodeImageSize(String base64String) async {
    Uint8List imageBytes = decodeBase64(base64String);
    ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    setState(() {
      imageHeight = frameInfo.image.height.toDouble();
      imageWidth = frameInfo.image.width.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.base64Strings != null && widget.base64Strings!.isNotEmpty) {
      Uint8List imageBytes = decodeBase64(widget.base64Strings![0]);
      return Container(
        padding: const EdgeInsets.only(top: 10),
        width: MediaQuery.of(context).size.width * 0.7,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Image.memory(
            imageBytes,
            height: imageHeight != null &&
                    imageWidth != null &&
                    imageHeight! / imageWidth! > 2
                ? 400
                : null,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container();
    }
  }
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
    {Function(Uint8List, bool)? showImage}) {
  final Widget _chatWidget = Container(
    // メッセージウィジェットのUI部分
    margin: const EdgeInsets.only(bottom: 10, top: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2000000),
          child: Image.network(
            "https://${dotenv.env['BASE_URL']}/geticon?user_id=${author}",
            width: MediaQuery.of(context).size.height * 0.05,
          ),
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
              Column(children: [
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
                GestureDetector(
                  child: Base64ImageWidget(base64Strings: attachments),
                  onTap: () {
                    showImage!(decodeBase64(attachments[0]), true);
                  },
                )
              ]),
            ],
          ),
        ),
      ],
    ),
  );

  final chatWidget = GestureDetector(
      // メッセージのウィジェットのIDとタップイベントハンドラーを担当
      key: ValueKey(messageId),
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
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.8,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: _chatWidget,
                                        ),
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
                                          }),
                                      SimpleDialogOption(
                                          child: const Text('キャンセル'),
                                          onPressed: () async {
                                            Navigator.pop(context);
                                          }),
                                    ],
                                  );
                                },
                              );
                            }),
                        SimpleDialogOption(
                            // メッセージ削除ボタン
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
                        attachments.isNotEmpty
                            ? SimpleDialogOption(
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
                                })
                            : Container(),
                      ],
                    )));
          },
        );
      },
      child: _chatWidget);
  return chatWidget;
}

Widget getVoiceWidget(BuildContext context,String roomId){
  return GestureDetector(child: Container(child:Text("通話に参加"),),onTap: ()async{
    final token = await getRoom(roomId);
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => VoiceChat(RoomInfo(
              token: token,
              displayName: "",
              iconUrl:""))),
    );
  },);
}