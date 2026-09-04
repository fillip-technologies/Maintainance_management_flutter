import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equipment_management_system/core/config/app_config.dart';
import 'package:equipment_management_system/features/auth/auth.dart';
import 'package:equipment_management_system/core/storage/storage_service.dart';
import 'package:equipment_management_system/main.dart';

void main() {
  testWidgets('App launches smoke test and displays LoginPage', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
        ],
        child: const EquipmentManagementApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(AppConfig.appName), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);

    // Tap Hindi segment
    await tester.tap(find.text('हिन्दी'));
    await tester.pumpAndSettle();

    // Verify UI switched to Hindi
    expect(find.text('लॉग इन करें'), findsOneWidget);
    expect(find.text('उपकरण और रखरखाव प्रबंधन'), findsOneWidget);

    // Tap English segment back
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // Verify UI switched back to English
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Equipment & Maintenance Management'), findsOneWidget);
  });
}
