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
    return Column(children: [
      Text(widget.name),
      widget.widget
    ]);
  }
}