import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UserIcon extends StatefulWidget {
  final String userId;
  final double? size;
  const UserIcon({required this.userId, this.size, Key? key}): super(key: key);

  @override
  _UserIconState createState() => _UserIconState();
}

class _UserIconState extends State<UserIcon> {
  late Future<Uint8List?> _imageFuture;
  final Box _cacheBox = Hive.box('imageCache');

  @override
  void initState() {
    super.initState();
    _imageFuture = _getImageData();
  }

  Future<Uint8List?> _getImageData() async {
    // すでにキャッシュがあればそれを返す
    if (_cacheBox.containsKey(widget.userId)) {
      return _cacheBox.get(widget.userId) as Uint8List?;
    }
    // キャッシュがなければFirebase Storageから取得
    try {
      Uint8List? data = await FirebaseStorage.instance
          .ref()
          .child("usericons/${widget.userId}")
          .getData();
      if (data != null) {
        _cacheBox.put(widget.userId, data);
      }
      return data;
    } catch (e) {
      print("Error fetching image: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Image.asset('assets/images/default_user_icon.png', width: widget.size, height: widget.size);
        } else if (snapshot.hasError || snapshot.data == null) {
          return Image.asset('assets/images/default_user_icon.png', width: widget.size, height: widget.size);
        } else {
          return Image.memory(snapshot.data!,width: widget.size, height: widget.size);
        }
      },
    );
  }
}
