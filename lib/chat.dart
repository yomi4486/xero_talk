import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'package:xero_talk/utils/voice_chat.dart';
import 'dart:convert';
import 'package:xero_talk/widgets/message_screen.dart';
import 'package:xero_talk/utils/message_tools.dart';
import 'package:xero_talk/widgets/image_viewer.dart';
import 'package:provider/provider.dart';
import 'package:xero_talk/tabs.dart';
import 'package:xero_talk/widgets/user_icon.dart';

Uint8List base64ToUint8List(String base64String) {
  return base64Decode(base64String);
}

class chatProvider with ChangeNotifier {
  bool showImage = false;
  late Uint8List image;
  bool isSending = false;  // 送信中の状態を追加

  void setSending(bool sending) {
    isSending = sending;
    notifyListeners();
  }

  void visibleImage(Uint8List uintimage, bool mode) {
    showImage = mode;
    image = uintimage;
    notifyListeners();
  }
  void hideImage() {
    showImage = false;
    notifyListeners();
  }

  bool editing = false;
  String editingMessageId = "";

  void editMode(String messageId, bool mode) {
    editing = mode;
    editingMessageId = messageId;
    notifyListeners();
  }

  void toggleEditMode(){
    editing = !editing;
    notifyListeners();
  }
}

class chat extends StatefulWidget {
  const chat({Key? key, required this.channelInfo,required this.snapshot}) : super(key: key);
  final Map channelInfo;
  final AsyncSnapshot snapshot;

  @override
  State<chat> createState() {
    return _chat(channelInfo: channelInfo);
  }
}

class _chat extends State<chat> {
  _chat({required this.channelInfo});
  Map channelInfo;
  String chatText = "";
  final fieldText = TextEditingController();
  FocusNode focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  List<String> images = [];
  final tabsProvider = TabsProvider();

  @override
  void initState(){
    super.initState();
  }

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

  Color lightenColor(Color color, double factor) {
    assert(factor >= 0 && factor <= 1);

    int red = color.red + ((255 - color.red) * factor).toInt();
    int green = color.green + ((255 - color.green) * factor).toInt();
    int blue = color.blue + ((255 - color.blue) * factor).toInt();

    return Color.fromARGB(color.alpha, red, green, blue);
  }

