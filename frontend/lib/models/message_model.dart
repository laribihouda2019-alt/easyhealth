class MessageModel {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final String messageType;
  final bool isFromAi;
  final DateTime sentAt;
  final DateTime? readAt;
  final String? imageUrl;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    this.messageType = 'text',
    this.isFromAi = false,
    required this.sentAt,
    this.readAt,
    this.imageUrl,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: json['sender_id'] ?? '',
      recipientId: json['recipient_id'] ?? '',
      content: json['content'] ?? '',
      messageType: json['message_type'] ?? 'text',
      isFromAi: json['is_from_ai'] ?? false,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'])
          : DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'recipient_id': recipientId,
      'content': content,
      'message_type': messageType,
      'image_url': imageUrl,
    };
  }
}



