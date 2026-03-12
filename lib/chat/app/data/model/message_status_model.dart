import '../types/message_status_type.dart';

class MessageStatusModel {
  final String messageId;
  final String userId;
  final MessageStatusType status;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  MessageStatusModel({
    required this.messageId,
    required this.userId,
    required this.status,
    this.deliveredAt,
    this.readAt,
  });

  factory MessageStatusModel.fromJson(Map<String, dynamic> json) {
    return MessageStatusModel(
      messageId: json['messageId'] as String,
      userId: json['userId'] as String,
      status: MessageStatusType.fromValue(json['status'] as String),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'userId': userId,
      'status': status.value,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  MessageStatusModel copyWith({
    String? messageId,
    String? userId,
    MessageStatusType? status,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return MessageStatusModel(
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
