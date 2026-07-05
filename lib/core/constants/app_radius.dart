/// ─── Bamako Thrift — Rayons de bordure ────────────────────────────────────
import 'package:flutter/material.dart';

abstract class AppRadius {
  AppRadius._();

  static const BorderRadius xs = BorderRadius.all(Radius.circular(4.0));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius md = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(24.0));
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(32.0));
  static const BorderRadius circle = BorderRadius.all(Radius.circular(999.0));

  // ── Top only ───────────────────────────────────────────────────────────
  static const BorderRadius topMd = BorderRadius.only(
    topLeft: Radius.circular(12.0),
    topRight: Radius.circular(12.0),
  );
  static const BorderRadius topLg = BorderRadius.only(
    topLeft: Radius.circular(16.0),
    topRight: Radius.circular(16.0),
  );
  static const BorderRadius topXl = BorderRadius.only(
    topLeft: Radius.circular(24.0),
    topRight: Radius.circular(24.0),
  );

  // ── Bottom only ────────────────────────────────────────────────────────
  static const BorderRadius bottomMd = BorderRadius.only(
    bottomLeft: Radius.circular(12.0),
    bottomRight: Radius.circular(12.0),
  );
  static const BorderRadius bottomLg = BorderRadius.only(
    bottomLeft: Radius.circular(16.0),
    bottomRight: Radius.circular(16.0),
  );

  // ── Radius values ──────────────────────────────────────────────────────
  static const Radius radiusXs = Radius.circular(4.0);
  static const Radius radiusSm = Radius.circular(8.0);
  static const Radius radiusMd = Radius.circular(12.0);
  static const Radius radiusLg = Radius.circular(16.0);
  static const Radius radiusXl = Radius.circular(24.0);
  static const Radius radiusCircle = Radius.circular(999.0);
}
