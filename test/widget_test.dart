import 'package:flutter_test/flutter_test.dart';
import 'package:equipment_management_system/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EquipmentManagementApp());
    expect(find.text('Equipment Hub'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
