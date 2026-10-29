// ─── Bamako Thrift — Champ sélecteur (bottom sheet) ────────────────────────
// Remplace un DropdownButton/DropdownButtonFormField rectangulaire par un
// champ arrondi qui ouvre un bottom sheet moderne (poignée, titre, recherche
// pour les longues listes, coche sur le choix actuel, zones tactiles
// ≥48px). Couleurs prises du thème (pas de hex figé) pour rester fidèle à
// la palette Danaya en clair ET en sombre (lot design menus, 2026-10-29).
import 'package:flutter/material.dart';

/// Ouvre le bottom sheet de sélection seul (sans le champ déclencheur), au
/// cas où un appelant veut son propre déclencheur. [SheetPickerField]
/// l'utilise déjà pour son propre tap.
Future<T?> showSheetPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T) labelOf,
  T? selected,
  bool? searchable,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SheetPickerContent<T>(
      title: title,
      options: options,
      labelOf: labelOf,
      selected: selected,
      // Recherche automatique au-delà de 8 options (listes courtes comme
      // Catégorie : pas besoin) sauf si l'appelant impose une valeur.
      searchable: searchable ?? options.length > 8,
    ),
  );
}

/// Champ complet (déclencheur + validation) : remplace directement un
/// `DropdownButtonFormField<T>` existant.
///
/// [value] est la seule source de vérité (comme l'ancien `DropdownButton`,
/// entièrement piloté par l'appelant) -- la `key` change avec [value] pour
/// forcer un nouveau `FormFieldState` à chaque changement, même quand il
/// vient d'un AUTRE champ (ex. Catégorie qui réinitialise Taille) : sans
/// ça, un `FormField` garde son état interne d'origine et n'affiche plus
/// la vraie valeur après un changement externe (piège connu de
/// `DropdownButtonFormField`).
class SheetPickerField<T> extends FormField<T> {
  SheetPickerField({
    Key? key,
    required String label,
    String? hint,
    required T? value,
    required List<T> options,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
    bool? searchable,
    IconData? prefixIcon,
    FormFieldValidator<T>? validator,
  }) : super(
          key: key ?? ValueKey(value),
          initialValue: value,
          validator: (_) => validator?.call(value),
          builder: (state) {
            return _SheetPickerFieldView<T>(
              label: label,
              hint: hint ?? label,
              value: value,
              labelOf: labelOf,
              errorText: state.errorText,
              prefixIcon: prefixIcon,
              onTap: () async {
                final picked = await showSheetPicker<T>(
                  context: state.context,
                  title: label,
                  options: options,
                  labelOf: labelOf,
                  selected: value,
                  searchable: searchable,
                );
                if (picked != null) {
                  state.didChange(picked);
                  onChanged(picked);
                }
              },
            );
          },
        );
}

class _SheetPickerFieldView<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final String Function(T) labelOf;
  final String? errorText;
  final IconData? prefixIcon;
  final VoidCallback onTap;

  const _SheetPickerFieldView({
    required this.label,
    required this.hint,
    required this.value,
    required this.labelOf,
    required this.errorText,
    required this.onTap,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final value = this.value;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon: Icon(Icons.keyboard_arrow_down_rounded,
              color: colors.onSurfaceVariant),
          filled: true,
          fillColor: isDark ? colors.surfaceContainerHighest : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          errorText: errorText,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.error, width: 1.2),
          ),
        ),
        child: Text(
          value != null ? labelOf(value) : hint,
          style: TextStyle(
            fontSize: 14,
            color: value != null
                ? (isDark ? colors.onSurface : Colors.black87)
                : (isDark ? colors.onSurfaceVariant : Colors.grey),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SheetPickerContent<T> extends StatefulWidget {
  final String title;
  final List<T> options;
  final String Function(T) labelOf;
  final T? selected;
  final bool searchable;

  const _SheetPickerContent({
    required this.title,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.searchable,
  });

  @override
  State<_SheetPickerContent<T>> createState() =>
      _SheetPickerContentState<T>();
}

class _SheetPickerContentState<T> extends State<_SheetPickerContent<T>> {
  final _searchController = TextEditingController();
  late List<T> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.options
          : widget.options
              .where((o) => widget.labelOf(o).toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ),
              if (widget.searchable) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: TextStyle(color: colors.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: Icon(Icons.search,
                          size: 20, color: colors.onSurfaceVariant),
                      filled: true,
                      fillColor: colors.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Flexible(
                child: _filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          'Aucun résultat',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: colors.outlineVariant.withOpacity(0.4),
                        ),
                        itemBuilder: (ctx, i) {
                          final option = _filtered[i];
                          final label = widget.labelOf(option);
                          final isSelected = option == widget.selected;
                          return InkWell(
                            onTap: () => Navigator.pop(context, option),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colors.onSurface,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle,
                                          color: colors.primary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom +
                    (MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
