enum MessageType {
  text('text'),
  image('image'),
  audio('audio'),
  document('document'),
  file('file'),
  system('system');

  final String value;
  const MessageType(this.value);

  static MessageType fromValue(String value) {
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.text,
    );
  }

  bool get isMedia =>
      this == MessageType.image ||
      this == MessageType.audio ||
      this == MessageType.document ||
      this == MessageType.file;
}
