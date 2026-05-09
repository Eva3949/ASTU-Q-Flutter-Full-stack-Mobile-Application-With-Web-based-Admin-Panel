import 'package:equatable/equatable.dart';

/// User Profile Entity representing extended user information
class UserProfile extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? bio;
  final String? avatarUrl;
  final int points;
  final int level;
  final List<String>? roles;
  final List<String>? permissions;
  final DateTime? emailVerifiedAt;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int questionsCount;
  final int answersCount;
  final int bestAnswersCount;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.bio,
    this.avatarUrl,
    required this.points,
    required this.level,
    this.roles,
    this.permissions,
    this.emailVerifiedAt,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
    this.questionsCount = 0,
    this.answersCount = 0,
    this.bestAnswersCount = 0,
  });

  /// Create a UserProfile from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Handle both 'user_id' and 'id' from different API responses
    final idRaw = json['user_id'] ?? json['id'];
    final id = idRaw is String ? int.parse(idRaw) : (idRaw as int? ?? 0);

    // Construct name from first_name and last_name if available, otherwise use username
    String name = json['username'] ?? '';
    if (json['first_name'] != null || json['last_name'] != null) {
      name = '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim();
    }
    if (name.isEmpty) name = json['name'] ?? 'User';

    return UserProfile(
      id: id,
      name: name,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['profile_picture'] ?? json['avatar_url'] as String?,
      points: json['points'] is String
          ? int.parse(json['points'])
          : (json['points'] as int? ?? 0),
      level: json['level'] is String
          ? int.parse(json['level'])
          : (json['level'] as int? ?? 1),
      roles: json['role'] != null
          ? [json['role'] as String]
          : (json['roles'] as List<dynamic>?)?.cast<String>(),
      permissions: (json['permissions'] as List<dynamic>?)?.cast<String>(),
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'].toString())
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      questionsCount: json['questions_count'] as int? ?? 0,
      answersCount: json['answers_count'] as int? ?? 0,
      bestAnswersCount: json['best_answers_count'] as int? ?? 0,
    );
  }

  /// Convert UserProfile to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'bio': bio,
      'avatar_url': avatarUrl,
      'points': points,
      'level': level,
      'roles': roles,
      'permissions': permissions,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'questions_count': questionsCount,
      'answers_count': answersCount,
      'best_answers_count': bestAnswersCount,
    };
  }

  /// Create a copy of UserProfile with updated fields
  UserProfile copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? avatarUrl,
    int? points,
    int? level,
    List<String>? roles,
    List<String>? permissions,
    DateTime? emailVerifiedAt,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      points: points ?? this.points,
      level: level ?? this.level,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    bio,
    avatarUrl,
    points,
    level,
    roles,
    permissions,
    emailVerifiedAt,
    lastLoginAt,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, email: $email, points: $points, level: $level)';
  }
}
