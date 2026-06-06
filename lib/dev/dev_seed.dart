import 'dart:math';

import '../data/database.dart';

/// Development-only data seeding. The single caller is gated behind
/// [kDebugMode], so in release builds this code is tree-shaken out and never
/// ships. `dart:math` stays scoped here, out of production widgets/data code.

/// Wipes all entries and inserts a realistic near-daily series with a
/// down → up → down shape and small day-to-day noise, for sanity-checking the
/// chart and moving-average overlay.
Future<void> seedRealisticData(AppDatabase db) async {
  final dao = db.weightEntryDao;
  await dao.deleteAllEntries();

  final rng = Random(42);
  final today = DateTime.now();
  final start = today.subtract(const Duration(days: 75));

  // Piecewise targets: down 90->82, up 82->87, down 87->83.
  double targetFor(int day) {
    if (day <= 30) return 90 - (8 * day / 30); // 90 -> 82
    if (day <= 50) return 82 + (5 * (day - 30) / 20); // 82 -> 87
    return 87 - (4 * (day - 50) / 25); // 87 -> 83
  }

  final rows = <WeightEntriesCompanion>[];
  for (var d = 0; d <= 75; d++) {
    // ~85% of days logged (leave occasional gaps).
    if (rng.nextDouble() < 0.15) continue;
    final noise = (rng.nextDouble() - 0.5) * 0.8; // +/-0.4 kg
    final kg = double.parse((targetFor(d) + noise).toStringAsFixed(1));
    final at = DateTime(start.year, start.month, start.day + d, 7, 30);
    rows.add(WeightEntriesCompanion.insert(measuredAt: at, weightKg: kg));
  }
  await dao.bulkInsert(rows);
}
