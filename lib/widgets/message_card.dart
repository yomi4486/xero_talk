import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert' as convert;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xero_talk/utils/message_tools.dart';

String lastMessageId = "";

class MessageCard extends StatefulWidget {
  MessageCard({Key? key, required this.focusNode, required this.scrollController,required this.channelInfo,required this.fieldText,required this.EditMode}) : super(key: key);
  final FocusNode focusNode; /// チャット入力欄のフォーカスノード
  final ScrollController scrollController;
  final Map channelInfo;
  final TextEditingController fieldText;
  final Function(String,bool) EditMode;
  @override
  _MessageCardState createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  List<Widget> returnWidget = [];
  Map chatHistory = {};
  
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
      chatHistory.remove(key);
    }catch(e){
      print(e);
    }
  }
  void editWidget(String key,String content) {
    try{
      chatHistory[key]["content"] = content;
      chatHistory[key]["edited"] = true;
    }catch(e){
      print(e);
    }
  }

  String getTimeStringFormat(DateTime dateTime){
    final DateTime nowDate = DateTime.now();
    late String today;
    if (dateTime.year == nowDate.year && dateTime.month == nowDate.month && dateTime.day == nowDate.day){
      today = "今日";
    }else{
      today = "${dateTime.year}/${dateTime.month}/${dateTime.day}";
    }
    final String modifiedDateTime = "$today, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    return modifiedDateTime;
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

  List<TextSpan> getTextSpans(String text,bool edited,List<Color>textColor) {
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
    if(edited){
      print("test");
      spans.add(
        TextSpan(
          text: " (編集済み)",
          style: TextStyle(color:textColor[0],fontSize: 10),
        ),
      );
    }
    return spans;
  }


  final AuthContext instance = AuthContext();
  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = Color.lerp(instance.theme[0], instance.theme[1], .5)!;
    double brightness = (backgroundColor.red * 0.299 + backgroundColor.green * 0.587 + backgroundColor.blue * 0.114) /255;
    List<Color> textColor = brightness > 0.5 ? [
      const Color.fromARGB(198, 79, 79, 79),
      const Color.fromARGB(200, 33, 33, 33),
      const Color.fromARGB(200, 55, 55, 55),
    ] : [
      const Color.fromARGB(198, 176, 176, 176),
      const Color.fromARGB(200, 222, 222, 222),
      const Color.fromARGB(200, 200, 200, 200),
    ];
    return StreamBuilder(
      stream: instance.bloadCast,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        var displayName = "";
        var content = {};
        try {
          if (snapshot.data != null){
            content = convert.json.decode(snapshot.data);
          }else{
            return Column(children: returnWidget);
          }
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
              bool edited = false;
              if(type == "delete_message"){
                removeWidget(messageId);
                return Column(children: returnWidget);
              }
              if(type == "edit_message"){
                editWidget(messageId,content["content"]);
                edited = true;
              }
              final String messageContent = content["content"];
              final int timestamp = content["timestamp"];
              final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
              final String modifiedDateTime = getTimeStringFormat(dateTime);
              if(type == "send_message" && lastMessageId == messageId){
                return Column(children: returnWidget,);
              }
              lastMessageId = messageId; // 最終受信を上書き
              chatHistory[messageId] = {
                "author":content["author"],
                "content":messageContent,
                "timeStamp":timestamp,
                "display_time":modifiedDateTime,
                "edited":edited,
                "display_name":displayName
              };
              returnWidget = [];
              for (var entry in chatHistory.entries){
                final Widget _chatWidget = Container(
                  margin: const EdgeInsets.only(bottom: 10, top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2000000),
                        child: Image.network(
                          "https://${dotenv.env['BASE_URL']}:8092/geticon?user_id=${entry.value["author"]}",
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
                                  entry.value["display_name"],
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
                                  child:Text( // 時刻
                                    entry.value["display_time"],
                                    style: TextStyle(
                                      color: textColor[0],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                )
                              ]
                            ),
                            Row(
                              children:[
                                SizedBox(
                                  width: MediaQuery.of(context).size.width*0.7,
                                  child:RichText(
                                    text: TextSpan(
                                      children: getTextSpans(entry.value["content"],entry.value["edited"],textColor),
                                      style:TextStyle(
                                        color: textColor[1],
                                        fontSize: 16.0
                                      ),
                                    ),
                                  ),
                                ),
                              ]
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
                final chatWidget = GestureDetector(
                  key:ValueKey(entry.key),
                  onLongPress: (){
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
                          height: MediaQuery.of(context).size.height*0.4,
                          child: Padding(
                            padding: const EdgeInsets.only(top:20),
                            child:ListView(
                              children: [
                                SimpleDialogOption( // メッセージ削除ボタン
                                  padding: const EdgeInsets.all(15),
                                  child: const Row(
                                    children:[
                                      Icon(Icons.delete),
                                      Padding(
                                        padding: EdgeInsets.only(left:5),
                                        child: Text('メッセージを削除',style: TextStyle(fontSize: 16))
                                      )
                                    ]
                                  ),
                                  onPressed: ()async {
                                    Navigator.pop(context);
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
                                                await deleteMessage(entry.key, widget.channelInfo["id"]);
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
                                  }
                                ),
                                SimpleDialogOption( // メッセージ削除ボタン
                                  padding: const EdgeInsets.all(15),
                                  child: const Row(
                                    children:[
                                      Icon(Icons.edit),
                                      Padding(
                                        padding: EdgeInsets.only(left:5),
                                        child: Text('編集',style: TextStyle(fontSize: 16))
                                      )
                                    ]
                                  ),
                                  onPressed: ()async {
                                    Navigator.pop(context);
                                    widget.focusNode.requestFocus();
                                    widget.fieldText.text = entry.value["content"];
                                    widget.EditMode(entry.key,true);
                                  }
                                ),
                              ],
                            )
                          )
                        );
                      },
                    );
                  },
                  child: _chatWidget
                );
                addWidget(chatWidget,_currentPosition);
              }
            }
            return Column(children: returnWidget);
          },
        );
      },
    );
  }
}
