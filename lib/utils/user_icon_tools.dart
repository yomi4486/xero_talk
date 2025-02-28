import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
Future<void> upload(String token,String imageData)async{
  final response = await http.post(
    Uri.parse("https://${dotenv.env['BASE_URL']}/seticon"),
    headers: <String, String>{ 'Content-Type': 'application/json; charset=UTF-8' },
    body: jsonEncode(<String,String>{'token':token,'content':imageData})
  );
  if (response.statusCode != 200) {
    print('Request failed with status: ${response.statusCode}'); 
  }
}