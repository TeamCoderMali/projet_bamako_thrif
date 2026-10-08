// ─── Bamako Thrift — Dialogue de signalement ───────────────────────────────
// Bouton "Signaler" réutilisable (fiche article, conversation). Écrit dans
// la collection "reports", distincte de "non_conformities" (liée au flux
// de commande/relais) — un signalement n'a pas besoin d'une commande.
//
// ID déterministe {reporterId}_{targetType}_{targetId} : un seul
// signalement actif par personne et par objet signalé (voir audit du
// 2026-10-08 — l'ancien schéma en ID auto-généré permettait des envois
// illimités). L'app vérifie l'existence avant d'afficher le formulaire.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum ReportTargetType { product, chat }

const reportReasons = <String>[
  'Arnaque ou tentative de fraude',
  'Article non conforme à la description',
  'Contenu inapproprié',
  'Comportement abusif ou harcèlement',
  'Autre',
];

String _targetTypeCode(ReportTargetType t) =>
    t == ReportTargetType.product ? 'product' : 'chat';

String _reportId(String reporterId, ReportTargetType targetType, String targetId) =>
    '${reporterId}_${_targetTypeCode(targetType)}_$targetId';

Future<void> showReportDialog(
  BuildContext context, {
  required ReportTargetType targetType,
  required String targetId,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final reportId = _reportId(uid, targetType, targetId);
  final existing =
      await FirebaseFirestore.instance.collection('reports').doc(reportId).get();

  if (!context.mounted) return;

  if (existing.exists) {
    await _showAlreadyReportedSheet(context, targetType);
    return;
  }

  String? selectedReason;
  final textController = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (sheetCtx, setState) {
          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                color: Theme.of(sheetCtx).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signaler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(sheetCtx).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    targetType == ReportTargetType.product
                        ? 'Signaler cet article aux administrateurs.'
                        : 'Signaler cette conversation aux administrateurs.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(sheetCtx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...reportReasons.map(
                    (r) => RadioListTile<String>(
                      value: r,
                      groupValue: selectedReason,
                      title: Text(r, style: const TextStyle(fontSize: 14)),
                      activeColor: const Color(0xFF6B7F4D),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => selectedReason = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Détails (optionnel)',
                      border:
                          OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedReason == null
                          ? null
                          : () async {
                              await FirebaseFirestore.instance
                                  .collection('reports')
                                  .doc(reportId)
                                  .set({
                                'reporterId': uid,
                                'targetType': _targetTypeCode(targetType),
                                'targetId': targetId,
                                'reasonCode': selectedReason,
                                'reasonText': textController.text.trim(),
                                'status': 'nouveau',
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Signalement envoyé, merci.'),
                                    backgroundColor: Color(0xFF6B7F4D),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B7F4D),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape:
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Envoyer le signalement',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _showAlreadyReportedSheet(
    BuildContext context, ReportTargetType targetType) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      final colors = Theme.of(sheetCtx).colorScheme;
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: Theme.of(sheetCtx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, color: Color(0xFF6B7F4D)),
                const SizedBox(width: 8),
                Text(
                  'Déjà signalé',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              targetType == ReportTargetType.product
                  ? 'Vous avez déjà signalé cet article. Les administrateurs ont été informés.'
                  : 'Vous avez déjà signalé cette conversation. Les administrateurs ont été informés.',
              style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(sheetCtx),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
