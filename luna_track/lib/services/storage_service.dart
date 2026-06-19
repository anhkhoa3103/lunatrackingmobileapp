import 'package:hive_flutter/hive_flutter.dart';
import '../models/cycle_entry.dart';

class StorageService {
  static const _boxName = 'cycle_entries';

  // Call once at app startup
  static Future<void> init() async {
    Hive.registerAdapter(CycleEntryAdapter());
    await Hive.openBox<CycleEntry>(_boxName);
  }

  static Box<CycleEntry> get _box => Hive.box<CycleEntry>(_boxName);

  // Save or update today's entry
  static Future<void> saveEntry(CycleEntry entry) async {
    final key = _dateKey(entry.date);
    await _box.put(key, entry);
  }

  // Get entry for a specific date (null if not logged)
  static CycleEntry? getEntry(DateTime date) {
    return _box.get(_dateKey(date));
  }

  // Get all entries sorted by date
  static List<CycleEntry> getAllEntries() {
    final entries = _box.values.toList();
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  // Get last N entries (for AI context)
  static List<CycleEntry> getRecentEntries({int count = 7}) {
    final all = getAllEntries();
    if (all.length <= count) return all;
    return all.sublist(all.length - count);
  }

  // Delete an entry
  static Future<void> deleteEntry(DateTime date) async {
    await _box.delete(_dateKey(date));
  }

  // Key format: "2025-01-15"
  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}