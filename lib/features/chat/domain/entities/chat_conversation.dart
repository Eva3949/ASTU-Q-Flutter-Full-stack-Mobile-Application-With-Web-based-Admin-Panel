import 'chat_message.dart';

/// Chat Conversation Entity
/// Represents a chat conversation between users
class ChatConversation {
  final int id;
  final String? title;
  final ChatUser? otherUser;
  final ChatMessage? lastMessage;
  final bool isGroupChat;
  final bool isStarred;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<ChatUser>? participants;
  final Map<String, dynamic>? metadata;

  const ChatConversation({
    required this.id,
    this.title,
    this.otherUser,
    this.lastMessage,
    this.isGroupChat = false,
    this.isStarred = false,
    this.unreadCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.participants,
    this.metadata,
  });

  /// Get display name for the conversation
  String get displayName {
    if (title != null && title!.isNotEmpty) return title!;
    if (otherUser != null) return otherUser!.name;
    return 'Unknown';
  }

  /// Get display avatar for the conversation
  String? get displayAvatar {
    return otherUser?.avatar;
  }

  /// Check if conversation has unread messages
  bool get hasUnreadMessages => unreadCount > 0;

  /// Get last message preview
  String get lastMessagePreview {
    if (lastMessage == null) return 'No messages yet';

    final message = lastMessage!;
    if (message.type == 'text') {
      return message.content.length > 50
          ? '${message.content.substring(0, 50)}...'
          : message.content;
    } else if (message.type == 'image') {
      return 'Photo';
    } else if (message.type == 'file') {
      return 'File';
    } else {
      return message.type;
    }
  }

  /// Create a copy with updated values
  ChatConversation copyWith({
    int? id,
    String? title,
    ChatUser? otherUser,
    ChatMessage? lastMessage,
    bool? isGroupChat,
    bool? isStarred,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatUser>? participants,
    Map<String, dynamic>? metadata,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      isGroupChat: isGroupChat ?? this.isGroupChat,
      isStarred: isStarred ?? this.isStarred,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participants: participants ?? this.participants,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Create from JSON
  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as int,
      title: json['title'] as String?,
      otherUser: json['other_user'] != null
          ? ChatUser.fromJson(json['other_user'] as Map<String, dynamic>)
          : null,
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      isGroupChat: json['is_group_chat'] as bool? ?? false,
      isStarred: json['is_starred'] as bool? ?? false,
      unreadCount: json['unread_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      participants: json['participants'] != null
          ? (json['participants'] as List)
                .map((p) => ChatUser.fromJson(p as Map<String, dynamic>))
                .toList()
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'other_user': otherUser?.toJson(),
      'last_message': lastMessage?.toJson(),
      'is_group_chat': isGroupChat,
      'is_starred': isStarred,
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'participants': participants?.map((p) => p.toJson()).toList(),
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatConversation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatConversation(id: $id, title: $title, unreadCount: $unreadCount)';
  }
}
