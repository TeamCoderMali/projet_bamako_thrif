import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_keys.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';

/// Barre de recherche personnalisée et réutilisable.
class AppSearchBar extends StatefulWidget {
  final String? hint;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onFilterTap;
  final bool showFilter;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool autofocus;

  const AppSearchBar({
    super.key = AppKeys.searchField,
    this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.showFilter = true,
    this.readOnly = false,
    this.onTap,
    this.autofocus = false,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            autofocus: widget.autofocus,
            textInputAction: TextInputAction.search,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.hint ?? 'Rechercher des articles…',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.outline),
              suffixIcon: _hasText
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: AppSizes.iconSm),
                      onPressed: () {
                        _controller.clear();
                        widget.onChanged?.call('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        if (widget.showFilter) ...[
          const SizedBox(width: 8),
          _FilterButton(onTap: widget.onFilterTap),
        ],
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _FilterButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.md,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: AppRadius.md,
        ),
        child: const Icon(
          Icons.tune_rounded,
          color: AppColors.primary,
          size: AppSizes.iconMd,
        ),
      ),
    );
  }
}
