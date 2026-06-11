import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

/// Data access for the single [Settings] row (display preferences).
///
/// Creates the row with sensible defaults (kg / cm / system, overlays on) on
/// first use, so the UI always has settings to read.
@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Ensures the single settings row exists and returns it.
  Future<Setting> getOrCreateSettings() async {
    final existing = await select(settings).getSingleOrNull();
    if (existing != null) return existing;
    final id = await into(settings).insert(const SettingsCompanion());
    return (select(settings)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Reactive view of settings (emits null until the row is first created).
  Stream<Setting?> watchSettings() => select(settings).watchSingleOrNull();

  Future<void> _patch(SettingsCompanion patch) async {
    final current = await getOrCreateSettings();
    await (update(
      settings,
    )..where((t) => t.id.equals(current.id))).write(patch);
  }

  Future<void> updateWeightUnit(String unit) =>
      _patch(SettingsCompanion(weightUnit: Value(unit)));

  Future<void> updateLengthUnit(String unit) =>
      _patch(SettingsCompanion(lengthUnit: Value(unit)));

  Future<void> updateTheme(String theme) =>
      _patch(SettingsCompanion(theme: Value(theme)));

  Future<void> setShowMovingAvg(bool value) =>
      _patch(SettingsCompanion(showMovingAvg: Value(value)));

  Future<void> setShowGoalLine(bool value) =>
      _patch(SettingsCompanion(showGoalLine: Value(value)));

  Future<void> updatePalette(String id) =>
      _patch(SettingsCompanion(palette: Value(id)));

  Future<void> setCheckUpdates(bool value) =>
      _patch(SettingsCompanion(checkUpdates: Value(value)));

  Future<void> setDismissedUpdateVersion(String? version) =>
      _patch(SettingsCompanion(dismissedUpdateVersion: Value(version)));

  Future<void> setOnboardingDone(bool value) =>
      _patch(SettingsCompanion(onboardingDone: Value(value)));

  Future<void> setHeroShowsTrend(bool value) =>
      _patch(SettingsCompanion(heroShowsTrend: Value(value)));

  Future<void> setShowEnergyEstimate(bool value) =>
      _patch(SettingsCompanion(showEnergyEstimate: Value(value)));
}
