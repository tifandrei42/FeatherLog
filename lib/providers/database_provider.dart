import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';

/// The app-wide [AppDatabase] instance.
///
/// Everything that touches persistence depends on this provider, so tests can
/// swap in an in-memory database with
/// `databaseProvider.overrideWithValue(AppDatabase.forTesting(...))`.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
