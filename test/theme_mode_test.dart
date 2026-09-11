import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/core/theme/theme.dart';
import '../lib/features/auth/auth.dart';
import '../lib/features/profile/views/profile_page.dart';
import '../lib/core/widgets/language_switcher_button.dart';
import '../lib/l10n/app_localizations.dart';

class FakeAuthNotifier extends AuthNotifier {
  final UserModel _user;
  FakeAuthNotifier(this._user);

  @override
  Future<UserModel?> build() async => _user;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeModeNotifier & AppDarkColors Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('ThemeModeNotifier defaults to ThemeMode.dark', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mode = container.read(themeModeProvider);
      expect(mode, ThemeMode.dark);
    });

    test('toggleTheme toggles between dark and light and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(AppColors.isDark, isTrue);
      expect(AppColors.background, AppDarkColors.background);

      // Toggle to light
      await notifier.toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(AppColors.isDark, isFalse);
      expect(AppColors.background, AppLightColors.background);
      expect(AppColors.surface, AppLightColors.surface);
      expect(AppColors.textPrimary, AppLightColors.textPrimary);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_theme_mode'), 'light');

      // Toggle back to dark
      await notifier.toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(AppColors.isDark, isTrue);
      expect(AppColors.background, AppDarkColors.background);
      expect(prefs.getString('selected_theme_mode'), 'dark');
    });

    test('setThemeMode directly sets mode', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      await notifier.setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_theme_mode'), 'light');
    });

    test('AppTheme.light and AppTheme.dark have correct brightness and colors', () {
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.dark.brightness, Brightness.dark);
      expect(AppDarkColors.background, const Color(0xFF070E1E));
      expect(AppDarkColors.surface, const Color(0xFF0C172C));
      expect(AppDarkColors.card, const Color(0xFF0C172C));
      expect(AppDarkColors.textPrimary, const Color(0xFFFFFFFF));
    });
  });

  group('ProfilePage Theme Switch Widget Test', () {
    final testUser = UserModel(
      id: 'test_user_id',
      email: 'tech@example.com',
      name: 'Test Technician',
      role: UserRole.technician,
    );

    testWidgets('renders theme switch and toggles theme on tap', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => FakeAuthNotifier(testUser)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ProfilePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for theme section
      expect(find.textContaining('Theme'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);

      final switchFinder = find.byKey(const ValueKey('theme_mode_switch'));
      expect(switchFinder, findsOneWidget);

      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();

      // Verify switch is currently on (dark)
      final switchWidgetBefore = tester.widget<Switch>(switchFinder);
      expect(switchWidgetBefore.value, isTrue);

      // Verify language switcher button has dark primaryBg before toggle
      final langBtnFinder = find.byType(LanguageSwitcherButton);
      expect(langBtnFinder, findsOneWidget);
      final containerBefore = tester.widget<Container>(
        find.descendant(of: langBtnFinder, matching: find.byType(Container)),
      );
      expect((containerBefore.decoration as BoxDecoration).color, AppDarkColors.primaryBg);

      // Tap switch to toggle to Light Mode
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Verify label changed to Light Mode and switch is inactive
      expect(find.text('Light Mode'), findsOneWidget);
      final switchWidgetAfter = tester.widget<Switch>(switchFinder);
      expect(switchWidgetAfter.value, isFalse);

      // Verify language switcher button updated to light primaryBg
      final containerAfter = tester.widget<Container>(
        find.descendant(of: langBtnFinder, matching: find.byType(Container)),
      );
      expect((containerAfter.decoration as BoxDecoration).color, AppLightColors.primaryBg);

      // Tap switch again to toggle back to Dark Mode
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(find.text('Dark Mode'), findsOneWidget);
      final switchWidgetFinal = tester.widget<Switch>(switchFinder);
      expect(switchWidgetFinal.value, isTrue);

      final containerFinal = tester.widget<Container>(
        find.descendant(of: langBtnFinder, matching: find.byType(Container)),
      );
      expect((containerFinal.decoration as BoxDecoration).color, AppDarkColors.primaryBg);
    });
  });
}
