import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Indicateur de chargement global réutilisable.
class LoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;
  final double strokeWidth;

  const LoadingIndicator({
    super.key,
    this.color,
    this.size = 40.0,
    this.strokeWidth = 3.0,
  });

  /// Indicateur centré dans un Scaffold.
  static Widget centered({Color? color}) {
    return Center(child: LoadingIndicator(color: color));
  }

  /// Indicateur overlay plein écran.
  static Widget fullScreen({Color? color, String? message}) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingIndicator(color: color),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: color ?? AppColors.primary,
        strokeWidth: strokeWidth,
        strokeCap: StrokeCap.round,
      ),
    );
  }
}
