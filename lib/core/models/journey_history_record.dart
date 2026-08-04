import 'dart:convert';

class JourneyHistoryRecord {
  const JourneyHistoryRecord({
    required this.id,
    required this.destinationName,
    this.destinationAddress,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.startTime,
    required this.endTime,
    required this.totalDurationSeconds,
    required this.totalDistanceMeters,
    required this.alarmThresholdMeters,
    required this.travelMode,
    required this.status,
  });

  final String id;
  final String destinationName;
  final String? destinationAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final DateTime startTime;
  final DateTime endTime;
  final int totalDurationSeconds;
  final double totalDistanceMeters;
  final double alarmThresholdMeters;
  final String travelMode;
  final String status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'destinationName': destinationName,
        'destinationAddress': destinationAddress,
        'destinationLatitude': destinationLatitude,
        'destinationLongitude': destinationLongitude,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'totalDurationSeconds': totalDurationSeconds,
        'totalDistanceMeters': totalDistanceMeters,
        'alarmThresholdMeters': alarmThresholdMeters,
        'travelMode': travelMode,
        'status': status,
      };

  factory JourneyHistoryRecord.fromJson(Map<String, dynamic> json) {
    return JourneyHistoryRecord(
      id: json['id'] as String? ?? '',
      destinationName: json['destinationName'] as String? ?? 'Unknown Destination',
      destinationAddress: json['destinationAddress'] as String?,
      destinationLatitude: (json['destinationLatitude'] as num?)?.toDouble() ?? 0.0,
      destinationLongitude: (json['destinationLongitude'] as num?)?.toDouble() ?? 0.0,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : DateTime.now(),
      totalDurationSeconds: (json['totalDurationSeconds'] as num?)?.toInt() ?? 0,
      totalDistanceMeters: (json['totalDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      alarmThresholdMeters: (json['alarmThresholdMeters'] as num?)?.toDouble() ?? 1000.0,
      travelMode: json['travelMode'] as String? ?? 'Drive',
      status: json['status'] as String? ?? 'Completed',
    );
  }

  String encode() => jsonEncode(toJson());

  factory JourneyHistoryRecord.decode(String str) =>
      JourneyHistoryRecord.fromJson(jsonDecode(str) as Map<String, dynamic>);
}
