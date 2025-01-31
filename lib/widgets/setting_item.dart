import 'package:flutter/material.dart';
import 'package:xero_talk/utils/auth_context.dart';

final AuthContext instance = AuthContext();

class SettingItem extends StatefulWidget {
  SettingItem({Key? key, required this.name, required this.defaultValue, required this.widget}) : super(key: key);
  final String name;
  final String defaultValue;
  final Widget widget;
  @override
  _SettingItemState createState() => _SettingItemState();
}

class _SettingItemState extends State<SettingItem> { 
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(// 上の枠線
          bottom: BorderSide(width: 1.0, color: Color.fromARGB(255, 195, 195, 195)), // 下の枠線
        ),
      ),
      padding:const EdgeInsets.all(16),
      child:Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.name,
            style:const TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontSize: 20,
            )
          ),
          widget.widget
        ]
      )
    );
  }
}