class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.senderId,
    required this.senderName,
  });

  final String id;
  final String body;
  final DateTime createdAt;
  final String senderId;
  final String senderName;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        senderId: json['senderId'] as String,
        senderName: (json['sender'] as Map<String, dynamic>?)?['name'] as String? ?? '',
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
  });

  final String memberId;
  final String memberName;
  final String lastMessage;
  final DateTime lastMessageAt;

  factory MessageThread.fromJson(Map<String, dynamic> json) => MessageThread(
        memberId: json['memberId'] as String,
        memberName: json['memberName'] as String,
        lastMessage: json['lastMessage'] as String,
        lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      );
}
