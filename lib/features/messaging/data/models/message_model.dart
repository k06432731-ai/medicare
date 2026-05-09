class MessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String senderRole; // 'patient' | 'doctor'
  final String content;
  final bool read;
  final String messageType; // 'text' | 'image' | 'document'
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.read,
    required this.messageType,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> d =
        json['attributes'] != null ? json['attributes'] as Map<String, dynamic> : json;
    return MessageModel(
      id: json['id'] as int? ?? 0,
      conversationId: d['conversationId'] as int? ?? 0,
      senderId: d['senderId'] as int? ?? 0,
      senderName: d['senderName'] as String? ?? '',
      senderRole: d['senderRole'] as String? ?? 'patient',
      content: d['content'] as String? ?? '',
      read: d['read'] as bool? ?? false,
      messageType: d['messageType'] as String? ?? 'text',
      createdAt: DateTime.tryParse(d['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
