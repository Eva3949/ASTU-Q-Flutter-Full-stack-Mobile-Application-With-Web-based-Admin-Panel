import 'package:equatable/equatable.dart';

/// Answer Entity representing an answer to a question
class Answer extends Equatable {
  final int id;
  final int questionId;
  final String content;
  final int userId;
  final String userName;
  final String? userAvatarUrl;
  final int upvotes;
  final int downvotes;
  final bool isBest;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActivityAt;

  const Answer({
    required this.id,
    required this.questionId,
    required this.content,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.upvotes,
    required this.downvotes,
    required this.isBest,
    required this.createdAt,
    required this.updatedAt,
    this.lastActivityAt,
  });

  /// Create an Answer from JSON
  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'] as int,
      questionId: json['question_id'] as int,
      content: json['content'] as String,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String,
      userAvatarUrl: json['user_avatar_url'] as String?,
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      isBest: json['is_best'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'] as String)
          : null,
    );
  }

  /// Convert Answer to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'content': content,
      'user_id': userId,
      'user_name': userName,
      'user_avatar_url': userAvatarUrl,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'is_best': isBest,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_activity_at': lastActivityAt?.toIso8601String(),
    };
  }

  /// Create a copy of Answer with updated fields
  Answer copyWith({
    int? id,
    int? questionId,
    String? content,
    int? userId,
    String? userName,
    String? userAvatarUrl,
    int? upvotes,
    int? downvotes,
    bool? isBest,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActivityAt,
  }) {
    return Answer(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      isBest: isBest ?? this.isBest,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        questionId,
        content,
        userId,
        userName,
        userAvatarUrl,
        upvotes,
        downvotes,
        isBest,
        createdAt,
        updatedAt,
        lastActivityAt,
      ];

  @override
  String toString() {
    return 'Answer(id: $id, questionId: $questionId, userName: $userName, isBest: $isBest)';
  }
}
