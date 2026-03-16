import '../types/user_presence.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? designation;
  final String? department;
  final UserPresence presence;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.designation,
    this.department,
    this.presence = UserPresence.offline,
    this.lastSeenAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final lastSeen = json['lastSeenAt'] ?? json['last_seen_at'];
    final created = json['createdAt'] ?? json['created_at'];
    final updated = json['updatedAt'] ?? json['updated_at'];

    return UserModel(
      id: (json['id'] ?? json['userId'] ?? json['user_id']) as String,
      // Server may send 'fullName', 'full_name', or 'name'
      name: (json['fullName'] ?? json['full_name'] ?? json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phoneNumber: (json['phoneNumber'] ?? json['phone_number'] ?? json['phone']) as String?,
      avatarUrl: (json['avatarUrl'] ?? json['avatar_url']) as String?,
      designation: json['designation'] as String?,
      department: json['department'] as String?,
      presence: json['presence'] != null
          ? UserPresence.fromValue(json['presence'] as String)
          : UserPresence.offline,
      lastSeenAt: lastSeen != null ? DateTime.parse(lastSeen as String) : null,
      createdAt: created != null ? DateTime.parse(created as String) : null,
      updatedAt: updated != null ? DateTime.parse(updated as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'designation': designation,
      'department': department,
      'presence': presence.value,
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    String? designation,
    String? department,
    UserPresence? presence,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      presence: presence ?? this.presence,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '';
  }
}
