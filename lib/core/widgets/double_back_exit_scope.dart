import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../utils/app_snackbar.dart';

/// Intercepts back navigation gestures / buttons at the root level of the application,
/// requiring the user to press back twice within [timeout] (default 2 seconds) to exit.
///
/// If [onWillPop] is provided and returns `false`, the back event is considered handled
/// by inner navigation (such as popping a breadcrumb hierarchy) and will not trigger
/// the exit prompt.
class DoubleBackExitScope extends StatefulWidget {
  final Widget child;

  /// Optional pre-pop handler. Return `false` to prevent the double-back exit flow
  /// (e.g. if the view has an internal navigation stack to unwind).
  final FutureOr<bool> Function()? onWillPop;

  /// Maximum duration between two back presses to trigger exit. Defaults to 2 seconds.
  final Duration timeout;

  /// Custom message override. If null, localized [AppLocalizations.pressBackAgainToExit] is used.
  final String? message;

  /// Optional time provider (for deterministic unit testing). Defaults to [DateTime.now].
  final DateTime Function()? clock;

  const DoubleBackExitScope({
    super.key,
    required this.child,
    this.onWillPop,
    this.timeout = const Duration(seconds: 2),
    this.message,
    this.clock,
  });

  @override
  State<DoubleBackExitScope> createState() => _DoubleBackExitScopeState();
}

class _DoubleBackExitScopeState extends State<DoubleBackExitScope> {
  DateTime? _lastPressedAt;

  Future<void> _handlePopInvoked(bool didPop) async {
    if (didPop) return;

    // Check custom inner handler first
    if (widget.onWillPop != null) {
      final shouldProceed = await widget.onWillPop!();
      if (!shouldProceed) {
        // Inner navigation handled the back press (e.g. navigated up zone tree)
        return;
      }
    }

    final now = widget.clock?.call() ?? DateTime.now();
    if (_lastPressedAt == null || now.difference(_lastPressedAt!) > widget.timeout) {
      _lastPressedAt = now;
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final toastMessage = widget.message ??
          l10n?.pressBackAgainToExit ??
          'Press back again to exit';
      AppSnackbar.toast(toastMessage, duration: widget.timeout);
      return;
    }

    // Two back presses within timeout -> exit app
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handlePopInvoked(didPop),
      child: widget.child,
    );
  }
}
