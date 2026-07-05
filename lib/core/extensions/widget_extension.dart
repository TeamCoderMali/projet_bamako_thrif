/// ─── Bamako Thrift — Widget Extensions ────────────────────────────────────
import 'package:flutter/material.dart';

extension WidgetExtension on Widget {
  // ── Padding ───────────────────────────────────────────────────────────
  Widget paddingAll(double value) => Padding(
        padding: EdgeInsets.all(value),
        child: this,
      );

  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) =>
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: this,
      );

  Widget paddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      Padding(
        padding: EdgeInsets.only(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
        ),
        child: this,
      );

  // ── Visibility ────────────────────────────────────────────────────────
  Widget visible(bool isVisible) => Visibility(
        visible: isVisible,
        child: this,
      );

  Widget opacity(double opacity) => Opacity(opacity: opacity, child: this);

  // ── Alignment ─────────────────────────────────────────────────────────
  Widget center() => Center(child: this);
  Widget alignLeft() => Align(alignment: Alignment.centerLeft, child: this);
  Widget alignRight() => Align(alignment: Alignment.centerRight, child: this);

  // ── Tap ───────────────────────────────────────────────────────────────
  Widget onTap(VoidCallback onTap, {bool opaque = true}) => GestureDetector(
        onTap: onTap,
        behavior:
            opaque ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
        child: this,
      );

  Widget inkWell({
    required VoidCallback onTap,
    BorderRadius? borderRadius,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: this,
      );

  // ── Sizing ────────────────────────────────────────────────────────────
  Widget expand([int flex = 1]) => Expanded(flex: flex, child: this);

  Widget sizedBox({double? width, double? height}) =>
      SizedBox(width: width, height: height, child: this);

  Widget constrained({
    double? maxWidth,
    double? maxHeight,
    double? minWidth,
    double? minHeight,
  }) =>
      ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? double.infinity,
          maxHeight: maxHeight ?? double.infinity,
          minWidth: minWidth ?? 0,
          minHeight: minHeight ?? 0,
        ),
        child: this,
      );

  // ── Decoration ────────────────────────────────────────────────────────
  Widget rounded([double radius = 8]) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: this,
      );

  // ── Sliver ────────────────────────────────────────────────────────────
  Widget get toSliver => SliverToBoxAdapter(child: this);
}
