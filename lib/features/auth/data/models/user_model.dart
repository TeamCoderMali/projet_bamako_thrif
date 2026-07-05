// ─── Bamako Thrift — User Model (Data Layer) ──────────────────────────────
// Étend UserEntity avec la sérialisation JSON / Firestore.
// Générer avec : flutter pub run build_runner build
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    super.phoneNumber,
    super.avatarUrl,
    super.bio,
    super.role,
    super.isEmailVerified,
    super.isActive,
    required super.createdAt,
    super.updatedAt,
    super.totalListings,
    super.totalSales,
    super.rating,
    super.reviewCount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      role: _parseRole(json['role'] as String?),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as int?) ?? 0,
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : null,
      totalListings: json['totalListings'] as int? ?? 0,
      totalSales: json['totalSales'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }

  /// Désérialisation depuis Firestore (DocumentSnapshot.data()).
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel.fromJson({...data, 'id': id});
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'role': role.name,
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'totalListings': totalListings,
      'totalSales': totalSales,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    UserRole? role,
    bool? isEmailVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalListings,
    int? totalSales,
    double? rating,
    int? reviewCount,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalListings: totalListings ?? this.totalListings,
      totalSales: totalSales ?? this.totalSales,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'seller':
        return UserRole.seller;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.buyer;
    }
  }
}
