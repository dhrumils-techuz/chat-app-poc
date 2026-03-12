enum UserPresence {
  online('online'),
  offline('offline'),
  typing('typing');

  final String value;
  const UserPresence(this.value);

  static UserPresence fromValue(String value) {
    return UserPresence.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserPresence.offline,
    );
  }

  bool get isOnline => this == UserPresence.online;
  bool get isTyping => this == UserPresence.typing;
  bool get isAvailable => this == UserPresence.online || this == UserPresence.typing;
}
