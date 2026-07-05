import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';

/// AppBar personnalisée et réutilisable.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation = 0,
    this.onBackPressed,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppColors.surface,
      elevation: elevation,
      scrolledUnderElevation: 1,
      leading: showBackButton
          ? leading ??
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: AppSizes.iconMd),
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              )
          : leading,
      automaticallyImplyLeading: showBackButton,
      titleTextStyle: AppTextStyles.titleLarge,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        AppSizes.appBarHeight + (bottom?.preferredSize.height ?? 0),
      );
}
