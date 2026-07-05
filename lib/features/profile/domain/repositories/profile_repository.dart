// ─── Bamako Thrift — Profile Repository (Domain Contract) ──────────────────
import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> getProfile(String userId);
  Future<ProfileEntity> getCurrentUserProfile();
  Future<ProfileEntity> updateProfile({
    String? fullName,
    String? bio,
    String? location,
    String? website,
    String? avatarUrl,
    String? coverUrl,
  });
  Future<String> uploadAvatar(String filePath);
  Future<void> followUser(String userId);
  Future<void> unfollowUser(String userId);
  Future<bool> isFollowing(String userId);
  Future<List<ProfileEntity>> getFollowers(String userId);
  Future<List<ProfileEntity>> getFollowing(String userId);
}
