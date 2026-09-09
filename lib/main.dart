import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/services/push_service.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/theme.dart';
import 'core/utils/app_snackbar.dart';
import 'features/auth/auth.dart';
import 'features/home/home.dart';
import 'features/profile/profile.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initPushBackground();
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
    final currentThemeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      scaffoldMessengerKey: AppSnackbar.messengerKey,
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: currentThemeMode,
      locale: currentLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: authState.when(
        data: (user) {
          if (user == null) {
            return LoginPage(key: ValueKey('login_page_${currentThemeMode.name}'));
          }
          return GlobalHomePage(key: ValueKey('global_home_page_${currentThemeMode.name}'));
        },
        loading: () => Scaffold(
          key: ValueKey('auth_loading_${currentThemeMode.name}'),
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (_, _) => LoginPage(key: ValueKey('login_page_error_${currentThemeMode.name}')),
      ),
    );
  }
}
