/// The application shell that wires together the app theme and router.
library;

import 'package:flutter/material.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';

class NorivoApp extends StatelessWidget {
  const NorivoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Norivo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
