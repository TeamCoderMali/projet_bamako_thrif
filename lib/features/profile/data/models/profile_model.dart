// ─── Bamako Thrift — Profile Model (Data Layer) ────────────────────────────
import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.userId,
    required super.fullName,
    super.bio,
    super.avatarUrl,
    super.coverUrl,
    super.location,
    super.website,
    super.followersCount,
    super.followingCount,
    super.totalListings,
    super.totalSales,
    super.averageRating,
    super.reviewCount,
    super.isFollowedByCurrentUser,
    required super.joinedAt,
  });

  factory ProfileModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ProfileModel(
      id: id,
      userId: data['userId'] as String? ?? id,
      fullName: data['fullName'] as String,
      bio: data['bio'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      coverUrl: data['coverUrl'] as String?,
      location: data['location'] as String?,
      website: data['website'] as String?,
      followersCount: data['followersCount'] as int? ?? 0,
      followingCount: data['followingCount'] as int? ?? 0,
      totalListings: data['totalListings'] as int? ?? 0,
      totalSales: data['totalSales'] as int? ?? 0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      isFollowedByCurrentUser:
          data['isFollowedByCurrentUser'] as bool? ?? false,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(
        data['joinedAt'] as int? ?? 0,
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'fullName': fullName,
        'bio': bio,
        'avatarUrl': avatarUrl,
        'coverUrl': coverUrl,
        'location': location,
        'website': website,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'totalListings': totalListings,
        'totalSales': totalSales,
        'averageRating': averageRating,
        'reviewCount': reviewCount,
        'joinedAt': joinedAt.millisecondsSinceEpoch,
      };
}
