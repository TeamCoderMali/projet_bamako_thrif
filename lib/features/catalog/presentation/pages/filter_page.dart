import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  String _selectedCategorie = 'Tous';
  String _selectedEtat = 'Tous';
  RangeValues _prixRange = const RangeValues(0, 50000);

  final List<String> _categories = [
    'Tous',
    'Femme',
    'Homme',
    'Enfant',
    'Chaussures',
    'Accessoires'
  ];

  final List<String> _etats = [
    'Tous',
    'Satisfaisant',
    'Bon état',
    'Très satisfaisant',
    'État 99'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go(RouteNames.catalog),
        ),
        title: const Text(
          'Filtres',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategorie = 'Tous';
                _selectedEtat = 'Tous';
                _prixRange = const RangeValues(0, 50000);
              });
            },
            child: const Text(
              'Réinitialiser',
              style: TextStyle(color: const Color(0xFF6B7F4D)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Catégorie
            const Text(
              'Catégorie',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = cat == _selectedCategorie;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategorie = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected ? Colors.orange : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // État
            const Text(
              'État du vêtement',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _etats.map((etat) {
                final isSelected = etat == _selectedEtat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEtat = etat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected ? Colors.orange : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      etat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Prix
            const Text(
              'Prix (FCFA)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_prixRange.start.round()} FCFA',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  '${_prixRange.end.round()} FCFA',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            RangeSlider(
              values: _prixRange,
              min: 0,
              max: 50000,
              divisions: 50,
              activeColor: const Color(0xFF6B7F4D),
              onChanged: (values) {
                setState(() => _prixRange = values);
              },
            ),

            const SizedBox(height: 32),

            // Bouton appliquer
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.go(RouteNames.catalog),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7F4D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Appliquer les filtres',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
