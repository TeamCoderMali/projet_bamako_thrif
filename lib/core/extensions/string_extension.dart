/// ─── Bamako Thrift — String Extensions ────────────────────────────────────
extension StringExtension on String {
  // ── Casing ────────────────────────────────────────────────────────────
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get capitalizeWords {
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  String get camelToSnake {
    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  // ── Validation ────────────────────────────────────────────────────────
  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(this);

  bool get isValidPhone =>
      RegExp(r'^(\+223|00223)?[567]\d{7}$').hasMatch(this);

  bool get isValidUrl =>
      RegExp(r'^(https?|ftp):\/\/[^\s/$.?#].[^\s]*$').hasMatch(this);

  bool get isNumeric => double.tryParse(this) != null;

  bool get isBlank => trim().isEmpty;

  bool get isNotBlank => trim().isNotEmpty;

  // ── Formatting ────────────────────────────────────────────────────────
  String truncate(int maxLength, {String ellipsis = '…'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  String removeSpaces() => replaceAll(' ', '');

  String get initials {
    final parts = trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Transforme "5000" en "5 000 FCFA"
  String get toPriceFCFA {
    final value = double.tryParse(this);
    if (value == null) return this;
    return '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ')} FCFA';
  }

  // ── Search ────────────────────────────────────────────────────────────
  bool containsIgnoreCase(String other) =>
      toLowerCase().contains(other.toLowerCase());

  String removeAccents() {
    const accents = 'àáâãäåèéêëìíîïòóôõöùúûüýÿñç';
    const noAccents = 'aaaaaaeeeeiiiioooooouuuuyync';
    var result = toLowerCase();
    for (int i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], noAccents[i]);
    }
    return result;
  }
}

extension NullableStringExtension on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;
  String get orEmpty => this ?? '';
}
