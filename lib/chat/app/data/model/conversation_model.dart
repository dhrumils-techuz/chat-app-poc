import '../types/conversation_type.dart';
import 'group_member_model.dart';
import 'message_model.dart';
import 'user_model.dart';

class ConversationModel {
  final String id;
  final ConversationType type;
  final String? name;
  final String? avatarUrl;
  final MessageModel? lastMessage;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;
  final bool isArchived;
  final List<UserModel>? participants;
  final List<GroupMemberModel>? groupMembers;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastMessageAt;

  ConversationModel({
    required this.id,
    required this.type,
    this.name,
    this.avatarUrl,
    this.lastMessage,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
    this.isArchived = false,
    this.participants,
    this.groupMembers,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.lastMessageAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final lastMsg = json['lastMessage'] ?? json['last_message'];
    final createdAt = json['createdAt'] ?? json['created_at'];
    final updatedAt = json['updatedAt'] ?? json['updated_at'];
    final lastMsgAt = json['lastMessageAt'] ?? json['last_message_at'];

    return ConversationModel(
      id: json['id'] as String,
      type: ConversationType.fromValue(json['type'] as String),
      name: json['name'] as String?,
      avatarUrl: (json['avatarUrl'] ?? json['avatar_url']) as String?,
      lastMessage: lastMsg != null
          ? MessageModel.fromJson(lastMsg as Map<String, dynamic>)
          : null,
      unreadCount: (json['unreadCount'] ?? json['unread_count']) as int? ?? 0,
      isMuted: (json['isMuted'] ?? json['is_muted']) as bool? ?? false,
      isPinned: (json['isPinned'] ?? json['is_pinned']) as bool? ?? false,
      isArchived: (json['isArchived'] ?? json['is_archived']) as bool? ?? false,
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      groupMembers: (json['groupMembers'] ?? json['group_members']) != null
          ? ((json['groupMembers'] ?? json['group_members']) as List)
              .map((e) => GroupMemberModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      createdBy: (json['createdBy'] ?? json['created_by']) as String?,
      createdAt: createdAt != null ? DateTime.parse(createdAt as String) : null,
      updatedAt: updatedAt != null ? DateTime.parse(updatedAt as String) : null,
      lastMessageAt:
          lastMsgAt != null ? DateTime.parse(lastMsgAt as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'name': name,
      'avatarUrl': avatarUrl,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'isMuted': isMuted,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'participants': participants?.map((e) => e.toJson()).toList(),
      'groupMembers': groupMembers?.map((e) => e.toJson()).toList(),
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
    };
  }

  ConversationModel copyWith({
    String? id,
    ConversationType? type,
    String? name,
    String? avatarUrl,
    MessageModel? lastMessage,
    int? unreadCount,
    bool? isMuted,
    bool? isPinned,
    bool? isArchived,
    List<UserModel>? participants,
    List<GroupMemberModel>? groupMembers,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      participants: participants ?? this.participants,
      groupMembers: groupMembers ?? this.groupMembers,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  bool get isGroup => type.isGroup;
  bool get hasUnread => unreadCount > 0;

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (participants != null && participants!.isNotEmpty) {
      return participants!.map((p) => p.name).join(', ');
    }
    return '';
  }

  /// Returns the display name excluding the current user.
  /// For 1:1 chats, shows only the other person's name.
  /// For group chats, returns the group name or all member names.
  String displayNameFor(String currentUserId) {
    if (isGroup && name != null && name!.isNotEmpty) return name!;
    if (participants != null && participants!.isNotEmpty) {
      final others = participants!.where((p) => p.id != currentUserId).toList();
      if (others.isNotEmpty) {
        return others.map((p) => p.name).join(', ');
      }
    }
    return displayName;
  }
}
