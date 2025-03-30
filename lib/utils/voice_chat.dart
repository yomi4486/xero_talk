import 'package:firebase_auth/firebase_auth.dart';
import 'package:xero_talk/utils/auth_context.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

final AuthContext instance = AuthContext();
const Uuid uuid = Uuid();

Future<String> createRoom() async {
  String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
  final response = await http.post(
      Uri.parse("https://${dotenv.env['BASE_URL']}/voiceclient"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode(<String, String>{'token': token!}));
  if (response.statusCode != 200) {
    print('Request failed with status: ${response.statusCode}');
  }
  return response.body.toString();
}
