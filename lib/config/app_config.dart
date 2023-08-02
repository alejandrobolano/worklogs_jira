import 'package:flutter/widgets.dart';

class AppConfig extends InheritedWidget {
  const AppConfig({
    Key? key,
    required this.flavorName,
    required this.apiBaseUrl,
    required this.debug,
    required Widget child,
  }) : super(key: key, child: child);

  final String flavorName;
  final String apiBaseUrl;
  final bool debug;

  static AppConfig? _instance;

  static AppConfig getInstance({
    required String flavorName,
    required String apiBaseUrl,
    required bool debug,
    required Widget child,
  }) {
    _instance ??= AppConfig(
      flavorName: flavorName,
      apiBaseUrl: apiBaseUrl,
      debug: debug,
      child: child,
    );
    return _instance!;
  }

  static AppConfig? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppConfig>();
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;
}
