// ─── Bamako Thrift — Profile Entity (Domain Layer) ─────────────────────────
import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String id;
  final String userId;
  final String fullName;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final String? location;
  final String? website;
  final int followersCount;
  final int followingCount;
  final int totalListings;
  final int totalSales;
  final double averageRating;
  final int reviewCount;
  final bool isFollowedByCurrentUser;
  final DateTime joinedAt;

  const ProfileEntity({
    required this.id,
    required this.userId,
    required this.fullName,
    this.bio,
    this.avatarUrl,
    this.coverUrl,
    this.location,
    this.website,
    this.followersCount = 0,
    this.followingCount = 0,
    this.totalListings = 0,
    this.totalSales = 0,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.isFollowedByCurrentUser = false,
    required this.joinedAt,
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  List<Object?> get props => [
        id, userId, fullName, bio, avatarUrl, followersCount,
        followingCount, totalListings, averageRating, isFollowedByCurrentUser,
      ];
}
