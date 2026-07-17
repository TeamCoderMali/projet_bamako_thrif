// ─── Bamako Thrift — Storage Service (Firebase Storage upload) ───────────────
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final _uuid = const Uuid();

  StorageService(this._storage, this._auth);

  String get _currentUid => _auth.currentUser!.uid;

  // ── Upload plusieurs images produit ──────────────────────────────────────
  /// Retourne la liste des URLs de téléchargement.
  Future<List<String>> uploadProductImages(List<File> images) async {
    final urls = <String>[];
    for (final file in images) {
      final url = await uploadProductImage(file);
      urls.add(url);
    }
    return urls;
  }

  // ── Upload une image produit ─────────────────────────────────────────────
  Future<String> uploadProductImage(File file) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage
        .ref('product_images')
        .child(_currentUid)
        .child(fileName);

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'uploadedBy': _currentUid},
    );

    final task = await ref.putFile(file, metadata);
    return task.ref.getDownloadURL();
  }

  // ── Upload avatar profil ─────────────────────────────────────────────────
  Future<String> uploadAvatar(File file) async {
    final ref = _storage.ref('avatars').child('$_currentUid.jpg');

    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final task = await ref.putFile(file, metadata);
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
  Stream<double> uploadProductImageWithProgress(File file, {
    required void Function(String url) onComplete,
    required void Function(String error) onError,
  }) async* {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage
        .ref('product_images')
        .child(_currentUid)
        .child(fileName);

    final task = ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));

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
