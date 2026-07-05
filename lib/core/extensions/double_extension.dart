// ─── Bamako Thrift — Double Extensions ──────────────────────────────────────────
import 'package:flutter/material.dart';

extension DoubleExtension on double {
  // ── Spacing widgets ───────────────────────────────────────────────────
  SizedBox get widthBox => SizedBox(width: this);
  SizedBox get heightBox => SizedBox(height: this);

  // ── Padding ───────────────────────────────────────────────────────────
  EdgeInsets get allPadding => EdgeInsets.all(this);
  EdgeInsets get horizontalPadding => EdgeInsets.symmetric(horizontal: this);
  EdgeInsets get verticalPadding => EdgeInsets.symmetric(vertical: this);

  // ── Border radius ─────────────────────────────────────────────────────
  BorderRadius get rounded => BorderRadius.circular(this);
  Radius get radius => Radius.circular(this);

  // ── Formatting ────────────────────────────────────────────────────────
  String get toPriceFCFA {
    final intPart = toInt();
    final formatted = intPart.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ' ',
        );
    return '$formatted FCFA';
  }

  String toFixed(int decimals) => toStringAsFixed(decimals);

  // ── Checks ────────────────────────────────────────────────────────────
  bool get isPositive => this > 0;
  bool get isNegative => this < 0;
  bool get isZero => this == 0.0;

  double clampBetween(double min, double max) => clamp(min, max).toDouble();

  /// Arrondi à N décimales.
  double roundTo(int decimals) {
    final factor = 10.0 * decimals;
    return (this * factor).round() / factor;
  }
}