  @override
  Widget build(BuildContext context) {
    final instance = Provider.of<AuthContext>(context);
    final provider = Provider.of<TabsProvider>(context);
    final chatProvider chatScreenProvider = Provider.of<chatProvider>(context);
    final Color backgroundColor = lightenColor(instance.theme[0], .2);
    final List<Color> textColor = instance.getTextColor(backgroundColor);
    final String displayName = channelInfo["display_name"] ?? "-";
    final double baseBottomBarHeight = MediaQuery.of(context).size.height * 0.1799;
    final double imagePreviewHeight = images.isNotEmpty ? 116.0 : 0.0; // 100px + 16px margin
    final double bottomBarHeight = baseBottomBarHeight + imagePreviewHeight;
    var offset = MediaQuery.of(context).viewInsets.bottom;
    print(offset);
    if(_scrollController.hasClients){
      _scrollController.jumpTo(
        _scrollController.offset+offset,
      );
    }
    return Stack(children: [
      Scaffold(
        resizeToAvoidBottomInset: true,
        bottomSheet: BottomAppBar(
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          height: bottomBarHeight,
          notchMargin: 4.0,
          color: darkenColor(instance.theme[1].withOpacity(1), .001),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 5),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    if (images.isNotEmpty)
                      Container(
                        height: 100,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                    image: DecorationImage(
                                      image: MemoryImage(base64ToUint8List(images[index])),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          images.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.7,
                          height: 48,
                          child: TextField(
                            focusNode: focusNode,
                            cursorColor:
                                const Color.fromARGB(55, 255, 255, 255),
                            controller: fieldText,
                            onTapOutside: (_) => unfocus(), // テキスト入力欄以外をタップしたらフォーカスを外す
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.transparent),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.transparent),
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
                              fillColor: const Color.fromARGB(55, 0, 0, 0),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 16.0),
                            ),
                            onChanged: (text) {
                              chatText = text;
                            },
                          ),
                        ),
                        TextFieldTapRegion(
                          child: SizedBox(
                            height: 60,
                            child: IconButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all<Color>(
                                    Colors.transparent),
                                overlayColor: MaterialStateProperty.all<Color>(
                                    Colors.transparent),
                              ),
                              onPressed: chatScreenProvider.isSending ? null : () async {
                                if (chatScreenProvider.editing) {
                                  chatScreenProvider.toggleEditMode();
                                  await editMessage(chatScreenProvider.editingMessageId,
                                      channelInfo["id"], chatText);
                                } else {
                                  chatScreenProvider.setSending(true);
                                  try {
                                    await sendMessage(chatText, channelInfo["id"],
                                        imageList: images);
                                  } finally {
                                    chatScreenProvider.setSending(false);
                                  }
                                }
                                chatText = "";
                                images = [];
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
                                child: chatScreenProvider.isSending
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color.fromARGB(255, 255, 255, 255),
                                        ),
                                      ),
                                    )
                                  : chatScreenProvider.editing
                                    ? const Icon(
                                        Icons.edit,
                                        color: Color.fromARGB(255, 255, 255, 255),
                                      )
                                    : const ImageIcon(
                                        AssetImage("assets/images/send.png"),
                                        color: Color.fromARGB(255, 255, 255, 255),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ]
                )
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 20, left: 10),
                width: MediaQuery.of(context).size.width,
                child: Row(
                  spacing: 10,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo,
                          color: Color.fromARGB(55, 0, 0, 0), size: 30),
                      onPressed: () async {
                        try {
                          final image = await pickImage();
                          if (image != null) {
                            setState(() {
                              images.add(image);
                            });
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('画像の選択に失敗しました'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions,
                          color: Color.fromARGB(55, 0, 0, 0), size: 30),
                      onPressed: () {},
                    ),
                  ],
                )
              ),
            ]
          )
        ),
        appBar: AppBar(
          centerTitle: false,
          automaticallyImplyLeading: false,
          titleTextStyle: const TextStyle(
              color: Color.fromARGB(200, 255, 255, 255), fontSize: 20),
          backgroundColor:
              darkenColor(instance.theme[0].withOpacity(1), .001),
          leadingWidth: 0,
          title: Row(children: [
            IconButton(
              onPressed: () {
                provider.showChatScreen();
              },
              icon: const Icon(Icons.arrow_back,
                  color: Color.fromARGB(128, 255, 255, 255)
              )
            ),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Container(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20.0),
                            topRight: Radius.circular(20.0),
                          ),
                        ),
                        height: MediaQuery.of(context).size.height * 0.8,
                        child: Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: ListView(
                              children: [
                                SimpleDialogOption(
                                  // ユーザープロフィールの表示
                                  padding: const EdgeInsets.all(15),
                                  child: Column(children: [
                                    Container(
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.2,
                                      width:
                                          MediaQuery.of(context).size.width *
                                              0.2,
                                      margin: const EdgeInsets.only(left: 5),
                                      child: ClipRRect(
                                        // アイコン表示（角丸）
                                        borderRadius:
                                            BorderRadius.circular(200),
                                        child: UserIcon(userId: channelInfo["id"])
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        channelInfo["display_name"],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                          color: textColor[0],
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      )
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        "@${channelInfo["name"]}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: textColor[1],
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      )
                                    ),
                                    Container(
                                      width:
                                          MediaQuery.of(context).size.width * 0.8,
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        color:
                                            Color.fromARGB(22, 255, 255, 255),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10.0),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Align(
                                            alignment: Alignment.topLeft,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 10,
                                                left: 10,
                                                right: 10,
                                                bottom: 0
                                              ),
                                              child: Text(
                                                "自己紹介",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: textColor[1],
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.topLeft,
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Text(
                                                channelInfo["description"],
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: textColor[0],
                                                )
                                              )
                                            )
                                          )
                                        ]
                                      ),
                                    )
                                  ]
                                ),
                              ),
                            ],
                          )
                        )
                      );
                    },
                  );
                },
                child:Row(
                  mainAxisAlignment: MainAxisAlignment.start, 
                  children: [
                    SizedBox(
                      child: Row(
                        children: [
                          Container(
                            height: 34,
                            width: 34,
                            margin: const EdgeInsets.only(left: 5),
                            child: ClipRRect(
                              // アイコン表示（角丸）
                              borderRadius: BorderRadius.circular(200),
                              child: UserIcon(userId: channelInfo["id"],)
                            ),
                          ),
                        ],
                      )
                    ),
                    Container(
                      width: 150,
                      margin: const EdgeInsets.only(left: 10),
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color.fromARGB(200, 255, 255, 255),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  ]
                ),
              ),
            ]
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16, bottom: 10),
              child: Wrap(spacing: 10, runSpacing: 10, 
              children: [
                FittedBox(
                  fit: BoxFit.cover,
                  child: ClipRRect(
                    // アイコン表示（角丸）
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                        color: const Color.fromARGB(0, 255, 255, 255),
                        child: IconButton(
                            onPressed: () async {
                              await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('通話を開始'),
                                    content: const Text('通話を開始しますか？'),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('キャンセル'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: const Text('開始'),
                                        onPressed: ()async {
                                          Navigator.of(context).pop();
                                          call(channelInfo["id"]);
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.phone,
                                color:
                                    Color.fromARGB(128, 255, 255, 255)))),
                  ),
                ),
                FittedBox(
                  child: ClipRRect(
                    // アイコン表示（角丸）
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                        color: const Color.fromARGB(0, 255, 255, 255),
                        child: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.search,
                                color:
                                    Color.fromARGB(128, 255, 255, 255)))),
                  ),
                ),
              ]
            )
          )
        ],
      ),
      body:Container(
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

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child:Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height:
                          MediaQuery.of(context).size.height,
                      child: Container(
                          margin: EdgeInsets.only(
                            left: 30,
                            right: 30,
                            bottom: bottomBarHeight+118+offset),
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: MediaQuery.of(context).size.height,
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.end,
                                  children: [
                                    MessageScreen(
                                        focusNode: focusNode,
                                        scrollController:
                                            _scrollController,
                                        channelInfo: channelInfo,
                                        fieldText: fieldText,
                                        EditMode: chatScreenProvider.editMode,
                                        ImageControler:
                                            chatScreenProvider.visibleImage,
                                        snapshot: widget.snapshot,
                                    )
                                  ]
                                ),
                              ),
                            )
                          ),
                        )
                      ] // childlen 画面全体
                    )
                  ]
                ),
                ),
              ],
            )
          ),
        ),
        chatScreenProvider.showImage && chatScreenProvider.image.isNotEmpty
        ? Positioned.fill(
            child: GestureDetector(
            onTap: () {
              chatScreenProvider.hideImage();
            },
            child: Container(
              color: Colors.black.withOpacity(0.5), // 半透明のオーバーレイ
              child: Center(child: ImageViewerPage(chatScreenProvider.image, chatScreenProvider.visibleImage)),
            ),
          )
        )
        : 
        Container(),
      ]
    );
  }
}
