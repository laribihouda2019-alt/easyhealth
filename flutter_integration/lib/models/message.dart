class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String? appointmentId;
  final String messageType;
  final String content;
  final String? imageUrl;
  final bool isFromAi;
  final bool deliveryRequested;
  final String? deliveryAddress;
  final String? deliveryStatus;
  final DateTime sentAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    this.appointmentId,
    this.messageType = 'text',
    required this.content,
    this.imageUrl,
    this.isFromAi = false,
    this.deliveryRequested = false,
    this.deliveryAddress,
    this.deliveryStatus,
    required this.sentAt,
    this.readAt,
    this.metadata,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'].toString(),
      senderId: json['sender_id'] ?? '',
      recipientId: json['recipient_id'] ?? '',
      appointmentId: json['appointment_id']?.toString(),
      messageType: json['message_type'] ?? 'text',
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      isFromAi: json['is_from_ai'] ?? false,
      deliveryRequested: json['delivery_requested'] ?? false,
      deliveryAddress: json['delivery_address'],
      deliveryStatus: json['delivery_status'],
      sentAt: DateTime.parse(json['sent_at'] ?? DateTime.now().toIso8601String()),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'appointment_id': appointmentId,
      'message_type': messageType,
      'content': content,
      'image_url': imageUrl,
      'is_from_ai': isFromAi,
      'delivery_requested': deliveryRequested,
      'delivery_address': deliveryAddress,
      'delivery_status': deliveryStatus,
      'sent_at': sentAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Getters pour faciliter l'utilisation
  bool get isTextMessage => messageType == 'text';
  bool get isImageMessage => messageType == 'image';
  bool get isFileMessage => messageType == 'file';
  bool get isSystemMessage => messageType == 'system';

  bool get isRead => readAt != null;
  bool get isUnread => readAt == null;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasDelivery => deliveryRequested && deliveryAddress != null;

  String get deliveryStatusDisplay {
    switch (deliveryStatus) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return 'Non spécifiée';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(sentAt);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return '${sentAt.day}/${sentAt.month}/${sentAt.year}';
    }
  }

  @override
  String toString() {
    return 'Message(id: $id, content: $content, type: $messageType, deliveryRequested: $deliveryRequested)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Conversation {
  final UserProfile otherUser;
  final Message lastMessage;
  final bool unread;
  final int unreadCount;

  Conversation({
    required this.otherUser,
    required this.lastMessage,
    this.unread = false,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      otherUser: UserProfile.fromJson(json['other_user'] ?? {}),
      lastMessage: Message.fromJson(json['last_message'] ?? {}),
      unread: json['unread'] ?? false,
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  String get displayName => otherUser.fullName;
  String get lastMessageContent => lastMessage.content;
  String get lastMessageTime => lastMessage.timeAgo;
  bool get hasImage => lastMessage.hasImage;
  bool get hasDelivery => lastMessage.hasDelivery;
}
