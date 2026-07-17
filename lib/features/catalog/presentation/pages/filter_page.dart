// ─── Bamako Thrift — Filter Page ─────────────────────────────────────────────
// Reçoit les filtres actuels via extra GoRouter et retourne les filtres choisis
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bamako_thrift/features/product/domain/entities/product_entity.dart';
import 'catalog_page.dart'; // CatalogFilters

class FilterPage extends StatefulWidget {
  final CatalogFilters? currentFilters;
  const FilterPage({super.key, this.currentFilters});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late ProductCategory? _category;
  late ProductCondition? _condition;
  late RangeValues _priceRange;

  static const double _maxPrice = 100000;

  @override
  void initState() {
    super.initState();
    final f = widget.currentFilters ?? const CatalogFilters();
    _category   = f.category;
    _condition  = f.condition;
    _priceRange = RangeValues(f.minPrice, f.maxPrice);
  }

  void _reset() {
    setState(() {
      _category   = null;
      _condition  = null;
      _priceRange = const RangeValues(0, _maxPrice);
    });
  }

  void _apply() {
    final filters = CatalogFilters(
      category:  _category,
      condition: _condition,
      minPrice:  _priceRange.start,
      maxPrice:  _priceRange.end,
    );
    context.pop(filters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Filtres',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: _reset,
            child: const Text(
              'Réinitialiser',
              style: TextStyle(color: Color(0xFF6B7F4D), fontSize: 13),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Catégorie ───────────────────────────────────────────────────
            _SectionTitle('Catégorie'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'Toutes',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                ..._catItems.map((e) => _FilterChip(
                      label: e.label,
                      selected: _category == e.value,
                      onTap: () =>
                          setState(() => _category = e.value),
                    )),
              ],
            ),

            const SizedBox(height: 22),

            // ── État ────────────────────────────────────────────────────────
            _SectionTitle('État du vêtement'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'Tous',
                  selected: _condition == null,
                  onTap: () => setState(() => _condition = null),
                ),
                ..._condItems.map((e) => _FilterChip(
                      label: e.label,
                      selected: _condition == e.value,
                      onTap: () =>
                          setState(() => _condition = e.value),
                    )),
              ],
            ),

            const SizedBox(height: 22),

            // ── Prix ────────────────────────────────────────────────────────
            _SectionTitle('Prix (FCFA)'),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fmt(_priceRange.start),
                  style: const TextStyle(
                      color: Color(0xFF5A6B3E), fontWeight: FontWeight.w600),
                ),
                Text(
                  _fmt(_priceRange.end),
                  style: const TextStyle(
                      color: Color(0xFF5A6B3E), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: _maxPrice,
              divisions: 100,
              activeColor: const Color(0xFF6B7F4D),
              inactiveColor: const Color(0xFFD6E4BE),
              labels: RangeLabels(
                _fmt(_priceRange.start),
                _fmt(_priceRange.end),
              ),
              onChanged: (v) => setState(() => _priceRange = v),
            ),

            const SizedBox(height: 30),

            // ── Bouton appliquer ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7F4D),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Appliquer les filtres',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} F';
}

// ── Données statiques ─────────────────────────────────────────────────────────
class _Item<T> {
  final T value;
  final String label;
  const _Item(this.value, this.label);
}

const _catItems = [
  _Item(ProductCategory.women,       'Femme'),
  _Item(ProductCategory.men,         'Homme'),
  _Item(ProductCategory.children,    'Enfant'),
  _Item(ProductCategory.shoes,       'Chaussures'),
  _Item(ProductCategory.accessories, 'Accessoires'),
  _Item(ProductCategory.bags,        'Sacs'),
  _Item(ProductCategory.jewelry,     'Bijoux'),
  _Item(ProductCategory.sportswear,  'Sport'),
  _Item(ProductCategory.traditional, 'Traditionnel'),
];

const _condItems = [
  _Item(ProductCondition.newWithTags,    'Neuf avec étiquette'),
  _Item(ProductCondition.newWithoutTags, 'Neuf sans étiquette'),
  _Item(ProductCondition.veryGood,       'Très bon état'),
  _Item(ProductCondition.good,           'Bon état'),
  _Item(ProductCondition.fair,           'État correct'),
];

// ── Widgets utilitaires ───────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87),
      );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6B7F4D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF6B7F4D)
                : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
