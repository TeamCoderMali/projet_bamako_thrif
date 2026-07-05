/// ─── Bamako Thrift — Paddings prédéfinis ──────────────────────────────────
import 'package:flutter/material.dart';

abstract class AppPadding {
  AppPadding._();

  // ── Symmetric ──────────────────────────────────────────────────────────
  static const EdgeInsets allXs = EdgeInsets.all(4.0);
  static const EdgeInsets allSm = EdgeInsets.all(8.0);
  static const EdgeInsets allMd = EdgeInsets.all(16.0);
  static const EdgeInsets allLg = EdgeInsets.all(24.0);
  static const EdgeInsets allXl = EdgeInsets.all(32.0);

  // ── Horizontal ─────────────────────────────────────────────────────────
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: 8.0);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: 24.0);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: 32.0);

  // ── Vertical ───────────────────────────────────────────────────────────
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: 4.0);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: 8.0);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: 16.0);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: 24.0);

  // ── Page ───────────────────────────────────────────────────────────────
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: 16.0);

  // ── Card ───────────────────────────────────────────────────────────────
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingSm = EdgeInsets.all(12.0);

  // ── Button ─────────────────────────────────────────────────────────────
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 14.0,
  );
  static const EdgeInsets buttonPaddingSm = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 10.0,
  );

  // ── Input ──────────────────────────────────────────────────────────────
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 14.0,
  );

  // ── List item ──────────────────────────────────────────────────────────
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );

  // ── Bottom safe ────────────────────────────────────────────────────────
  static const EdgeInsets bottomSafe = EdgeInsets.only(bottom: 16.0);
}
