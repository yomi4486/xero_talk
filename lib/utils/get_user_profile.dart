import 'package:cloud_firestore/cloud_firestore.dart';
Future<Map<String, dynamic>> getUserProfile(String id)async{
  try{
    final DocumentSnapshot<Map<String, dynamic>> data = await FirebaseFirestore.instance.collection('user_account').doc(id).get();
    final docData = data.data();

    final userProfile = data.data() as Map<String, dynamic>;
    if (docData != null && docData.containsKey("color_theme")) {
      if (docData.isEmpty) {
        userProfile["description"] = "自己紹介はありません。";
      }
    }
    userProfile["id"] = id;
    return userProfile;
  }catch(e){
    final Map<String, dynamic> userProfile = {'id':'0','name':'unknown','display_name':'unknown'};
    return userProfile;
  }
}