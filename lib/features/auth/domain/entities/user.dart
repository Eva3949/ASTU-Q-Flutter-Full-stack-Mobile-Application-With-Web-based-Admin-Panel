import 'package:equatable/equatable.dart';

/// User entity representing a user in the system
class User extends Equatable {
  final int? id;
  final String name;
  final String email;
  final String? phone;
  final String? bio;
  final String? avatarUrl;
  final List<String>? roles;
  final List<String>? permissions;
  final DateTime? emailVerifiedAt;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    this.bio,
    this.avatarUrl,
    this.roles,
    this.permissions,
    this.emailVerifiedAt,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    // Handle both 'user_id' and 'id' from different API responses
    final idRaw = json['user_id'] ?? json['id'];
    final id = idRaw is String ? int.tryParse(idRaw) : (idRaw as int?);

    // Construct name from first_name and last_name if available, otherwise use username
    String name = json['username'] ?? '';
    if (json['first_name'] != null || json['last_name'] != null) {
      name = '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim();
    }
    if (name.isEmpty) name = json['name'] ?? 'User';

    return User(
      id: id,
      name: name,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['profile_picture'] ?? json['avatar_url'] as String?,
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
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'bio': bio,
      'avatar_url': avatarUrl,
      'roles': roles,
      'permissions': permissions,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of User with updated fields
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? avatarUrl,
    List<String>? roles,
    List<String>? permissions,
    DateTime? emailVerifiedAt,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
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
    roles,
    permissions,
    emailVerifiedAt,
    lastLoginAt,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email)';
  }
}
