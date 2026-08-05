import '../models/destination_place.dart';
import '../services/destination_search_service.dart';

class JourneyNotificationService {
  const JourneyNotificationService._();

  static const int notificationId = 1001;

  static String buildTitle(DestinationPlace destination) {
    return 'Heading to ${destination.name}';
  }

  static String buildContent({
    required double distanceMeters,
    required double? durationSeconds,
    required bool isNearDestination,
  }) {
    final distText = DestinationSearchService.formatDistance(distanceMeters);
    final mins = durationSeconds != null
        ? (durationSeconds / 60).round()
        : (distanceMeters / 250).round();
    final etaText = mins < 1 ? '< 1 min' : '$mins mins';
    final statusText = isNearDestination ? 'Arriving Soon' : 'In Progress';

    return '$distText • ETA: $etaText • $statusText';
  }
}
