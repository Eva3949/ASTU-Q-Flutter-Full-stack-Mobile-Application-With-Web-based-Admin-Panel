import 'package:equatable/equatable.dart';

/// Question Entity representing a question in the system
class Question extends Equatable {
  final int id;
  final String title;
  final String content;
  final String subject;
  final int userId;
  final String userName;
  final String? userAvatarUrl;
  final int upvotes;
  final int downvotes;
  final int answerCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActivityAt;
  final List<String>? tags;
  final List<String> images;
  final bool isSolved;
  final int? bestAnswerId;
  final String status;

  const Question({
    required this.id,
    required this.title,
    required this.content,
    required this.subject,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.upvotes,
    required this.downvotes,
    required this.answerCount,
    required this.createdAt,
    required this.updatedAt,
    this.lastActivityAt,
    this.tags,
    this.images = const [],
    required this.isSolved,
    this.bestAnswerId,
    this.status = 'pending',
  });

  /// Create a Question from JSON
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      subject: json['subject'] as String,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String,
      userAvatarUrl: json['user_avatar_url'] as String?,
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      answerCount: json['answer_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'] as String)
          : null,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      images: json['images'] is List ? List<String>.from(json['images']) : [],
      isSolved: json['is_solved'] as bool? ?? false,
      bestAnswerId: json['best_answer_id'] as int?,
      status: json['status'] as String? ?? 'pending',
    );
  }

  /// Convert Question to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'subject': subject,
      'user_id': userId,
      'user_name': userName,
      'user_avatar_url': userAvatarUrl,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'answer_count': answerCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_activity_at': lastActivityAt?.toIso8601String(),
      'tags': tags,
      'images': images,
      'is_solved': isSolved,
      'best_answer_id': bestAnswerId,
      'status': status,
    };
  }

  /// Create a copy of Question with updated fields
  Question copyWith({
    int? id,
    String? title,
    String? content,
    String? subject,
    int? userId,
    String? userName,
    String? userAvatarUrl,
    int? upvotes,
    int? downvotes,
    int? answerCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActivityAt,
    List<String>? tags,
    List<String>? images,
    bool? isSolved,
    int? bestAnswerId,
    String? status,
  }) {
    return Question(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      subject: subject ?? this.subject,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      answerCount: answerCount ?? this.answerCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      tags: tags ?? this.tags,
      images: images ?? this.images,
      isSolved: isSolved ?? this.isSolved,
      bestAnswerId: bestAnswerId ?? this.bestAnswerId,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    subject,
    userId,
    userName,
    userAvatarUrl,
    upvotes,
    downvotes,
    answerCount,
    createdAt,
    updatedAt,
    lastActivityAt,
    tags,
    images,
    isSolved,
    bestAnswerId,
    status,
  ];

  @override
  String toString() {
    return 'Question(id: $id, title: $title, subject: $subject, userName: $userName)';
  }
}
