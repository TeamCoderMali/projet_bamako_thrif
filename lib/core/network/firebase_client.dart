/// ─── Bamako Thrift — Firebase Client ──────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Wrapper centralisé pour les instances Firebase.
/// Permet de faciliter les tests via injection de mocks.
class FirebaseClient {
  FirebaseClient({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseMessaging? messaging,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseMessaging _messaging;

  // ── Getters ───────────────────────────────────────────────────────────
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  FirebaseMessaging get messaging => _messaging;

  // ── Firestore collections ─────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get usersRef =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get productsRef =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get ordersRef =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get chatsRef =>
      _firestore.collection('chats');

  CollectionReference<Map<String, dynamic>> get notificationsRef =>
      _firestore.collection('notifications');

  CollectionReference<Map<String, dynamic>> get reviewsRef =>
      _firestore.collection('reviews');

  CollectionReference<Map<String, dynamic>> get categoriesRef =>
      _firestore.collection('categories');

  // ── Storage paths ─────────────────────────────────────────────────────
  Reference get productImagesRef => _storage.ref('product_images');
  Reference get avatarsRef => _storage.ref('avatars');
  Reference get chatMediaRef => _storage.ref('chat_media');

  // ── Auth helpers ──────────────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  String? get currentUserId => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
