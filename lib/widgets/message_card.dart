import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert' as convert;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:url_launcher/url_launcher.dart';

String lastMessageId = "";

class MessageCard extends StatefulWidget {
  MessageCard({Key? key, required this.focusNode, required this.scrollController,required this.channelInfo}) : super(key: key);
  final FocusNode focusNode;
  final ScrollController scrollController;
  final Map channelInfo;
  @override
  _MessageCardState createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  List<Widget> returnWidget = [];
  
  void addWidget(Widget newWidget, double currentPosition) {
    returnWidget.add(newWidget); 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.scrollController.jumpTo(currentPosition); // 再描画前の座標にScrollViewを戻す
      widget.scrollController.animateTo( // 最新のメッセージまでスクロール
        widget.scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void removeWidget(String key) {
    try{
      returnWidget.removeWhere((widget) => (widget.key as ValueKey).value == key);
    }catch(e){
      print(e);
    }
  }

  @override 
  void initState() {
    super.initState();
  }

  @override void dispose() {  // チャット入力欄のフォーカスを無視する
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

  List<TextSpan> getTextSpans(String text) {
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
            style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()..onTap = () async {
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
    return spans;
  }


  final AuthContext instance = AuthContext();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: instance.bloadCast,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        var displayName = "";
        var content = {};
        try {
          content = convert.json.decode(snapshot.data);
        } catch (e) {
          print(e);
          return Column(children: returnWidget);
        }
        final a = FirebaseFirestore.instance
          .collection('user_account')
          .doc('${content["author"]}');
        ()async{ // 会話に変更があった場合ファイルに書き込み
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
              displayName = (docSnapshot.data?.data() as Map<String, dynamic>)["display_name"] ?? "No Name";
              final String type = content["type"];
              final String messageId = content["id"];
              if(type == "delete_message"){
                removeWidget(messageId);
                return Column(children: returnWidget);
              }
              final String messageContent = content["content"];
              final int timestamp = content["timestamp"];
              final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
              final DateTime nowDate = DateTime.now();
              late String today;
              if (dateTime.year == nowDate.year && dateTime.month == nowDate.month && dateTime.day == nowDate.day){
                today = "今日";
              }else{
                today = "${dateTime.year}/${dateTime.month}/${dateTime.day}";
              }
              final String modifiedDateTime = "$today, ${dateTime.hour}:${dateTime.minute}";
              
              if(lastMessageId == messageId){ // 同一のメッセージ複数受け取っている場合は無視
                return Column(children: returnWidget,);
              }
              lastMessageId = messageId; // 最終受信を上書き
              final Widget _chatWidget = Container(
                margin: const EdgeInsets.only(bottom: 10, top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2000000),
                      child: Image.network(
                        "https://${dotenv.env['BASE_URL']}:8092/geticon?user_id=${content['author']}",
                        width: MediaQuery.of(context).size.height * 0.05,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children:[
                              Text( // 名前
                                displayName,
                                style: const TextStyle(
                                  color: Color.fromARGB(200, 55, 55, 55),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 7),
                                child:Text(
                                  modifiedDateTime,
                                  style: const TextStyle(
                                    color: Color.fromARGB(198, 79, 79, 79),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              )
                            ]
                          ),
                          SizedBox( // コンテンツ
                            width: MediaQuery.of(context).size.width*0.7,
                            child:RichText(
                              text: TextSpan(
                                children: getTextSpans(messageContent),
                                style:const TextStyle(
                                  color: Color.fromARGB(200, 33, 33, 33),
                                  fontSize: 16.0
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
              final chatWidget = GestureDetector(
                key:ValueKey(messageId),
                onLongPress: (){
                  Future deleteMessage() async {
                    final sendBody = {"type": "delete_message","id": messageId,"channel":widget.channelInfo["id"]};
                    final String data = convert.json.encode(sendBody);
                    if(instance.channel.readyState == 3){ // WebSocketが接続されていない場合
                      await instance.restoreConnection().then((v){
                        instance.channel.add(data);
                      });
                      return;
                    }
                    try{
                      instance.channel.add(data);
                    }catch(e){
                      print('送信に失敗：${e}');
                    }
                  }
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return SimpleDialog(
                        title:const Text('メッセージを削除',style: TextStyle(fontSize: 16),),
                        children: <Widget>[
                          SizedBox(
                            width: MediaQuery.of(context).size.width *0.8,
                            child:Padding(
                              padding:const EdgeInsets.all(10),
                              child:_chatWidget,
                            ),
                          ),
                          SimpleDialogOption(
                            child: const Text('削除',style: TextStyle(color: Color.fromARGB(255, 255, 10, 10)),),
                            onPressed: ()async {
                              await deleteMessage();
                              Navigator.pop(context);
                            }
                          ),
                          SimpleDialogOption(
                            child: const Text('キャンセル'),
                            onPressed: ()async{
                              Navigator.pop(context);
                            }
                          ),
                        ],
                      );
                    },
                  );
                },
                child: _chatWidget
              );
              addWidget(chatWidget,_currentPosition);
            }
            return Column(children: returnWidget);
          },
        );
      },
    );
  }
}
