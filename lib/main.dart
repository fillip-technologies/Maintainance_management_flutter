import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/auth_provider.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/colors.dart';
import 'core/utils/app_snackbar.dart';
import 'features/auth/view/login_page.dart';
import 'features/home/view/global_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = await StorageService.init();

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storageService)],
      child: const EquipmentManagementApp(),
    ),
  );
}

class EquipmentManagementApp extends ConsumerWidget {
  const EquipmentManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      scaffoldMessengerKey: AppSnackbar.messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Equipment Management System',
      theme: AppColors.theme,
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginPage();
          }
          return const GlobalHomePage();
        },
        loading: () => const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (_, _) => const LoginPage(),
      ),
    );
  }
}
