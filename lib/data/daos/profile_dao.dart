import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'profile_dao.g.dart';

/// Data access for the single [Profiles] row.
///
/// v1 is single-profile, so these helpers transparently create the row on first
/// use — the UI never has to handle a "no profile yet" state.
@DriftAccessor(tables: [Profiles])
class ProfileDao extends DatabaseAccessor<AppDatabase> with _$ProfileDaoMixin {
  ProfileDao(super.db);

  /// Ensures the single profile row exists and returns it.
  Future<Profile> getOrCreateProfile() async {
    final existing = await select(profiles).getSingleOrNull();
    if (existing != null) return existing;
    final id = await into(profiles).insert(const ProfilesCompanion());
    return (select(profiles)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Reactive view of the profile (emits null until the row is first created).
  Stream<Profile?> watchProfile() => select(profiles).watchSingleOrNull();

  Future<void> updateHeight(double? heightCm) async {
    final profile = await getOrCreateProfile();
    await (update(profiles)..where((t) => t.id.equals(profile.id))).write(
      ProfilesCompanion(heightCm: Value(heightCm)),
    );
  }

  Future<void> updateGoalWeight(double? goalWeightKg) async {
    final profile = await getOrCreateProfile();
    await (update(profiles)..where((t) => t.id.equals(profile.id))).write(
      ProfilesCompanion(goalWeightKg: Value(goalWeightKg)),
    );
  }

  /// Optional biological sex hint (free text, e.g. 'male' | 'female'). Pass null
  /// to clear it. Does not affect BMI bands (see `domain/age.dart`).
  Future<void> updateSex(String? sex) async {
    final profile = await getOrCreateProfile();
    await (update(profiles)..where((t) => t.id.equals(profile.id))).write(
      ProfilesCompanion(sex: Value(sex)),
    );
  }

  /// Optional birth date, used only to derive age for display/context. Pass null
  /// to clear it.
  Future<void> updateBirthDate(DateTime? birthDate) async {
    final profile = await getOrCreateProfile();
    await (update(profiles)..where((t) => t.id.equals(profile.id))).write(
      ProfilesCompanion(birthDate: Value(birthDate)),
    );
  }
}
