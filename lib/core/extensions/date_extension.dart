/// ─── Bamako Thrift — Date Extensions ──────────────────────────────────────
extension DateTimeExtension on DateTime {
  // ── Comparison ────────────────────────────────────────────────────────
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    return difference(now).abs().inDays < 7;
  }

  bool get isPast => isBefore(DateTime.now());
  bool get isFuture => isAfter(DateTime.now());

  // ── Formatting ────────────────────────────────────────────────────────
  String get toDateString => '$day/${month.toString().padLeft(2, '0')}/$year';

  String get toTimeString =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get toDateTimeString => '$toDateString à $toTimeString';

  String get toRelative {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (isYesterday) return 'Hier à $toTimeString';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    if (diff.inDays < 30) return 'Il y a ${(diff.inDays / 7).floor()} sem.';
    if (diff.inDays < 365) return 'Il y a ${(diff.inDays / 30).floor()} mois';
    return 'Il y a ${(diff.inDays / 365).floor()} an(s)';
  }

  // ── Manipulation ──────────────────────────────────────────────────────
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay =>
      DateTime(year, month, day, 23, 59, 59, 999);

  DateTime get startOfMonth => DateTime(year, month, 1);
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  /// Timestamp Firestore compatible.
  int get toTimestamp => millisecondsSinceEpoch;
}

extension NullableDateExtension on DateTime? {
  bool get isNullOrPast =>
      this == null || this!.isBefore(DateTime.now());
}
