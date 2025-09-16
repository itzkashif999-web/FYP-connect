import 'dart:convert';

import 'package:fyp_connect/chats%20and%20notifications/notifications/services/get_server_key.dart';
import 'package:http/http.dart' as http;

class SendNotificationService {
  static Future<void> sendNotificationUsingApi({
    required String? token,
    required String? title,
    required String? body,
    required Map<String, dynamic>? data,
  }) async {
    String serverKey = await GetServerKey().getServerKeyToken();
    print('Server Key: $serverKey');
    String url =
        'https://fcm.googleapis.com/v1/projects/fypconnect-19dfd/messages:send';
    var headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $serverKey',
    };
    Map<String, dynamic> message = {
      "message": {
        "token": token,
        // 'topic': 'all',
        "notification": {"body": body, "title": title},
        'data': data,
      },
    };
    final http.Response response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(message),
    );
    if (response.statusCode == 200) {
      print('Notification send successfully');
    } else {
      print('❌ Failed to send notification: ${response.body}');
    }
  }
}
