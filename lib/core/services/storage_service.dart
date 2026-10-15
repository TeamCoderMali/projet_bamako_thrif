// ─── Bamako Thrift — Storage Service (Supabase Storage upload) ───────────────
// Upload direct vers l'API REST de Supabase Storage via dio (pas de SDK).
// Remplace Firebase Storage : le bucket n'a jamais été provisionné sur ce
// projet (forfait Spark, voir l'audit du 2026-10-15). Interface publique
// inchangée pour les appelants (uploadProductImage, uploadAvatar,
// deleteByUrl) — on pourra revenir à Firebase Storage plus tard sans
// toucher au reste de l'appli.
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../constants/supabase_storage_config.dart';
import 'logger_service.dart';

/// Photo ni décodable (ex. HEIC non converti par le navigateur) ni dans un
/// format accepté tel quel (jpeg/png/webp, < 5 Mo) — message dédié affiché
/// côté UI, distinct d'une simple erreur réseau.
class UnsupportedImageException implements Exception {
  const UnsupportedImageException();
}

class StorageService {
  final FirebaseAuth _auth;
  final _uuid = const Uuid();
  final Dio _dio = Dio();

  static const int _maxBytes = 5 * 1024 * 1024;

  StorageService(this._auth);

  String get _currentUid => _auth.currentUser!.uid;

  String _mimeTypeFor(String path) {
    final ext = path.toLowerCase().split('.').last.split('?').first;
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Redimensionne (largeur max 1600px) et recompresse en JPEG ~80%. Si le
  /// décodage échoue (ex. HEIC que le navigateur n'a pas converti), repli
  /// sur le fichier original SEULEMENT s'il est déjà jpeg/png/webp et
  /// < 5 Mo ; sinon lève UnsupportedImageException.
  Future<(Uint8List, String)> _prepareImage(
      Uint8List original, String path) async {
    try {
      final decoded = img.decodeImage(original);
      if (decoded != null) {
        final resized = decoded.width > 1600
            ? img.copyResize(decoded, width: 1600)
            : decoded;
        final jpg = Uint8List.fromList(img.encodeJpg(resized, quality: 80));
        if (jpg.length <= _maxBytes) {
          return (jpg, 'image/jpeg');
        }
        // Repli très rare (image compressée encore trop lourde) : on
        // retente juste la logique de repli ci-dessous sur l'original.
      }
    } catch (_) {
      // Décodage impossible (ex. HEIC) — on tente le repli ci-dessous.
    }

    final mime = _mimeTypeFor(path);
    final supported = {'image/jpeg', 'image/png', 'image/webp'}.contains(mime);
    if (supported && original.length <= _maxBytes) {
      return (original, mime);
    }
    throw const UnsupportedImageException();
  }

  Future<String> _upload(
    Uint8List bytes,
    String contentType,
    String objectPath, {
    void Function(double progress)? onProgress,
  }) async {
    final uri =
        '${SupabaseStorageConfig.projectUrl}/storage/v1/object/${SupabaseStorageConfig.bucket}/$objectPath';
    await _dio.post<void>(
      uri,
      data: bytes,
      options: Options(
        headers: {
          'apikey': SupabaseStorageConfig.publishableKey,
          'Authorization': 'Bearer ${SupabaseStorageConfig.publishableKey}',
          'Content-Type': contentType,
          'x-upsert': 'false',
        },
      ),
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
    );
    return '${SupabaseStorageConfig.projectUrl}/storage/v1/object/public/${SupabaseStorageConfig.bucket}/$objectPath';
  }

  // ── Upload une image produit ─────────────────────────────────────────────
  Future<String> uploadProductImage(
    XFile file, {
    void Function(double progress)? onProgress,
  }) async {
    final original = await file.readAsBytes();
    final (bytes, contentType) = await _prepareImage(original, file.path);
    final objectPath = 'product_images/$_currentUid/${_uuid.v4()}.jpg';
    return _upload(bytes, contentType, objectPath, onProgress: onProgress);
  }

  // ── Upload avatar profil ─────────────────────────────────────────────────
  // Nom de fichier unique (uuid) comme pour les articles : évite tout
  // conflit d'écrasement (la policy n'autorise que l'INSERT, pas l'UPDATE —
  // un nom fixe réutilisé échouerait dès le 2e changement d'avatar).
  // L'ancien avatar reste orphelin sur Supabase (cohérent avec la décision
  // "pas de suppression distante", voir deleteByUrl).
  Future<String> uploadAvatar(
    XFile file, {
    void Function(double progress)? onProgress,
  }) async {
    final original = await file.readAsBytes();
    final (bytes, contentType) = await _prepareImage(original, file.path);
    final objectPath = 'avatars/$_currentUid/${_uuid.v4()}.jpg';
    return _upload(bytes, contentType, objectPath, onProgress: onProgress);
  }

  // ── Suppression ───────────────────────────────────────────────────────────
  // Décision (2026-10-15, option a) : la clé publishable ne peut de toute
  // façon pas supprimer (policy INSERT seule, par design). On retire juste
  // la référence côté Firestore ailleurs dans le code ; le fichier reste
  // orphelin sur Supabase. No-op journalisé pour garder une trace si
  // quelqu'un l'appelle plus tard.
  Future<void> deleteByUrl(String url) async {
    logger.info(
        'Suppression distante ignorée (Supabase Storage, option a — pas de suppression) : $url');
  }
}
