/// Defines the app routes for each feature area.
library;

import 'package:flutter/material.dart';

import '../../features/active_journey/active_journey_screen.dart';
import '../../features/alarm_ringing/alarm_ringing_screen.dart';
import '../../features/alarm_setup/alarm_setup_screen.dart';
import '../../features/destination_search/destination_search_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/splash/splash_screen.dart';

class AppRouter {
  const AppRouter._();

  static const String splash = '/';
  static const String home = '/home';
  static const String destinationSearch = '/destination-search';
  static const String alarmSetup = '/alarm-setup';
  static const String activeJourney = '/active-journey';
  static const String alarmRinging = '/alarm-ringing';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute<void>(builder: (_) => const SplashScreen());
      case home:
        return MaterialPageRoute<void>(builder: (_) => const HomeScreen());
      case destinationSearch:
        return MaterialPageRoute<void>(
          builder: (_) => const DestinationSearchScreen(),
        );
      case alarmSetup:
        return MaterialPageRoute<void>(
          builder: (_) => const AlarmSetupScreen(),
        );
      case activeJourney:
        return MaterialPageRoute<void>(
          builder: (_) => const ActiveJourneyScreen(),
        );
      case alarmRinging:
        return MaterialPageRoute<void>(
          builder: (_) => const AlarmRingingScreen(),
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
