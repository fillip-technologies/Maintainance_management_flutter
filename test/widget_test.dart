import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equipment_management_system/core/config/app_config.dart';
import 'package:equipment_management_system/core/providers/auth_provider.dart';
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
  });
}
