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
import 'package:provider/provider.dart'; // Ensure provider/provider.dart is imported for AuthContext
import 'package:xero_talk/utils/auth_context.dart'; // Correct import for AuthContext
import 'package:xero_talk/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xero_talk/services/block_service.dart';
import 'package:flutter/services.dart'; // クリップボード用
import 'dart:convert';
import 'package:http/http.dart' as http;

// YouTube動画情報を格納するクラス
class YouTubeVideoInfo {
  final String title;
  final String channelTitle;
  final String? description;
  final int? duration;

  YouTubeVideoInfo({
    required this.title,
    required this.channelTitle,
    this.description,
    this.duration,
  });
}

/// YouTube動画の情報を取得する関数
Future<YouTubeVideoInfo?> getYouTubeVideoInfo(String videoId) async {
  try {
    final response = await http.get(
      Uri.parse('https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return YouTubeVideoInfo(
        title: data['title'] ?? 'YouTube Video',
        channelTitle: data['author_name'] ?? 'Unknown Channel',
      );
    }
  } catch (e) {
    print('Error fetching YouTube video info: $e');
  }
  
  return null;
}

// YouTube動画のIDを抽出する関数
String? extractYouTubeVideoId(String url) {
  final RegExp regExp = RegExp(
    r'(?:youtube\.com/(?:[^/]+/.+/|(?:v|e(?:mbed)?)/|.*[?&]v=)|youtu\.be/)([^"&?/\s]{11})',
    caseSensitive: false,
  );
  final match = regExp.firstMatch(url);
  return match?.group(1);
}

// YouTube動画のサムネイルURLを取得する関数（フォールバック付き）
String getYouTubeThumbnailUrl(String videoId) {
  return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
}

// サムネイル読み込みに失敗した場合のフォールバック画像URL
List<String> getYouTubeThumbnailFallbacks(String videoId) {
  return [
    'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
    'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
    'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
    'https://img.youtube.com/vi/$videoId/default.jpg',
  ];
}

// URLからYouTube動画を検出する関数
bool isYouTubeUrl(String url) {
  return url.contains('youtube.com/watch') || 
         url.contains('youtu.be/') || 
         url.contains('youtube.com/embed/');
}

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

// YouTube動画プレビューウィジェットを作成する関数
Widget buildYouTubePreview(String url, BuildContext context) {
  final videoId = extractYouTubeVideoId(url);
  if (videoId == null) return Container();
  
  final thumbnailUrls = getYouTubeThumbnailFallbacks(videoId);
  
  return Container(
    margin: const EdgeInsets.only(top: 8),
    width: MediaQuery.of(context).size.width * 0.7,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () async {
          if (await canLaunch(url)) {
            await launch(url);
          }
        },
        child: Column(
          children: [
            // サムネイル部分
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildThumbnailImage(thumbnailUrls, 0),
                ),
                // 半透明オーバーレイ
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // 再生ボタン
                const Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      size: 64,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black54,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // YouTubeロゴ
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'YouTube',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // 動画情報部分
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.grey[50],
              child: FutureBuilder<YouTubeVideoInfo?>(
                future: getYouTubeVideoInfo(videoId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 12,
                          width: 200,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.grey,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                          ),
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          height: 12,
                          width: 120,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.grey,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                          ),
                        ),
                      ],
                    );
                  }
                  
                  final videoInfo = snapshot.data;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        videoInfo?.title ?? 'YouTube Video',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        videoInfo?.channelTitle ?? 'Unknown Channel',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// サムネイル画像を順次フォールバックして読み込むウィジェット
Widget _buildThumbnailImage(List<String> thumbnailUrls, int index) {
  if (index >= thumbnailUrls.length) {
    // すべてのURLが失敗した場合のフォールバック
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'YouTube Video',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  
  return Image.network(
    thumbnailUrls[index],
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      // 次のURLを試す
      return _buildThumbnailImage(thumbnailUrls, index + 1);
    },
  );
}

