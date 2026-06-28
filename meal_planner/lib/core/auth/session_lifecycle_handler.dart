import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_planner/core/config/env.dart';
import 'package:meal_planner/features/auth/presentation/auth_provider.dart';

/// Signs the user out when the app leaves the foreground so the next open
/// requires authentication again.
class SessionLifecycleHandler extends ConsumerStatefulWidget {
  const SessionLifecycleHandler({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SessionLifecycleHandler> createState() =>
      _SessionLifecycleHandlerState();
}

class _SessionLifecycleHandlerState extends ConsumerState<SessionLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!Env.hasSupabase) return;
    if (ref.read(authOperationInProgressProvider)) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _signOut();
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      // Best-effort; next cold start also clears persisted session.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
