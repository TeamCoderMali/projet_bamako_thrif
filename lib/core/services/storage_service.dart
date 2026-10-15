// ─── Bamako Thrift — Storage Service (Firebase Storage upload) ───────────────
// putData(bytes) plutôt que putFile(File) : dart:io.File n'est pas vraiment
// disponible sur le web (putFile y jetait UnimplementedError — lot
// "putFile web", 2026-10-15). XFile.readAsBytes() fonctionne identiquement
// sur Android/iOS/web.
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final _uuid = const Uuid();

  StorageService(this._storage, this._auth);

  String get _currentUid => _auth.currentUser!.uid;

  /// Type MIME déduit de l'extension du fichier choisi (la compression/
  /// redimensionnement d'image_picker ne change pas le format). Repli sur
  /// jpeg, comme le contentType fixe d'avant.
  String _mimeTypeFor(String path) {
    final ext = path.toLowerCase().split('.').last.split('?').first;
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  // ── Upload plusieurs images produit ──────────────────────────────────────
  /// Retourne la liste des URLs de téléchargement.
  Future<List<String>> uploadProductImages(List<XFile> images) async {
    final urls = <String>[];
    for (final file in images) {
      final url = await uploadProductImage(file);
      urls.add(url);
    }
    return urls;
  }

  // ── Upload une image produit ─────────────────────────────────────────────
  Future<String> uploadProductImage(XFile file) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage
        .ref('product_images')
        .child(_currentUid)
        .child(fileName);

    final bytes = await file.readAsBytes();
    final metadata = SettableMetadata(
      contentType: _mimeTypeFor(file.path),
      customMetadata: {'uploadedBy': _currentUid},
    );

    final task = await ref.putData(bytes, metadata);
    return task.ref.getDownloadURL();
  }

  // ── Upload avatar profil ─────────────────────────────────────────────────
  Future<String> uploadAvatar(XFile file) async {
    final ref = _storage.ref('avatars').child('$_currentUid.jpg');

    final bytes = await file.readAsBytes();
    final metadata = SettableMetadata(contentType: _mimeTypeFor(file.path));
    final task = await ref.putData(bytes, metadata);
    return task.ref.getDownloadURL();
  }

  // ── Supprimer une image depuis son URL ───────────────────────────────────
  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Ignore si l'image n'existe plus
    }
  }

  // ── Upload avec progression (pour afficher un ProgressIndicator) ─────────
  Stream<double> uploadProductImageWithProgress(XFile file, {
    required void Function(String url) onComplete,
    required void Function(String error) onError,
  }) async* {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage
        .ref('product_images')
        .child(_currentUid)
        .child(fileName);

    final bytes = await file.readAsBytes();
    final task = ref.putData(
        bytes, SettableMetadata(contentType: _mimeTypeFor(file.path)));

    await for (final snapshot in task.snapshotEvents) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      yield progress;
      if (snapshot.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        onComplete(url);
      }
      if (snapshot.state == TaskState.error) {
        onError('Erreur lors de l\'upload');
      }
    }
  }
}
