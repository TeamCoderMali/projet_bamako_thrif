// ─── Bamako Thrift — Profile Cubit & State ─────────────────────────────────
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

// ── States ─────────────────────────────────────────────────────────────────
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;
  const ProfileLoaded(this.profile);
  @override
  List<Object?> get props => [profile];
}

class ProfileUpdating extends ProfileState {
  final ProfileEntity profile;
  const ProfileUpdating(this.profile);
  @override
  List<Object?> get props => [profile];
}

class ProfileUpdated extends ProfileState {
  final ProfileEntity profile;
  const ProfileUpdated(this.profile);
  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ──────────────────────────────────────────────────────────────────
class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _repository;

  ProfileCubit({required ProfileRepository repository})
      : _repository = repository,
        super(const ProfileInitial());

  Future<void> loadCurrentProfile() async {
    emit(const ProfileLoading());
    try {
      final profile = await _repository.getCurrentUserProfile();
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> loadProfile(String userId) async {
    emit(const ProfileLoading());
    try {
      final profile = await _repository.getProfile(userId);
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? location,
    String? website,
  }) async {
    final current = state;
    if (current is ProfileLoaded) {
      emit(ProfileUpdating(current.profile));
    }
    try {
      final updated = await _repository.updateProfile(
        fullName: fullName,
        bio: bio,
        location: location,
        website: website,
      );
      emit(ProfileUpdated(updated));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> toggleFollow(String userId) async {
    try {
      final isFollowing = await _repository.isFollowing(userId);
      if (isFollowing) {
        await _repository.unfollowUser(userId);
      } else {
        await _repository.followUser(userId);
      }
      await loadProfile(userId);
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
