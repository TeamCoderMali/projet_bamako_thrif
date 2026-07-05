/// ─── Bamako Thrift — Int Extensions ────────────────────────────────────────
import 'package:flutter/material.dart';

extension IntExtension on int {
  // ── Spacing widgets ───────────────────────────────────────────────────
  SizedBox get widthBox => SizedBox(width: toDouble());
  SizedBox get heightBox => SizedBox(height: toDouble());

  // ── Duration ──────────────────────────────────────────────────────────
  Duration get milliseconds => Duration(milliseconds: this);
  Duration get seconds => Duration(seconds: this);
  Duration get minutes => Duration(minutes: this);
  Duration get hours => Duration(hours: this);
  Duration get days => Duration(days: this);

  // ── Border radius ─────────────────────────────────────────────────────
  BorderRadius get rounded => BorderRadius.circular(toDouble());

  // ── Formatting ────────────────────────────────────────────────────────
  String get compact {
    if (this >= 1000000) return '${(this / 1000000).toStringAsFixed(1)}M';
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}k';
    return toString();
  }

  String toOrdinal() {
    if (this == 1) return '${this}er';
    return '${this}ème';
  }

  bool get isEven => this % 2 == 0;
  bool get isOdd => this % 2 != 0;
  bool get isPositive => this > 0;
  bool get isNegative => this < 0;
  bool get isZero => this == 0;
}
