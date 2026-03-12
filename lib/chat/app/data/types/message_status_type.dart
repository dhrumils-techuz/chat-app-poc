enum MessageStatusType {
  sending('sending'),
  sent('sent'),
  delivered('delivered'),
  read('read'),
  failed('failed');

  final String value;
  const MessageStatusType(this.value);

  static MessageStatusType fromValue(String value) {
    return MessageStatusType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageStatusType.sending,
    );
  }

  bool get isPending => this == MessageStatusType.sending;
  bool get isFailed => this == MessageStatusType.failed;
  bool get isDelivered =>
      this == MessageStatusType.delivered || this == MessageStatusType.read;
}
