enum FolderType {
  admin('admin'),
  user('user');

  final String value;
  const FolderType(this.value);

  static FolderType fromValue(String value) {
    return FolderType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FolderType.user,
    );
  }

  bool get isAdmin => this == FolderType.admin;
}
