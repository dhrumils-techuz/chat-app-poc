class GroupMemberModel {
  final String userId;
  final String name;
  final String? avatarUrl;
  final GroupRole role;
  final DateTime? joinedAt;

  GroupMemberModel({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.role = GroupRole.member,
    this.joinedAt,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      userId: json['userId'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] != null
          ? GroupRole.fromValue(json['role'] as String)
          : GroupRole.member,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'avatarUrl': avatarUrl,
      'role': role.value,
      'joinedAt': joinedAt?.toIso8601String(),
    };
  }

  GroupMemberModel copyWith({
    String? userId,
    String? name,
    String? avatarUrl,
    GroupRole? role,
    DateTime? joinedAt,
  }) {
    return GroupMemberModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  bool get isAdmin => role == GroupRole.admin;
}

enum GroupRole {
  admin('admin'),
  member('member');

  final String value;
  const GroupRole(this.value);

  static GroupRole fromValue(String value) {
    return GroupRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GroupRole.member,
    );
  }
}
