import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';

// 1. Storage Provider (Overridden in main.dart after SharedPreferences.getInstance())
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be initialized in main()');
});

// 2. ApiClient Provider (Configured with storage for automatic JWT refresh)
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(storage: storage);
});

// 3. Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthRepository(apiClient: apiClient, storage: storage);
});

// 4. Universal Auth State AsyncNotifier
class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final authRepo = ref.watch(authRepositoryProvider);
    return authRepo.getCurrentUser();
  }

  void setUser(UserModel? user) {
    state = AsyncValue.data(user);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.login(email: email, password: password);
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.logout();
    } finally {
      state = const AsyncValue.data(null);
    }
  }
}

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

// 5. Dedicated Login Controller for managing login button loading and error states
class LoginController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    return;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.login(email: email, password: password);
      ref.read(authStateProvider.notifier).setUser(user);
    });

    return !state.hasError;
  }

  void clearError() {
    state = const AsyncValue.data(null);
  }
}

final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<LoginController, void>(LoginController.new);

// 5. Computed / Helper Selectors
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value != null;
});

final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.role;
});
