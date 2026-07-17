// ─── Bamako Thrift — Chat Repository Implementation (Firestore) ─────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChatRepositoryImpl(this._firestore, this._auth);

  String get _currentUid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _chatsCol =>
      _firestore.collection('chat');

  // ── Récupérer mes chats ─────────────────────────────────────────────────
  @override
  Future<List<ChatEntity>> getMyChats() async {
    final snap = await _chatsCol
        .where('participantIds', arrayContains: _currentUid)
        .orderBy('lastMessageAt', descending: true)
        .get();

    return snap.docs.map((doc) {
      final data = _convertTimestamps(doc.data());
      return ChatModel.fromFirestore(data, doc.id);
    }).toList();
  }

  // ── Récupérer un chat par ID ─────────────────────────────────────────────
  @override
  Future<ChatEntity> getChatById(String chatId) async {
    final doc = await _chatsCol.doc(chatId).get();
    if (!doc.exists) throw Exception('Chat introuvable.');
    final data = _convertTimestamps(doc.data()!);
    return ChatModel.fromFirestore(data, doc.id);
  }

  // ── Créer ou récupérer un chat existant ────────────────────────────────────
  @override
  Future<ChatEntity> createOrGetChat({
    required String otherUserId,
    String? productId,
  }) async {
    // Chercher un chat existant entre les deux utilisateurs pour ce produit
    final existing = await _chatsCol
        .where('participantIds', arrayContains: _currentUid)
        .get();

    for (final doc in existing.docs) {
      final ids = List<String>.from(doc.data()['participantIds'] as List? ?? []);
      final pid = doc.data()['productId'] as String?;
      if (ids.contains(otherUserId) &&
          (productId == null || pid == productId)) {
        final data = _convertTimestamps(doc.data());
        return ChatModel.fromFirestore(data, doc.id);
      }
    }

    // Créer un nouveau chat
    final currentUser = _auth.currentUser!;
    final docRef = await _chatsCol.add({
      'participantIds': [_currentUid, otherUserId],
      'participantNames': {
        _currentUid: currentUser.displayName ?? 'Utilisateur',
        otherUserId: '',
      },
      'participantAvatars': {
        _currentUid: currentUser.photoURL,
        otherUserId: null,
      },
      'lastMessage': null,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'productId': productId,
      'productTitle': null,
      'productImageUrl': null,
      'unreadCount': {_currentUid: 0, otherUserId: 0},
    });

    final created = await docRef.get();
    final data = _convertTimestamps(created.data()!);
    return ChatModel.fromFirestore(data, docRef.id);
  }

  /// Variante avec infos participants complètes (utilisée par NewChatPage).
  Future<String> createOrGetChatWithUsers({
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String?> participantAvatars,
    String? productId,
    String? productTitle,
  }) async {
    // Vérifier si un chat existe déjà entre ces participants
    final otherUid = participantIds.firstWhere(
        (id) => id != _currentUid,
        orElse: () => '');

    if (otherUid.isNotEmpty) {
      final existing = await _chatsCol
          .where('participantIds', arrayContains: _currentUid)
          .get();

      for (final doc in existing.docs) {
        final ids = List<String>.from(
            doc.data()['participantIds'] as List? ?? []);
        final pid = doc.data()['productId'] as String?;
        if (ids.contains(otherUid) &&
            (productId == null || pid == productId)) {
          return doc.id;
        }
      }
    }

    // Créer un nouveau chat
    final unreadMap = <String, int>{};
    for (final id in participantIds) {
      unreadMap[id] = 0;
    }

    final docRef = await _chatsCol.add({
      'participantIds': participantIds,
      'participantNames':
          participantNames.map((k, v) => MapEntry(k, v)),
      'participantAvatars':
          participantAvatars.map((k, v) => MapEntry(k, v)),
      'lastMessage': null,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'productId': productId,
      'productTitle': productTitle,
      'productImageUrl': null,
      'unreadCount': unreadMap,
    });

    return docRef.id;
  }

  // ── Envoyer un message ───────────────────────────────────────────────────
  @override
  Future<MessageEntity> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) async {
    final now = FieldValue.serverTimestamp();

    // Ajouter le message dans la sous-collection
    final msgRef = await _chatsCol.doc(chatId).collection('message').add({
      'chatId': chatId,
      'senderId': _currentUid,
      'content': content,
      'type': type.name,
      'isRead': false,
      'createdAt': now,
      'mediaUrl': mediaUrl,
    });

    // Mettre à jour le dernier message du chat
    await _chatsCol.doc(chatId).update({
      'lastMessage': content,
      'lastMessageAt': now,
    });

    // Retourner le message créé
    final msgDoc = await msgRef.get();
    final data = Map<String, dynamic>.from(msgDoc.data()!);
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
    }
    return MessageModel.fromFirestore(data, msgRef.id);
  }

  // ── Marquer comme lu ─────────────────────────────────────────────────────
  @override
  Future<void> markAsRead(String chatId) async {
    // Marquer tous les messages non lus comme lus
    final unread = await _chatsCol
        .doc(chatId)
        .collection('message')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: _currentUid)
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    batch.update(_chatsCol.doc(chatId), {'unreadCount.$_currentUid': 0});
    await batch.commit();
  }

  // ── Stream messages en temps réel ────────────────────────────────────────
  @override
  Stream<List<MessageEntity>> watchMessages(String chatId) {
    return _chatsCol
        .doc(chatId)
        .collection('message')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = _convertTimestamps(doc.data());
              return MessageModel.fromFirestore(data, doc.id);
            }).toList());
  }

  // ── Stream liste des chats ───────────────────────────────────────────────
  @override
  Stream<List<ChatEntity>> watchChats() {
    return _chatsCol
        .where('participantIds', arrayContains: _currentUid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = _convertTimestamps(doc.data());
              return ChatModel.fromFirestore(data, doc.id);
            }).toList());
  }

  // ── Supprimer un chat ────────────────────────────────────────────────────
  @override
  Future<void> deleteChat(String chatId) async {
    // Supprimer les messages d'abord
    final msgs =
        await _chatsCol.doc(chatId).collection('message').get();
    final batch = _firestore.batch();
    for (final doc in msgs.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_chatsCol.doc(chatId));
    await batch.commit();
  }

  // ── Helper Timestamp ─────────────────────────────────────────────────────
  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final r = Map<String, dynamic>.from(data);
    // Convertir tous les champs Timestamp possibles
    for (final key in ['lastMessageAt', 'createdAt', 'updatedAt']) {
      if (r[key] is Timestamp) {
        r[key] = (r[key] as Timestamp).millisecondsSinceEpoch;
      }
    }
    return r;
  }
}
