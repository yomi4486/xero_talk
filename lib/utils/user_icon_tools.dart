import 'package:http/http.dart' as http;
import 'dart:convert';
Future<void> upload(String token,String imageData)async{
  final response = await http.post(
    Uri.parse('https://xenfo.org:8092/seticon'),
    headers: <String, String>{ 'Content-Type': 'application/json; charset=UTF-8' },
    body: jsonEncode(<String,String>{'token':token,'content':imageData})
  );
  if (response.statusCode == 200) { 
    print('Request successful'); }
  else { 
    print('Request failed with status: ${response.statusCode}'); 
  }
}