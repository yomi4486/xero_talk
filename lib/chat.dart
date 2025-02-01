import 'package:flutter/material.dart';
import 'package:xero_talk/utils/auth_context.dart';

import 'package:xero_talk/widgets/message_card.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:xero_talk/utils/message_tools.dart';

class chat extends StatefulWidget {
  const chat({Key? key, required this.channelInfo}) : super(key: key);
  final Map channelInfo;

  @override
  
  State<chat> createState(){
    return _chat(channelInfo: channelInfo);
  }
}

class _chat extends State<chat>{
  _chat({required this.channelInfo});
  Map channelInfo;
  String? chatText = "";
  final AuthContext instance = AuthContext();
  final fieldText = TextEditingController();
  FocusNode focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    fieldText.dispose();
    super.dispose();
  }

  void unfocus() {
     if (focusNode.hasFocus) {
      focusNode.unfocus(); 
    } 
  }

  Color darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
  
  @override
  Widget build(BuildContext context) {
    final String displayName = channelInfo["display_name"];
    return Scaffold(
      bottomSheet: BottomAppBar(
        surfaceTintColor:Colors.transparent,
        shadowColor: Colors.transparent,
        height: MediaQuery.of(context).size.height*0.13,
        notchMargin:4.0,
        color: darkenColor(instance.theme[1].withOpacity(1), .001),
        child:Container(
          margin: const EdgeInsets.only(bottom:20),
          width: MediaQuery.of(context).size.width,
          child:Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width*0.7,
                child:TextField(
                  focusNode: focusNode,
                  cursorColor: const Color.fromARGB(55, 255, 255, 255),
                  controller: fieldText,
                  onTapOutside:(_)=>unfocus(), // テキスト入力欄以外をタップしたらフォーカスを外す
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  style: const TextStyle(                            
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color:Colors.transparent),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color:Colors.transparent),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    hintText: '$displayNameにメッセージを送信',
                    labelStyle: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 16,
                    ),
                    hintStyle: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 12,
                      overflow: TextOverflow.ellipsis,
                    ),
                    filled: true,
                    fillColor: const Color.fromARGB(55, 0, 0, 0)
                  ),
                  onChanged: (text){
                    chatText = text;
                  },
                ),
              ),
              IconButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
                  overlayColor: MaterialStateProperty.all<Color>(Colors.transparent),
                ),
                onPressed: () async {
                  sendMessage(chatText,channelInfo["id"]);
                  chatText = "";
                  fieldText.clear();
                },
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(55, 0, 0, 0), 
                        Color.fromARGB(55, 0, 0, 0)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const ImageIcon(
                    AssetImage("assets/images/send.png"),
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
            ],
          )
        )
      ),
      appBar:AppBar(
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleTextStyle: const TextStyle(
          color:Color.fromARGB(200, 255, 255, 255),
          fontSize: 20
        ),
        backgroundColor: darkenColor(instance.theme[0].withOpacity(1), .001),
        leadingWidth: 0,
        title:  Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children:[
            IconButton(
              onPressed: (){
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_back,
                color: Color.fromARGB(128, 255, 255, 255)
              )
            ),
            SizedBox(
              child: Row(
                children:[
                  Container(
                    height: 34,
                    width: 34,
                    margin:const EdgeInsets.only(left:5),
                    child:ClipRRect( // アイコン表示（角丸）
                      borderRadius: BorderRadius.circular(200),
                      child:Image.network(
                        "https://${dotenv.env['BASE_URL']}:8092/geticon?user_id=${channelInfo["id"]}",
                        fit:BoxFit.contain,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            return child; 
                          } else {
                            return Image.asset(
                              'assets/images/default_user_icon.png',
                              fit:BoxFit.contain,
                            );
                          } 
                        },
                      ),
                    ),
                  ),
                ],
              )
            ),
            Container(
              width: 150,
              margin:const EdgeInsets.only(left:10),
              child:Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color:Color.fromARGB(200, 255, 255, 255),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          ]
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16,bottom:10),
            child:Wrap(
              spacing: 10,
              runSpacing: 10,
              children:[
                FittedBox( 
                fit:BoxFit.cover,
                  child:ClipRRect( // アイコン表示（角丸）
                    borderRadius: BorderRadius.circular(30),
                    child:Container(
                      color:const Color.fromARGB(0, 255, 255, 255),
                      child:IconButton(
                        onPressed: (){},
                        icon: const Icon(
                          Icons.phone,
                          color: Color.fromARGB(128, 255, 255, 255)
                        )
                      )
                    ),
                  ),
                ),
                FittedBox(
                  child:ClipRRect( // アイコン表示（角丸）
                    borderRadius: BorderRadius.circular(30),
                    child:Container(
                      color:const Color.fromARGB(0, 255, 255, 255),
                      child:IconButton(
                        onPressed: (){},
                        icon: const Icon(Icons.search,color: Color.fromARGB(128, 255, 255, 255))
                      )
                    ),
                  ),
                ),
              ]
            )
          )
        ],
      ),
      body:WillPopScope(
        onWillPop: ()async=>true,
        child:GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! > 0) { // 左スワイプ
              Navigator.of(context).pop();
            }
          },
          child: Container(
            decoration: BoxDecoration( 
              gradient: LinearGradient( 
                begin: FractionalOffset.topLeft, 
                end: FractionalOffset.bottomRight, 
                colors: instance.theme,
                stops: const [ 
                  0.0, 
                  1.0, 
                ], 
              ), 
            ),
            height: double.infinity,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Stack(
                  clipBehavior: Clip.none,
                  children:[
                    Column( 
                      children: [
                        SizedBox(
                          width:MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height*0.76,
                          child: Container(
                            margin: const EdgeInsets.only(left:30,top: 30,right: 30,bottom: 30),
                            child:LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  controller: _scrollController,
                                  child:ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child:Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children:[
                                        MessageCard(
                                          focusNode: focusNode,
                                          scrollController: _scrollController,
                                          channelInfo: channelInfo,
                                        ) // コントローラーやノードの状態をストリームの描画部分と共有
                                      ]
                                    ),
                                  ),
                                );
                              },
                            )
                          ),
                        )
                      ] // childlen 画面全体
                    )
                  ] 
                )
              ],
            )
          )
        )
      )
    );
  }
}