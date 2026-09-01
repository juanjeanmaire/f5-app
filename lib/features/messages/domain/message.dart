import '../../../shared/utils/display_name.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.senderId,
    required this.senderName,
    this.senderNickname,
  });

  final String id;
  final String body;
  final DateTime createdAt;
  final String senderId;
  final String senderName;
  final String? senderNickname;

  String get senderDisplayName => formatDisplayName(senderName, senderNickname);

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        senderId: json['senderId'] as String,
        senderName: (json['sender'] as Map<String, dynamic>?)?['name'] as String? ?? '',
        senderNickname: (json['sender'] as Map<String, dynamic>?)?['nickname'] as String?,
      );
}

/// Resumen de una conversación, tal como la ve el capitán en su listado
/// (una fila por miembro que le escribió, con el último mensaje).
class MessageThread {
  const MessageThread({
    required this.memberId,
    required this.memberName,
    required this.lastMessage,
    required this.lastMessageAt,
    this.memberNickname,
  });

  final String memberId;
  final String memberName;
  final String? memberNickname;
  final String lastMessage;
  final DateTime lastMessageAt;

  String get memberDisplayName => formatDisplayName(memberName, memberNickname);

  factory MessageThread.fromJson(Map<String, dynamic> json) => MessageThread(
        memberId: json['memberId'] as String,
        memberName: json['memberName'] as String,
        memberNickname: json['memberNickname'] as String?,
        lastMessage: json['lastMessage'] as String,
        lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      );
}
