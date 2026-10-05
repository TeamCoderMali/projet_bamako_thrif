// ─── Bamako Thrift — Badge "Vendeur Pro" ───────────────────────────────────
// Petit badge discret affiché uniquement quand isVendeurPro == true.
// Couleur ambre volontairement distincte du badge teal "✓ Vérifié" (pressing)
// pour ne pas créer de confusion entre les deux statuts.
import 'package:flutter/material.dart';

class VendeurProBadge extends StatelessWidget {
  const VendeurProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade700, width: 1),
      ),
      child: Text(
        '⭐ Vendeur Pro',
        style: TextStyle(
          color: Colors.amber.shade800,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
