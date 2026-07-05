/// ─── Bamako Thrift — Formatter ─────────────────────────────────────────────
import 'package:intl/intl.dart';

abstract class Formatter {
  Formatter._();

  // ── Prix ───────────────────────────────────────────────────────────────
  /// Formate en FCFA : 15 000 FCFA
  static String price(double amount, {String currency = 'FCFA'}) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount)} $currency';
  }

  static String priceCompact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M FCFA';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k FCFA';
    }
    return '${amount.toStringAsFixed(0)} FCFA';
  }

  // ── Date ───────────────────────────────────────────────────────────────
  static String date(DateTime date) =>
      DateFormat('dd/MM/yyyy', 'fr_FR').format(date);

  static String dateTime(DateTime date) =>
      DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(date);

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    if (diff.inDays < 30) return 'Il y a ${(diff.inDays / 7).floor()} sem.';
    if (diff.inDays < 365) return 'Il y a ${(diff.inDays / 30).floor()} mois';
    return 'Il y a ${(diff.inDays / 365).floor()} an(s)';
  }

  static String chatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return DateFormat('HH:mm').format(date);
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) {
      return DateFormat('EEEE', 'fr_FR').format(date);
    }
    return DateFormat('dd/MM/yy').format(date);
  }

  // ── Téléphone ──────────────────────────────────────────────────────────
  static String malianPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 8) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 8)}';
    }
    return phone;
  }

  // ── Nombre ─────────────────────────────────────────────────────────────
  static String compact(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}k';
    return number.toString();
  }

  // ── Initiales ──────────────────────────────────────────────────────────
  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // ── Taille de fichier ──────────────────────────────────────────────────
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
