import '../types/message_status_type.dart';
import '../types/message_type.dart';
import 'media_attachment_model.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final MessageType type;
  final String? content;
  final MediaAttachmentModel? attachment;
  final MessageStatusType status;
  final String? replyToMessageId;
  final String? replyToContent;
  final String? replyToSenderName;
  final bool isForwarded;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? readAt;
  final DateTime? deliveredAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    required this.type,
    this.content,
    this.attachment,
    this.status = MessageStatusType.sending,
    this.replyToMessageId,
    this.replyToContent,
    this.replyToSenderName,
    this.isForwarded = false,
    this.isDeleted = false,
    required this.createdAt,
    this.updatedAt,
    this.readAt,
    this.deliveredAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] ?? json['created_at'];
    final updatedAt = json['updatedAt'] ?? json['updated_at'];
    final readAt = json['readAt'] ?? json['read_at'];
    final deliveredAt = json['deliveredAt'] ?? json['delivered_at'];

    return MessageModel(
      id: json['id'] as String,
      conversationId: (json['conversationId'] ?? json['conversation_id'] ?? '') as String,
      senderId: (json['senderId'] ?? json['sender_id'] ?? '') as String,
      senderName: (json['senderName'] ?? json['sender_name']) as String?,
      type: MessageType.fromValue(json['type'] as String),
      content: json['content'] as String?,
      attachment: json['attachment'] != null
          ? MediaAttachmentModel.fromJson(
              json['attachment'] as Map<String, dynamic>)
          : null,
      status: json['status'] != null
          ? MessageStatusType.fromValue(json['status'] as String)
          : MessageStatusType.sent,
      replyToMessageId: (json['replyToMessageId'] ?? json['reply_to_id'] ?? json['replyToId']) as String?,
      replyToContent: (json['replyToContent'] ?? json['reply_to_content']) as String?,
      replyToSenderName: (json['replyToSenderName'] ?? json['reply_to_sender_name']) as String?,
      isForwarded: (json['isForwarded'] ?? json['is_forwarded']) as bool? ?? false,
      isDeleted: (json['isDeleted'] ?? json['is_deleted']) as bool? ?? false,
      createdAt: DateTime.parse(createdAt as String),
      updatedAt: updatedAt != null ? DateTime.parse(updatedAt as String) : null,
      readAt: readAt != null ? DateTime.parse(readAt as String) : null,
      deliveredAt: deliveredAt != null ? DateTime.parse(deliveredAt as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'type': type.value,
      'content': content,
      'attachment': attachment?.toJson(),
      'status': status.value,
      'replyToMessageId': replyToMessageId,
      'replyToContent': replyToContent,
      'replyToSenderName': replyToSenderName,
      'isForwarded': isForwarded,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    MessageType? type,
    String? content,
    MediaAttachmentModel? attachment,
    MessageStatusType? status,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSenderName,
    bool? isForwarded,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? readAt,
    DateTime? deliveredAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      type: type ?? this.type,
      content: content ?? this.content,
      attachment: attachment ?? this.attachment,
      status: status ?? this.status,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      isForwarded: isForwarded ?? this.isForwarded,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  bool get hasAttachment => attachment != null;
  bool get isTextMessage => type == MessageType.text;
  bool get isSystemMessage => type == MessageType.system;
  bool get hasReply => replyToMessageId != null;
}
