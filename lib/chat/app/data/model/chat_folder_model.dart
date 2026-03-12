import '../types/folder_type.dart';

class ChatFolderModel {
  final String id;
  final String name;
  final FolderType type;
  final List<String> conversationIds;
  final int? sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChatFolderModel({
    required this.id,
    required this.name,
    required this.type,
    this.conversationIds = const [],
    this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatFolderModel.fromJson(Map<String, dynamic> json) {
    return ChatFolderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: FolderType.fromValue(json['type'] as String),
      conversationIds: json['conversationIds'] != null
          ? List<String>.from(json['conversationIds'] as List)
          : [],
      sortOrder: json['sortOrder'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'conversationIds': conversationIds,
      'sortOrder': sortOrder,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ChatFolderModel copyWith({
    String? id,
    String? name,
    FolderType? type,
    List<String>? conversationIds,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatFolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      conversationIds: conversationIds ?? this.conversationIds,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAdmin => type.isAdmin;
  int get conversationCount => conversationIds.length;
}
