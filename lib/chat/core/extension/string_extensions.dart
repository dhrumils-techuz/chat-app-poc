extension StringExtensions on String {
  /// Returns the string with the first letter capitalized.
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Returns the string with each word's first letter capitalized.
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalized).join(' ');
  }

  /// Returns initials from a full name (first and last).
  String get initials {
    if (isEmpty) return '';
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '';
  }

  /// Truncates the string to the given length with an ellipsis.
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Checks if the string is a valid email address.
  bool get isValidEmail {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(this);
  }

  /// Checks if the string is a valid URL.
  bool get isValidUrl {
    return Uri.tryParse(this)?.hasAbsolutePath ?? false;
  }

  /// Returns null if the string is empty or blank, otherwise returns the string.
  String? get nullIfEmpty {
    if (trim().isEmpty) return null;
    return this;
  }

  /// Extracts URLs from the string.
  List<String> get extractUrls {
    final urlPattern = RegExp(
      r'https?://[^\s<>\[\]{}|\\^`"]+',
      caseSensitive: false,
    );
    return urlPattern.allMatches(this).map((m) => m.group(0)!).toList();
  }

  /// Masks the string for privacy (e.g., email: "j***@example.com").
  String get masked {
    if (length <= 3) return '***';
    if (isValidEmail) {
      final parts = split('@');
      final name = parts[0];
      final domain = parts[1];
      final visibleChars = name.length > 2 ? 2 : 1;
      return '${name.substring(0, visibleChars)}${'*' * (name.length - visibleChars)}@$domain';
    }
    return '${substring(0, 2)}${'*' * (length - 4)}${substring(length - 2)}';
  }
}
