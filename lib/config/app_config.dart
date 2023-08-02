import 'package:flutter/widgets.dart';

class AppConfig extends InheritedWidget {
  const AppConfig({
    Key? key,
    required this.appName,
    required this.flavorName,
    required this.apiBaseUrl,
    required this.apiEndpointUrl,
    required Widget child,
  }) : super(key: key, child: child);

  final String appName;
  final String flavorName;
  final String apiBaseUrl;
  final String apiEndpointUrl;

  static AppConfig? _instance;

  static AppConfig getInstance({
    required String appName,
    required String flavorName,
    required String apiBaseUrl,
    required String apiEndpointUrl,
    required Widget child,
  }) {
    _instance ??= AppConfig(
      appName: appName,
      flavorName: flavorName,
      apiBaseUrl: apiBaseUrl,
      apiEndpointUrl: apiEndpointUrl,
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
