/// Model representing a chat room
class ChatRoom {
  final int chatRoomId;
  final String name;
  final String? description;
  final String? imageUrl;
  final int? memberCount;
  final ChatMessage? lastMessage;
  final int? unreadCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChatRoom({
    required this.chatRoomId,
    required this.name,
    this.description,
    this.imageUrl,
    this.memberCount,
    this.lastMessage,
    this.unreadCount,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      chatRoomId: _parseInt(json['chat_room_id'] ?? json['chatRoomId']) ?? 0,
      name: (json['name'] ?? json['chat_room_name'] ?? '').toString(),
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      memberCount: _parseInt(json['member_count'] ?? json['memberCount']),
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: _parseInt(json['unread_count'] ?? json['unreadCount']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_room_id': chatRoomId,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'member_count': memberCount,
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}

/// Model representing a chat message
class ChatMessage {
  final int? messageId;
  final int chatRoomId;
  final int senderId;
  final String? senderName;
  final String? senderAvatar;
  final String message;
  final String? messageType; // 'text', 'image', 'location', etc.
  final DateTime? sentAt;
  final DateTime? readAt;
  final bool? isRead;
  final bool isMine; // Helper to determine if message is from current user

  ChatMessage({
    this.messageId,
    required this.chatRoomId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.message,
    this.messageType = 'text',
    this.sentAt,
    this.readAt,
    this.isRead,
    this.isMine = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    final senderId = _parseInt(json['sender_id'] ?? json['senderId'] ?? json['member_id']) ?? 0;
    
    return ChatMessage(
      messageId: _parseInt(json['message_id'] ?? json['messageId'] ?? json['id']),
      chatRoomId: _parseInt(json['chat_room_id'] ?? json['chatRoomId']) ?? 0,
      senderId: senderId,
      senderName: json['sender_name']?.toString() ?? 
                  json['senderName']?.toString() ??
                  json['first_name']?.toString(),
      senderAvatar: json['sender_avatar']?.toString() ?? 
                    json['senderAvatar']?.toString() ??
                    json['profile_photo_url']?.toString(),
      message: (json['message'] ?? json['content'] ?? '').toString(),
      messageType: json['message_type']?.toString() ?? json['messageType']?.toString() ?? 'text',
      sentAt: _parseDateTime(json['sent_at'] ?? json['sentAt'] ?? json['created_at']),
      readAt: _parseDateTime(json['read_at'] ?? json['readAt']),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      isMine: currentUserId != null && senderId == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'chat_room_id': chatRoomId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'message': message,
      'message_type': messageType,
      'sent_at': sentAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'is_read': isRead,
    };
  }

  /// Create a copy with updated isMine flag
  ChatMessage copyWithCurrentUser(int currentUserId) {
    return ChatMessage(
      messageId: messageId,
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      message: message,
      messageType: messageType,
      sentAt: sentAt,
      readAt: readAt,
      isRead: isRead,
      isMine: senderId == currentUserId,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}