// メッセージ内のYouTube URLsを検出して取得する関数
List<String> extractYouTubeUrls(String text) {
  final RegExp urlRegExp = RegExp(
    r'(http|https):\/\/([\w.]+\/?)\S*',
    caseSensitive: false,
  );
  
  final matches = urlRegExp.allMatches(text);
  final youtubeUrls = <String>[];
  
  for (final match in matches) {
    final url = match.group(0);
    if (url != null && isYouTubeUrl(url)) {
      youtubeUrls.add(url);
    }
  }
  
  return youtubeUrls;
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
  final instance = Provider.of<AuthContext>(context, listen: false);
  final isMyMessage = author == instance.id;
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
                // YouTube動画プレビューを表示
                ...(() {
                  if (content.isNotEmpty) {
                    final youtubeUrls = extractYouTubeUrls(content);
                    return youtubeUrls.map((url) => buildYouTubePreview(url, context)).toList();
                  }
                  return <Widget>[];
                })(),
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
                          padding: const EdgeInsets.all(15),
                          child: const Row(children: [
                            Icon(Icons.copy),
                            Padding(
                              padding: EdgeInsets.only(left: 5),
                              child: Text('テキストをコピー', style: TextStyle(fontSize: 16)),
                            ),
                          ]),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: content));
                            Navigator.pop(context);
                            final _rootCtx = navigatorKey.currentState?.context;
                            if (_rootCtx != null) {
                              ScaffoldMessenger.of(_rootCtx).showSnackBar(
                                const SnackBar(content: Text('コピーしました')),
                              );
                            }
                          },
                        ),
                        if (isMyMessage) ...[
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
                                        Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(20),
                                                child: UserIcon(userId: author, size: 30)
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      displayName,
                                                      style: TextStyle(
                                                        color: textColor[2],
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (content.isNotEmpty)
                                                      Text(
                                                        content,
                                                        style: TextStyle(
                                                          color: textColor[1], 
                                                          fontSize: 14,
                                                        ),
                                                        maxLines: 3,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    if (attachments.isNotEmpty)
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 4),
                                                        child: Row(
                                                          children: [
                                                            const Icon(Icons.image, size: 16, color: Colors.grey),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              '画像 ${attachments.length}枚',
                                                              style: TextStyle(
                                                                color: Colors.grey[600],
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
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
                        ],
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
                          // 通報オプション（自分のメッセージには表示しない）
                          if (!isMyMessage)
                            SimpleDialogOption(
                                padding: const EdgeInsets.all(15),
                                child: const Row(children: [
                                  Icon(Icons.flag),
                                  Padding(
                                      padding: EdgeInsets.only(left: 5),
                                      child: Text('通報する',
                                          style: TextStyle(fontSize: 16)))
                                ]),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  // 理由入力ダイアログを表示
                                  final TextEditingController _reasonController = TextEditingController();
                                  final reported = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('メッセージを通報'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('問題のある内容を通報できます。理由を入力してください（任意）。'),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: _reasonController,
                                            maxLines: 3,
                                            decoration: const InputDecoration(
                                              hintText: '通報理由（例：誹謗中傷、わいせつ、スパム）',
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('キャンセル'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop(true);
                                          },
                                          child: const Text('送信'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (reported == true) {
                                    final reason = _reasonController.text.trim();
                                  try {
                                    print('Reporting message $messageId from $author for reason: $reason');
                                    await FirebaseFirestore.instance.collection('report_messages').add({
                                      'message_id': messageId,
                                      'channel_id': widget.channelInfo["id"],
                                      'reported_user_id': author,
                                      'reporter_user_id': instance.id,
                                      'content': content,
                                      'attachments': attachments,
                                      'reason': reason,
                                      'status': 'open',
                                      'created_at': FieldValue.serverTimestamp(),
                                    });
                                    final _rootCtx = navigatorKey.currentState?.context;
                                    if (_rootCtx != null) {

                                    // 通報後、ブロック確認ダイアログを表示
                                    final shouldBlock = await showDialog<bool>(
                                      context: _rootCtx,
                                      builder: (context) => AlertDialog(
                                        title: const Text('通報完了'),
                                        content: const Text('このユーザーをブロックしますか？ブロックすると相手からのメッセージが届かなくなります。'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('いいえ'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text('はい'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (shouldBlock == true) {
                                      try {
                                        final instance = Provider.of<AuthContext>(context, listen: false);
                                        final blockService = BlockService();
                                        await blockService.blockUser(instance.id, author);
                                        final _rootCtx = navigatorKey.currentState?.context;
                                        if (_rootCtx != null) {
                                          ScaffoldMessenger.of(_rootCtx).showSnackBar(const SnackBar(content: Text('ユーザーをブロックしました。')));
                                        }
                                      } catch (e) {
                                        debugPrint('Block failed: $e');
                                        final _rootCtx = navigatorKey.currentState?.context;
                                        if (_rootCtx != null) {
                                          ScaffoldMessenger.of(_rootCtx).showSnackBar(const SnackBar(content: Text('ブロックに失敗しました。')));
                                        }
                                      }
                                    }
                                    }
                                  } catch (e) {
                                    debugPrint('Report failed: $e');
                                    final _rootCtx = navigatorKey.currentState?.context;
                                    if (_rootCtx != null) {
                                      ScaffoldMessenger.of(_rootCtx).showSnackBar(const SnackBar(content: Text('通報に失敗しました。後でもう一度お試しください。')));
                                    }
                                  }
                                  
                                  }
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