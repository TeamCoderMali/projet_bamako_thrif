// ─── Bamako Thrift — User Entity (Domain Layer) ───────────────────────────
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? bio;
  final UserRole role;
  final bool isEmailVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int totalListings;
  final int totalSales;
  final double rating;
  final int reviewCount;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    this.bio,
    this.role = UserRole.buyer,
    this.isEmailVerified = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.totalListings = 0,
    this.totalSales = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  bool get isSeller => role == UserRole.seller || role == UserRole.admin;
  bool get isRelayManager => role == UserRole.relay_manager;
  bool get isAdmin => role == UserRole.admin;
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        phoneNumber,
        avatarUrl,
        bio,
        role,
        isEmailVerified,
        isActive,
        createdAt,
        updatedAt,
        totalListings,
        totalSales,
        rating,
        reviewCount,
      ];
}

enum UserRole { buyer, seller, admin, relay_manager }
