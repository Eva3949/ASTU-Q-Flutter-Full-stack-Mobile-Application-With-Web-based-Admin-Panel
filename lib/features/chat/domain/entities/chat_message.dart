/// Chat Message Entity
/// Represents a single message in a chat conversation
class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String type; // text, image, file, etc.
  final bool isFromCurrentUser;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    required this.isFromCurrentUser,
    required this.isRead,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  /// Create a copy with updated values
  ChatMessage copyWith({
    int? id,
    int? conversationId,
    int? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    String? type,
    bool? isFromCurrentUser,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      isFromCurrentUser: isFromCurrentUser ?? this.isFromCurrentUser,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      senderId: json['sender_id'] as int,
      senderName: json['sender_name'] as String,
      senderAvatar: json['sender_avatar'] as String?,
      content: json['content'] as String,
      type: json['type'] as String? ?? 'text',
      isFromCurrentUser: json['is_from_current_user'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'content': content,
      'type': type,
      'is_from_current_user': isFromCurrentUser,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage(id: $id, conversationId: $conversationId, senderName: $senderName, content: $content)';
  }
}

/// Chat User Entity
/// Represents a user in a chat conversation
class ChatUser {
  final int id;
  final String name;
  final String? avatar;
  final bool isOnline;
  final DateTime? lastSeen;

  const ChatUser({
    required this.id,
    required this.name,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
  });

  /// Create from JSON
  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] as int,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatUser(id: $id, name: $name, isOnline: $isOnline)';
  }
}
