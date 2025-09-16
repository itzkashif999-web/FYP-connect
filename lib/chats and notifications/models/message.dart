import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  Message({
    required this.id,
    required this.toId,
    required this.msg,
    required this.read,
    required this.type,
    required this.fromId,
    //required this.sent,
    this.sent,
  });
  late final String id;
  late final String toId;
  late final String msg;
  late final String read;
  late final String fromId;
  late final Timestamp? sent;
  late final Type type;

  Message.fromJson(Map<String, dynamic> json, String docId) {
    // chatId = json['chatId'].toString();
    id = docId;
    toId = json['toId'].toString();
    msg = json['msg'].toString();
    read = json['read'].toString();
    type = json['type'].toString() == Type.image.name ? Type.image : Type.text;
    fromId = json['fromId'].toString();
    // sent = json['sent'].toString();
    sent = json['sent'] != null && json['sent'] is Timestamp
        ? json['sent'] as Timestamp
        : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    //   data['chatId'] = chatId;
    data['id'] = id;
    data['toId'] = toId;
    data['msg'] = msg;
    data['read'] = read;
    data['type'] = type.name;
    data['fromId'] = fromId;
    // data['sent'] = sent;
    data['sent'] = FieldValue.serverTimestamp();
    return data;
  }
}

enum Type { text, image }

// ai message
class AiMessage {
  String msg;
  final MessageType msgType;

  AiMessage({required this.msg, required this.msgType});
}

enum MessageType { user, bot }
