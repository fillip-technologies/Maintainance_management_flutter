import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/colors.dart';
import 'core/utils/app_snackbar.dart';
import 'features/auth/auth.dart';
import 'features/home/home.dart';
import 'features/profile/profile.dart';
import 'l10n/app_localizations.dart';

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
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp(
      scaffoldMessengerKey: AppSnackbar.messengerKey,
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: AppColors.theme,
      locale: currentLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginPage(key: ValueKey('login_page'));
          }
          return const GlobalHomePage(key: ValueKey('global_home_page'));
        },
        loading: () => const Scaffold(
          key: ValueKey('auth_loading'),
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (_, _) => const LoginPage(key: ValueKey('login_page_error')),
      ),
    );
  }
}
