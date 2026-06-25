import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_planner/features/connectivity/connectivity_notifier.dart';

class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final isOffline = connectivity.maybeWhen(
      data: (results) => results.contains(ConnectivityResult.none),
      orElse: () => false,
    );

    return Column(
      children: [
        if (isOffline)
          Material(
            color: Theme.of(context).colorScheme.error,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Sin conexión',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}
