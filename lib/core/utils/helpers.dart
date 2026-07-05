/// ─── Bamako Thrift — Helpers ───────────────────────────────────────────────
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

abstract class Helpers {
  Helpers._();

  static const _uuid = Uuid();

  // ── ID génération ──────────────────────────────────────────────────────
  static String generateId() => _uuid.v4();
  static String generateShortId() => _uuid.v4().substring(0, 8).toUpperCase();

  // ── UI ─────────────────────────────────────────────────────────────────
  static void hideKeyboard(BuildContext context) =>
      FocusScope.of(context).unfocus();

  static bool isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Size screenSize(BuildContext context) => MediaQuery.sizeOf(context);
  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;
  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;
  static EdgeInsets safePadding(BuildContext context) =>
      MediaQuery.paddingOf(context);

  // ── String ─────────────────────────────────────────────────────────────
  static String truncate(String text, {int maxLength = 50}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}…';
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // ── Math ───────────────────────────────────────────────────────────────
  static double randomDouble(double min, double max) {
    return min + Random().nextDouble() * (max - min);
  }

  static int clamp(int value, int min, int max) =>
      value.clamp(min, max);

  // ── Colors ─────────────────────────────────────────────────────────────
  static Color colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String colorToHex(Color color, {bool includeAlpha = false}) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    final a = (color.a * 255).round().toRadixString(16).padLeft(2, '0');
    return includeAlpha ? '#$a$r$g$b' : '#$r$g$b';
  }

  // ── Async ──────────────────────────────────────────────────────────────
  static Future<void> delay(Duration duration) => Future.delayed(duration);

  // ── Lists ──────────────────────────────────────────────────────────────
  static List<T> paginate<T>(List<T> list, {int page = 0, int pageSize = 20}) {
    final start = page * pageSize;
    if (start >= list.length) return [];
    final end = (start + pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }
}
