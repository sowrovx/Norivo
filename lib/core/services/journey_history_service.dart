import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/journey_history_record.dart';

class JourneyHistoryService {
  JourneyHistoryService({this.preferences});

  static final JourneyHistoryService instance = JourneyHistoryService();
  static const String keyHistoryRecords = 'norivo_journey_history_records';

  SharedPreferences? preferences;

  final ValueNotifier<List<JourneyHistoryRecord>> historyNotifier =
      ValueNotifier<List<JourneyHistoryRecord>>([]);

  Future<SharedPreferences> _getPrefs() async {
    if (preferences != null) return preferences!;
    preferences = await SharedPreferences.getInstance();
    return preferences!;
  }

  Future<List<JourneyHistoryRecord>> getHistoryRecords() async {
    try {
      final prefs = await _getPrefs();
      final rawList = prefs.getStringList(keyHistoryRecords) ?? [];
      final records = rawList
          .map((item) {
            try {
              return JourneyHistoryRecord.decode(item);
            } catch (e) {
              return null;
            }
          })
          .whereType<JourneyHistoryRecord>()
          .toList();

      records.sort((a, b) => b.startTime.compareTo(a.startTime));
      historyNotifier.value = List.unmodifiable(records);
      return records;
    } catch (e) {
      debugPrint('Error reading journey history records: $e');
      return [];
    }
  }

  Future<void> addRecord(JourneyHistoryRecord record) async {
    try {
      final records = await getHistoryRecords();
      final updatedList = [record, ...records];
      final prefs = await _getPrefs();
      final rawList = updatedList.map((r) => r.encode()).toList();
      await prefs.setStringList(keyHistoryRecords, rawList);
      historyNotifier.value = List.unmodifiable(updatedList);
    } catch (e) {
      debugPrint('Error saving journey history record: $e');
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      final records = await getHistoryRecords();
      final updatedList = records.where((r) => r.id != id).toList();
      final prefs = await _getPrefs();
      final rawList = updatedList.map((r) => r.encode()).toList();
      await prefs.setStringList(keyHistoryRecords, rawList);
      historyNotifier.value = List.unmodifiable(updatedList);
    } catch (e) {
      debugPrint('Error deleting journey history record: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(keyHistoryRecords);
      historyNotifier.value = [];
    } catch (e) {
      debugPrint('Error clearing journey history: $e');
    }
  }
}
