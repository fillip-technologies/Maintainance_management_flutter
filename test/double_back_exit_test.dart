import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/core/utils/app_snackbar.dart';
import '../lib/core/widgets/double_back_exit_scope.dart';
import '../lib/l10n/app_localizations.dart';

void main() {
  group('DoubleBackExitScope Unit & Widget Tests', () {
    late List<MethodCall> systemChannelsCalls;

    setUp(() {
      systemChannelsCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        systemChannelsCalls.add(methodCall);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('1. First back press shows toast and does NOT exit the app', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: AppSnackbar.messengerKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DoubleBackExitScope(
            child: Scaffold(
              body: Center(child: Text('Home Screen')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger back button (first press)
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pump();

      // Verify pill toast is displayed with localized message
      expect(find.text('Press back again to exit'), findsOneWidget);

      // Verify SystemNavigator.pop was NOT invoked
      expect(systemChannelsCalls.where((call) => call.method == 'SystemNavigator.pop'), isEmpty);
    });

    testWidgets('2. Second back press within 2 seconds triggers SystemNavigator.pop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: AppSnackbar.messengerKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DoubleBackExitScope(
            child: Scaffold(
              body: Center(child: Text('Home Screen')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));

      // First back press
      await widgetsAppState.didPopRoute();
      await tester.pump();
      expect(systemChannelsCalls.where((call) => call.method == 'SystemNavigator.pop'), isEmpty);

      // Fast forward 500ms (within the 2-second timeout window)
      await tester.pump(const Duration(milliseconds: 500));

      // Second back press
      await widgetsAppState.didPopRoute();
      await tester.pump();

      // SystemNavigator.pop MUST have been invoked!
      expect(systemChannelsCalls.where((call) => call.method == 'SystemNavigator.pop').length, 1);
    });

    testWidgets('3. Second back press after > 2 seconds resets timer and shows toast again', (tester) async {
      var simulatedTime = DateTime(2026, 1, 1, 12, 0, 0);

      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: AppSnackbar.messengerKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DoubleBackExitScope(
            timeout: const Duration(seconds: 2),
            clock: () => simulatedTime,
            child: const Scaffold(
              body: Center(child: Text('Home Screen')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));

      // First back press at 12:00:00
      await widgetsAppState.didPopRoute();
      await tester.pump();
      expect(find.text('Press back again to exit'), findsOneWidget);

      // Advance simulated time by 3 seconds (to 12:00:03)
      simulatedTime = simulatedTime.add(const Duration(seconds: 3));

      // Second back press (timed out, so treated as new first press)
      await widgetsAppState.didPopRoute();
      await tester.pump();

      // Must NOT exit!
      expect(systemChannelsCalls.where((call) => call.method == 'SystemNavigator.pop'), isEmpty);
      expect(find.text('Press back again to exit'), findsOneWidget);
    });

    testWidgets('4. onWillPop returning false intercepts back and suppresses exit prompt', (tester) async {
      bool innerNavHandled = false;

      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: AppSnackbar.messengerKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DoubleBackExitScope(
            onWillPop: () {
              innerNavHandled = true;
              return false; // Handled by inner navigation
            },
            child: const Scaffold(
              body: Center(child: Text('Drilled Down Screen')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pump();

      // Inner navigation handled the back press
      expect(innerNavHandled, isTrue);
      // Exit toast should NOT be shown
      expect(find.text('Press back again to exit'), findsNothing);
      // App must NOT exit
      expect(systemChannelsCalls.where((call) => call.method == 'SystemNavigator.pop'), isEmpty);
    });
  });
}
