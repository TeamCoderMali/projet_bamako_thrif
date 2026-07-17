// ─── Bamako Thrift — Notification Repository Implementation (Firestore) ──────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseMessaging _messaging;

  NotificationRepositoryImpl(this._firestore, this._auth, this._messaging);

  String get _currentUid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _notifCol =>
      _firestore.collection('notification');

  // ── Récupérer les notifications ──────────────────────────────────────────
  @override
  Future<List<NotificationEntity>> getNotifications({int page = 0}) async {
    final snap = await _notifCol
        .where('userId', isEqualTo: _currentUid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snap.docs.map((doc) {
      final data = _convertTimestamps(doc.data());
      return NotificationModel.fromFirestore(data, doc.id);
    }).toList();
  }

  // ── Marquer une notification comme lue ───────────────────────────────────
  @override
  Future<void> markAsRead(String notificationId) async {
    await _notifCol.doc(notificationId).update({'isRead': true});
  }

  // ── Marquer toutes comme lues ────────────────────────────────────────────
  @override
  Future<void> markAllAsRead() async {
    final unread = await _notifCol
        .where('userId', isEqualTo: _currentUid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Supprimer une notification ───────────────────────────────────────────
  @override
  Future<void> deleteNotification(String notificationId) async {
    await _notifCol.doc(notificationId).delete();
  }

  // ── Effacer toutes ───────────────────────────────────────────────────────
  @override
  Future<void> clearAll() async {
    final all = await _notifCol
        .where('userId', isEqualTo: _currentUid)
        .get();

    final batch = _firestore.batch();
    for (final doc in all.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── Stream notifications temps réel ──────────────────────────────────────
  @override
  Stream<List<NotificationEntity>> watchNotifications() {
    return _notifCol
        .where('userId', isEqualTo: _currentUid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = _convertTimestamps(doc.data());
              return NotificationModel.fromFirestore(data, doc.id);
            }).toList());
  }

  // ── Compter les non lues ─────────────────────────────────────────────────
  @override
  Future<int> getUnreadCount() async {
    final snap = await _notifCol
        .where('userId', isEqualTo: _currentUid)
        .where('isRead', isEqualTo: false)
        .get();
    return snap.size;
  }

  // ── Token FCM ────────────────────────────────────────────────────────────
  @override
  Future<String?> getFcmToken() async {
    return _messaging.getToken();
  }

  @override
  Future<void> updateFcmToken(String token) async {
    await _firestore.collection('users').doc(_currentUid).update({
      'fcmToken': token,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Helper Timestamp ─────────────────────────────────────────────────────
  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final r = Map<String, dynamic>.from(data);
    if (r['createdAt'] is Timestamp) {
      r['createdAt'] = (r['createdAt'] as Timestamp).millisecondsSinceEpoch;
    }
    return r;
  }
}
