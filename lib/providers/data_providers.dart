import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import 'database_provider.dart';

/// All weight entries, newest first. Rebuilds dependents whenever an entry is
/// added, edited, or deleted.
final entriesProvider = StreamProvider<List<WeightEntry>>((ref) {
  return ref.watch(databaseProvider).weightEntryDao.watchAllEntries();
});

/// The single profile row (height, goal). Emits null until first created.
final profileProvider = StreamProvider<Profile?>((ref) {
  return ref.watch(databaseProvider).profileDao.watchProfile();
});

/// Display settings (units, theme, overlays). Emits null until first created.
final settingsProvider = StreamProvider<Setting?>((ref) {
  return ref.watch(databaseProvider).settingsDao.watchSettings();
});
