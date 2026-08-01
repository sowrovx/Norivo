/// The application shell that wires together the app theme and router.
library;

import 'package:flutter/material.dart';

import '../core/router/app_router.dart';
import '../core/services/settings_service.dart';
import '../core/theme/app_theme.dart';

class NorivoApp extends StatefulWidget {
  const NorivoApp({super.key});

  @override
  State<NorivoApp> createState() => _NorivoAppState();
}

class _NorivoAppState extends State<NorivoApp> {
  @override
  void initState() {
    super.initState();
    SettingsService.instance.isDarkMode();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsService.instance.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Norivo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          initialRoute: AppRouter.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}
