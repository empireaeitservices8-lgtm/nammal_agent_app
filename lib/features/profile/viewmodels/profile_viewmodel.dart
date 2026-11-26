import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_state.dart';
import '../repositories/profile_repository.dart';

class ProfileViewModel extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    Future.microtask(() => fetchProfile());
    return const ProfileState();
  }

  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  Future<void> fetchProfile() async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final profile = await _repository.getProfile();
      state = state.copyWith(status: ProfileStatus.loaded, profile: profile);
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>?> updateProfile({
    String? name,
    String? email,
    String? gender,
    String? bio,
    String? dob,
    int? age,
    String? idType,
    String? idNumber,
    String? avatarPath,
  }) async {
    try {
      final res = await _repository.updateProfile(
        name: name,
        email: email,
        gender: gender,
        bio: bio,
        dob: dob,
        age: age,
        idType: idType,
        idNumber: idNumber,
        avatarPath: avatarPath,
      );
      await fetchProfile();
      return res;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }
}

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);
