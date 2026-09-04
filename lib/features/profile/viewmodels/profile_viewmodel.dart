import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth.dart';
import '../models/profile_state.dart';

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState();

  Future<void> logout() async {
    state = state.copyWith(isLoggingOut: true, clearError: true);
    try {
      await ref.read(authStateProvider.notifier).logout();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    } finally {
      state = state.copyWith(isLoggingOut: false);
    }
  }
}

final profileViewModelProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
