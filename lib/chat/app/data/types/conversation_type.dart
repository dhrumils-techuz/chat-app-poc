enum ConversationType {
  private_chat('private'),
  group('group');

  final String value;
  const ConversationType(this.value);

  static ConversationType fromValue(String value) {
    return ConversationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ConversationType.private_chat,
    );
  }

  bool get isGroup => this == ConversationType.group;
  bool get isPrivate => this == ConversationType.private_chat;
}
