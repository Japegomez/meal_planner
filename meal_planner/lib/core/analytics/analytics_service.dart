import 'package:meal_planner/core/config/env.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

abstract final class AnalyticsService {
  static Future<void> initialize() async {
    if (!Env.hasPosthog) return;

    final config = PostHogConfig(Env.posthogApiKey)
      ..host = Env.posthogHost
      ..captureApplicationLifecycleEvents = true;

    await Posthog().setup(config);
  }

  static Future<void> trackAppOpened() async {
    if (!Env.hasPosthog) return;
    await Posthog().capture(eventName: 'app_opened');
  }

  static Future<void> track(String event, {Map<String, Object>? properties}) async {
    if (!Env.hasPosthog) return;
    await Posthog().capture(eventName: event, properties: properties);
  }
}
