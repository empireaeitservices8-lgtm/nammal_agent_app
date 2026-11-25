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

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? gender,
  }) async {
    try {
      await _repository.updateProfile(name: name, email: email, gender: gender);
      await fetchProfile();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);
