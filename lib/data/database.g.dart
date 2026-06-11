// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goalWeightKgMeta = const VerificationMeta(
    'goalWeightKg',
  );
  @override
  late final GeneratedColumn<double> goalWeightKg = GeneratedColumn<double>(
    'goal_weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  @override
  late final GeneratedColumn<DateTime> birthDate = GeneratedColumn<DateTime>(
    'birth_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    heightCm,
    goalWeightKg,
    sex,
    birthDate,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    }
    if (data.containsKey('goal_weight_kg')) {
      context.handle(
        _goalWeightKgMeta,
        goalWeightKg.isAcceptableOrUnknown(
          data['goal_weight_kg']!,
          _goalWeightKgMeta,
        ),
      );
    }
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      ),
      goalWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}goal_weight_kg'],
      ),
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      ),
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}birth_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final int id;

  /// Required for BMI; nullable until the user sets it.
  final double? heightCm;

  /// Optional target weight (canonical kg).
  final double? goalWeightKg;

  /// Optional, may refine BMI context / future age-sex formulas.
  final String? sex;
  final DateTime? birthDate;
  final DateTime createdAt;
  const Profile({
    required this.id,
    this.heightCm,
    this.goalWeightKg,
    this.sex,
    this.birthDate,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    if (!nullToAbsent || goalWeightKg != null) {
      map['goal_weight_kg'] = Variable<double>(goalWeightKg);
    }
    if (!nullToAbsent || sex != null) {
      map['sex'] = Variable<String>(sex);
    }
    if (!nullToAbsent || birthDate != null) {
      map['birth_date'] = Variable<DateTime>(birthDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      goalWeightKg: goalWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(goalWeightKg),
      sex: sex == null && nullToAbsent ? const Value.absent() : Value(sex),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      createdAt: Value(createdAt),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      goalWeightKg: serializer.fromJson<double?>(json['goalWeightKg']),
      sex: serializer.fromJson<String?>(json['sex']),
      birthDate: serializer.fromJson<DateTime?>(json['birthDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'heightCm': serializer.toJson<double?>(heightCm),
      'goalWeightKg': serializer.toJson<double?>(goalWeightKg),
      'sex': serializer.toJson<String?>(sex),
      'birthDate': serializer.toJson<DateTime?>(birthDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Profile copyWith({
    int? id,
    Value<double?> heightCm = const Value.absent(),
    Value<double?> goalWeightKg = const Value.absent(),
    Value<String?> sex = const Value.absent(),
    Value<DateTime?> birthDate = const Value.absent(),
    DateTime? createdAt,
  }) => Profile(
    id: id ?? this.id,
    heightCm: heightCm.present ? heightCm.value : this.heightCm,
    goalWeightKg: goalWeightKg.present ? goalWeightKg.value : this.goalWeightKg,
    sex: sex.present ? sex.value : this.sex,
    birthDate: birthDate.present ? birthDate.value : this.birthDate,
    createdAt: createdAt ?? this.createdAt,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      goalWeightKg: data.goalWeightKg.present
          ? data.goalWeightKg.value
          : this.goalWeightKg,
      sex: data.sex.present ? data.sex.value : this.sex,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('heightCm: $heightCm, ')
          ..write('goalWeightKg: $goalWeightKg, ')
          ..write('sex: $sex, ')
          ..write('birthDate: $birthDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, heightCm, goalWeightKg, sex, birthDate, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.heightCm == this.heightCm &&
          other.goalWeightKg == this.goalWeightKg &&
          other.sex == this.sex &&
          other.birthDate == this.birthDate &&
          other.createdAt == this.createdAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<double?> heightCm;
  final Value<double?> goalWeightKg;
  final Value<String?> sex;
  final Value<DateTime?> birthDate;
  final Value<DateTime> createdAt;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.goalWeightKg = const Value.absent(),
    this.sex = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.goalWeightKg = const Value.absent(),
    this.sex = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<double>? heightCm,
    Expression<double>? goalWeightKg,
    Expression<String>? sex,
    Expression<DateTime>? birthDate,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (heightCm != null) 'height_cm': heightCm,
      if (goalWeightKg != null) 'goal_weight_kg': goalWeightKg,
      if (sex != null) 'sex': sex,
      if (birthDate != null) 'birth_date': birthDate,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<double?>? heightCm,
    Value<double?>? goalWeightKg,
    Value<String?>? sex,
    Value<DateTime?>? birthDate,
    Value<DateTime>? createdAt,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      heightCm: heightCm ?? this.heightCm,
      goalWeightKg: goalWeightKg ?? this.goalWeightKg,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (goalWeightKg.present) {
      map['goal_weight_kg'] = Variable<double>(goalWeightKg.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<DateTime>(birthDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('heightCm: $heightCm, ')
          ..write('goalWeightKg: $goalWeightKg, ')
          ..write('sex: $sex, ')
          ..write('birthDate: $birthDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WeightEntriesTable extends WeightEntries
    with TableInfo<$WeightEntriesTable, WeightEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _measuredAtMeta = const VerificationMeta(
    'measuredAt',
  );
  @override
  late final GeneratedColumn<DateTime> measuredAt = GeneratedColumn<DateTime>(
    'measured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyFatPctMeta = const VerificationMeta(
    'bodyFatPct',
  );
  @override
  late final GeneratedColumn<double> bodyFatPct = GeneratedColumn<double>(
    'body_fat_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _musclePctMeta = const VerificationMeta(
    'musclePct',
  );
  @override
  late final GeneratedColumn<double> musclePct = GeneratedColumn<double>(
    'muscle_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waterPctMeta = const VerificationMeta(
    'waterPct',
  );
  @override
  late final GeneratedColumn<double> waterPct = GeneratedColumn<double>(
    'water_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEventMeta = const VerificationMeta(
    'isEvent',
  );
  @override
  late final GeneratedColumn<bool> isEvent = GeneratedColumn<bool>(
    'is_event',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_event" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _eventLabelMeta = const VerificationMeta(
    'eventLabel',
  );
  @override
  late final GeneratedColumn<String> eventLabel = GeneratedColumn<String>(
    'event_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    measuredAt,
    weightKg,
    note,
    bodyFatPct,
    musclePct,
    waterPct,
    source,
    externalId,
    profileId,
    isEvent,
    eventLabel,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('measured_at')) {
      context.handle(
        _measuredAtMeta,
        measuredAt.isAcceptableOrUnknown(data['measured_at']!, _measuredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_measuredAtMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('body_fat_pct')) {
      context.handle(
        _bodyFatPctMeta,
        bodyFatPct.isAcceptableOrUnknown(
          data['body_fat_pct']!,
          _bodyFatPctMeta,
        ),
      );
    }
    if (data.containsKey('muscle_pct')) {
      context.handle(
        _musclePctMeta,
        musclePct.isAcceptableOrUnknown(data['muscle_pct']!, _musclePctMeta),
      );
    }
    if (data.containsKey('water_pct')) {
      context.handle(
        _waterPctMeta,
        waterPct.isAcceptableOrUnknown(data['water_pct']!, _waterPctMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('is_event')) {
      context.handle(
        _isEventMeta,
        isEvent.isAcceptableOrUnknown(data['is_event']!, _isEventMeta),
      );
    }
    if (data.containsKey('event_label')) {
      context.handle(
        _eventLabelMeta,
        eventLabel.isAcceptableOrUnknown(data['event_label']!, _eventLabelMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeightEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      measuredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}measured_at'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      bodyFatPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}body_fat_pct'],
      ),
      musclePct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}muscle_pct'],
      ),
      waterPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}water_pct'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      ),
      isEvent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_event'],
      )!,
      eventLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_label'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WeightEntriesTable createAlias(String alias) {
    return $WeightEntriesTable(attachedDatabase, alias);
  }
}

class WeightEntry extends DataClass implements Insertable<WeightEntry> {
  final int id;

  /// Full timestamp of the reading (date + time). Not unique — several readings
  /// per day are allowed; aggregation to a single daily value happens on read.
  final DateTime measuredAt;

  /// Canonical weight in kilograms (always kg, regardless of display unit).
  final double weightKg;
  final String? note;

  /// Optional body-composition percentages (0–100), nullable so existing rows
  /// and weight-only entries stay valid. Free in FeatherLog (DATA_MODEL.md §8).
  final double? bodyFatPct;
  final double? musclePct;
  final double? waterPct;

  /// Provenance of this reading: null = manually entered in the app;
  /// otherwise 'aktibmi' | 'health_connect' | … Paired with [externalId] for
  /// idempotent re-import (unique index on the pair, NULLs exempt). v7.
  final String? source;

  /// Source-native identifier (e.g. a Health Connect record id), used with
  /// [source] to de-duplicate re-imports. Null for manual entries. v7.
  final String? externalId;

  /// Owning profile (logically references [Profiles.id]). Null = the default
  /// profile, so single-profile behaviour is unchanged; multi-profile later
  /// becomes UI work, not a data migration. v7.
  final int? profileId;

  /// Marks this reading as a user "event" (e.g. "started gym") so the chart can
  /// pin it. Defaulted false so existing rows are unaffected. v7.
  final bool isEvent;

  /// Optional short label shown on the chart's event pin (only when [isEvent]). v7.
  final String? eventLabel;
  final DateTime createdAt;
  final DateTime updatedAt;
  const WeightEntry({
    required this.id,
    required this.measuredAt,
    required this.weightKg,
    this.note,
    this.bodyFatPct,
    this.musclePct,
    this.waterPct,
    this.source,
    this.externalId,
    this.profileId,
    required this.isEvent,
    this.eventLabel,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['measured_at'] = Variable<DateTime>(measuredAt);
    map['weight_kg'] = Variable<double>(weightKg);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || bodyFatPct != null) {
      map['body_fat_pct'] = Variable<double>(bodyFatPct);
    }
    if (!nullToAbsent || musclePct != null) {
      map['muscle_pct'] = Variable<double>(musclePct);
    }
    if (!nullToAbsent || waterPct != null) {
      map['water_pct'] = Variable<double>(waterPct);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<int>(profileId);
    }
    map['is_event'] = Variable<bool>(isEvent);
    if (!nullToAbsent || eventLabel != null) {
      map['event_label'] = Variable<String>(eventLabel);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WeightEntriesCompanion toCompanion(bool nullToAbsent) {
    return WeightEntriesCompanion(
      id: Value(id),
      measuredAt: Value(measuredAt),
      weightKg: Value(weightKg),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      bodyFatPct: bodyFatPct == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyFatPct),
      musclePct: musclePct == null && nullToAbsent
          ? const Value.absent()
          : Value(musclePct),
      waterPct: waterPct == null && nullToAbsent
          ? const Value.absent()
          : Value(waterPct),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
      isEvent: Value(isEvent),
      eventLabel: eventLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(eventLabel),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WeightEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightEntry(
      id: serializer.fromJson<int>(json['id']),
      measuredAt: serializer.fromJson<DateTime>(json['measuredAt']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      note: serializer.fromJson<String?>(json['note']),
      bodyFatPct: serializer.fromJson<double?>(json['bodyFatPct']),
      musclePct: serializer.fromJson<double?>(json['musclePct']),
      waterPct: serializer.fromJson<double?>(json['waterPct']),
      source: serializer.fromJson<String?>(json['source']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      profileId: serializer.fromJson<int?>(json['profileId']),
      isEvent: serializer.fromJson<bool>(json['isEvent']),
      eventLabel: serializer.fromJson<String?>(json['eventLabel']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'measuredAt': serializer.toJson<DateTime>(measuredAt),
      'weightKg': serializer.toJson<double>(weightKg),
      'note': serializer.toJson<String?>(note),
      'bodyFatPct': serializer.toJson<double?>(bodyFatPct),
      'musclePct': serializer.toJson<double?>(musclePct),
      'waterPct': serializer.toJson<double?>(waterPct),
      'source': serializer.toJson<String?>(source),
      'externalId': serializer.toJson<String?>(externalId),
      'profileId': serializer.toJson<int?>(profileId),
      'isEvent': serializer.toJson<bool>(isEvent),
      'eventLabel': serializer.toJson<String?>(eventLabel),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WeightEntry copyWith({
    int? id,
    DateTime? measuredAt,
    double? weightKg,
    Value<String?> note = const Value.absent(),
    Value<double?> bodyFatPct = const Value.absent(),
    Value<double?> musclePct = const Value.absent(),
    Value<double?> waterPct = const Value.absent(),
    Value<String?> source = const Value.absent(),
    Value<String?> externalId = const Value.absent(),
    Value<int?> profileId = const Value.absent(),
    bool? isEvent,
    Value<String?> eventLabel = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WeightEntry(
    id: id ?? this.id,
    measuredAt: measuredAt ?? this.measuredAt,
    weightKg: weightKg ?? this.weightKg,
    note: note.present ? note.value : this.note,
    bodyFatPct: bodyFatPct.present ? bodyFatPct.value : this.bodyFatPct,
    musclePct: musclePct.present ? musclePct.value : this.musclePct,
    waterPct: waterPct.present ? waterPct.value : this.waterPct,
    source: source.present ? source.value : this.source,
    externalId: externalId.present ? externalId.value : this.externalId,
    profileId: profileId.present ? profileId.value : this.profileId,
    isEvent: isEvent ?? this.isEvent,
    eventLabel: eventLabel.present ? eventLabel.value : this.eventLabel,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WeightEntry copyWithCompanion(WeightEntriesCompanion data) {
    return WeightEntry(
      id: data.id.present ? data.id.value : this.id,
      measuredAt: data.measuredAt.present
          ? data.measuredAt.value
          : this.measuredAt,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      note: data.note.present ? data.note.value : this.note,
      bodyFatPct: data.bodyFatPct.present
          ? data.bodyFatPct.value
          : this.bodyFatPct,
      musclePct: data.musclePct.present ? data.musclePct.value : this.musclePct,
      waterPct: data.waterPct.present ? data.waterPct.value : this.waterPct,
      source: data.source.present ? data.source.value : this.source,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      isEvent: data.isEvent.present ? data.isEvent.value : this.isEvent,
      eventLabel: data.eventLabel.present
          ? data.eventLabel.value
          : this.eventLabel,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntry(')
          ..write('id: $id, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('weightKg: $weightKg, ')
          ..write('note: $note, ')
          ..write('bodyFatPct: $bodyFatPct, ')
          ..write('musclePct: $musclePct, ')
          ..write('waterPct: $waterPct, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('profileId: $profileId, ')
          ..write('isEvent: $isEvent, ')
          ..write('eventLabel: $eventLabel, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    measuredAt,
    weightKg,
    note,
    bodyFatPct,
    musclePct,
    waterPct,
    source,
    externalId,
    profileId,
    isEvent,
    eventLabel,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightEntry &&
          other.id == this.id &&
          other.measuredAt == this.measuredAt &&
          other.weightKg == this.weightKg &&
          other.note == this.note &&
          other.bodyFatPct == this.bodyFatPct &&
          other.musclePct == this.musclePct &&
          other.waterPct == this.waterPct &&
          other.source == this.source &&
          other.externalId == this.externalId &&
          other.profileId == this.profileId &&
          other.isEvent == this.isEvent &&
          other.eventLabel == this.eventLabel &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WeightEntriesCompanion extends UpdateCompanion<WeightEntry> {
  final Value<int> id;
  final Value<DateTime> measuredAt;
  final Value<double> weightKg;
  final Value<String?> note;
  final Value<double?> bodyFatPct;
  final Value<double?> musclePct;
  final Value<double?> waterPct;
  final Value<String?> source;
  final Value<String?> externalId;
  final Value<int?> profileId;
  final Value<bool> isEvent;
  final Value<String?> eventLabel;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const WeightEntriesCompanion({
    this.id = const Value.absent(),
    this.measuredAt = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.note = const Value.absent(),
    this.bodyFatPct = const Value.absent(),
    this.musclePct = const Value.absent(),
    this.waterPct = const Value.absent(),
    this.source = const Value.absent(),
    this.externalId = const Value.absent(),
    this.profileId = const Value.absent(),
    this.isEvent = const Value.absent(),
    this.eventLabel = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WeightEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime measuredAt,
    required double weightKg,
    this.note = const Value.absent(),
    this.bodyFatPct = const Value.absent(),
    this.musclePct = const Value.absent(),
    this.waterPct = const Value.absent(),
    this.source = const Value.absent(),
    this.externalId = const Value.absent(),
    this.profileId = const Value.absent(),
    this.isEvent = const Value.absent(),
    this.eventLabel = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : measuredAt = Value(measuredAt),
       weightKg = Value(weightKg);
  static Insertable<WeightEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? measuredAt,
    Expression<double>? weightKg,
    Expression<String>? note,
    Expression<double>? bodyFatPct,
    Expression<double>? musclePct,
    Expression<double>? waterPct,
    Expression<String>? source,
    Expression<String>? externalId,
    Expression<int>? profileId,
    Expression<bool>? isEvent,
    Expression<String>? eventLabel,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (measuredAt != null) 'measured_at': measuredAt,
      if (weightKg != null) 'weight_kg': weightKg,
      if (note != null) 'note': note,
      if (bodyFatPct != null) 'body_fat_pct': bodyFatPct,
      if (musclePct != null) 'muscle_pct': musclePct,
      if (waterPct != null) 'water_pct': waterPct,
      if (source != null) 'source': source,
      if (externalId != null) 'external_id': externalId,
      if (profileId != null) 'profile_id': profileId,
      if (isEvent != null) 'is_event': isEvent,
      if (eventLabel != null) 'event_label': eventLabel,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WeightEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? measuredAt,
    Value<double>? weightKg,
    Value<String?>? note,
    Value<double?>? bodyFatPct,
    Value<double?>? musclePct,
    Value<double?>? waterPct,
    Value<String?>? source,
    Value<String?>? externalId,
    Value<int?>? profileId,
    Value<bool>? isEvent,
    Value<String?>? eventLabel,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return WeightEntriesCompanion(
      id: id ?? this.id,
      measuredAt: measuredAt ?? this.measuredAt,
      weightKg: weightKg ?? this.weightKg,
      note: note ?? this.note,
      bodyFatPct: bodyFatPct ?? this.bodyFatPct,
      musclePct: musclePct ?? this.musclePct,
      waterPct: waterPct ?? this.waterPct,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      profileId: profileId ?? this.profileId,
      isEvent: isEvent ?? this.isEvent,
      eventLabel: eventLabel ?? this.eventLabel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (measuredAt.present) {
      map['measured_at'] = Variable<DateTime>(measuredAt.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (bodyFatPct.present) {
      map['body_fat_pct'] = Variable<double>(bodyFatPct.value);
    }
    if (musclePct.present) {
      map['muscle_pct'] = Variable<double>(musclePct.value);
    }
    if (waterPct.present) {
      map['water_pct'] = Variable<double>(waterPct.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (isEvent.present) {
      map['is_event'] = Variable<bool>(isEvent.value);
    }
    if (eventLabel.present) {
      map['event_label'] = Variable<String>(eventLabel.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntriesCompanion(')
          ..write('id: $id, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('weightKg: $weightKg, ')
          ..write('note: $note, ')
          ..write('bodyFatPct: $bodyFatPct, ')
          ..write('musclePct: $musclePct, ')
          ..write('waterPct: $waterPct, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('profileId: $profileId, ')
          ..write('isEvent: $isEvent, ')
          ..write('eventLabel: $eventLabel, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _weightUnitMeta = const VerificationMeta(
    'weightUnit',
  );
  @override
  late final GeneratedColumn<String> weightUnit = GeneratedColumn<String>(
    'weight_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('kg'),
  );
  static const VerificationMeta _lengthUnitMeta = const VerificationMeta(
    'lengthUnit',
  );
  @override
  late final GeneratedColumn<String> lengthUnit = GeneratedColumn<String>(
    'length_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cm'),
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _showMovingAvgMeta = const VerificationMeta(
    'showMovingAvg',
  );
  @override
  late final GeneratedColumn<bool> showMovingAvg = GeneratedColumn<bool>(
    'show_moving_avg',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_moving_avg" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showGoalLineMeta = const VerificationMeta(
    'showGoalLine',
  );
  @override
  late final GeneratedColumn<bool> showGoalLine = GeneratedColumn<bool>(
    'show_goal_line',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_goal_line" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _paletteMeta = const VerificationMeta(
    'palette',
  );
  @override
  late final GeneratedColumn<String> palette = GeneratedColumn<String>(
    'palette',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('meadow'),
  );
  static const VerificationMeta _checkUpdatesMeta = const VerificationMeta(
    'checkUpdates',
  );
  @override
  late final GeneratedColumn<bool> checkUpdates = GeneratedColumn<bool>(
    'check_updates',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("check_updates" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dismissedUpdateVersionMeta =
      const VerificationMeta('dismissedUpdateVersion');
  @override
  late final GeneratedColumn<String> dismissedUpdateVersion =
      GeneratedColumn<String>(
        'dismissed_update_version',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _onboardingDoneMeta = const VerificationMeta(
    'onboardingDone',
  );
  @override
  late final GeneratedColumn<bool> onboardingDone = GeneratedColumn<bool>(
    'onboarding_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _heroShowsTrendMeta = const VerificationMeta(
    'heroShowsTrend',
  );
  @override
  late final GeneratedColumn<bool> heroShowsTrend = GeneratedColumn<bool>(
    'hero_shows_trend',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hero_shows_trend" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showEnergyEstimateMeta =
      const VerificationMeta('showEnergyEstimate');
  @override
  late final GeneratedColumn<bool> showEnergyEstimate = GeneratedColumn<bool>(
    'show_energy_estimate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_energy_estimate" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    weightUnit,
    lengthUnit,
    theme,
    showMovingAvg,
    showGoalLine,
    palette,
    checkUpdates,
    dismissedUpdateVersion,
    onboardingDone,
    heroShowsTrend,
    showEnergyEstimate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('weight_unit')) {
      context.handle(
        _weightUnitMeta,
        weightUnit.isAcceptableOrUnknown(data['weight_unit']!, _weightUnitMeta),
      );
    }
    if (data.containsKey('length_unit')) {
      context.handle(
        _lengthUnitMeta,
        lengthUnit.isAcceptableOrUnknown(data['length_unit']!, _lengthUnitMeta),
      );
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    }
    if (data.containsKey('show_moving_avg')) {
      context.handle(
        _showMovingAvgMeta,
        showMovingAvg.isAcceptableOrUnknown(
          data['show_moving_avg']!,
          _showMovingAvgMeta,
        ),
      );
    }
    if (data.containsKey('show_goal_line')) {
      context.handle(
        _showGoalLineMeta,
        showGoalLine.isAcceptableOrUnknown(
          data['show_goal_line']!,
          _showGoalLineMeta,
        ),
      );
    }
    if (data.containsKey('palette')) {
      context.handle(
        _paletteMeta,
        palette.isAcceptableOrUnknown(data['palette']!, _paletteMeta),
      );
    }
    if (data.containsKey('check_updates')) {
      context.handle(
        _checkUpdatesMeta,
        checkUpdates.isAcceptableOrUnknown(
          data['check_updates']!,
          _checkUpdatesMeta,
        ),
      );
    }
    if (data.containsKey('dismissed_update_version')) {
      context.handle(
        _dismissedUpdateVersionMeta,
        dismissedUpdateVersion.isAcceptableOrUnknown(
          data['dismissed_update_version']!,
          _dismissedUpdateVersionMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_done')) {
      context.handle(
        _onboardingDoneMeta,
        onboardingDone.isAcceptableOrUnknown(
          data['onboarding_done']!,
          _onboardingDoneMeta,
        ),
      );
    }
    if (data.containsKey('hero_shows_trend')) {
      context.handle(
        _heroShowsTrendMeta,
        heroShowsTrend.isAcceptableOrUnknown(
          data['hero_shows_trend']!,
          _heroShowsTrendMeta,
        ),
      );
    }
    if (data.containsKey('show_energy_estimate')) {
      context.handle(
        _showEnergyEstimateMeta,
        showEnergyEstimate.isAcceptableOrUnknown(
          data['show_energy_estimate']!,
          _showEnergyEstimateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      weightUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weight_unit'],
      )!,
      lengthUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}length_unit'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
      showMovingAvg: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_moving_avg'],
      )!,
      showGoalLine: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_goal_line'],
      )!,
      palette: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}palette'],
      )!,
      checkUpdates: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}check_updates'],
      )!,
      dismissedUpdateVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dismissed_update_version'],
      ),
      onboardingDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_done'],
      )!,
      heroShowsTrend: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hero_shows_trend'],
      )!,
      showEnergyEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_energy_estimate'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final int id;

  /// 'kg' | 'lb' — display unit only; storage is always kg.
  final String weightUnit;

  /// 'cm' | 'in' — display unit only; storage is always cm.
  final String lengthUnit;

  /// 'system' | 'light' | 'dark'.
  final String theme;
  final bool showMovingAvg;
  final bool showGoalLine;

  /// Selected accent palette id (see `featherPalettes`). Display-only preference.
  final String palette;

  /// Opt-in: check GitHub for a newer release on launch. Off by default so the
  /// app stays zero-network unless the user asks for it (PRIVACY.md).
  final bool checkUpdates;

  /// The release tag the user dismissed from the update banner (e.g. 'v1.2.0'),
  /// so a declined update isn't shown again. Null until something is dismissed.
  final String? dismissedUpdateVersion;

  /// True once first-run onboarding has been completed (or skipped). Gates the
  /// onboarding flow so it shows only once. v7.
  final bool onboardingDone;

  /// When true (default) the Today hero leads with the smoothed *trend* weight
  /// and demotes the raw reading to a caption; when false it leads with the raw
  /// latest reading. The trend is the honest, less-noisy number (RESEARCH.md
  /// §4). v7.
  final bool heroShowsTrend;

  /// Opt-in: show the estimated energy-balance insight (kcal/day from the
  /// weight trend). Off by default; always framed as an estimate. v7.
  final bool showEnergyEstimate;
  const Setting({
    required this.id,
    required this.weightUnit,
    required this.lengthUnit,
    required this.theme,
    required this.showMovingAvg,
    required this.showGoalLine,
    required this.palette,
    required this.checkUpdates,
    this.dismissedUpdateVersion,
    required this.onboardingDone,
    required this.heroShowsTrend,
    required this.showEnergyEstimate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['weight_unit'] = Variable<String>(weightUnit);
    map['length_unit'] = Variable<String>(lengthUnit);
    map['theme'] = Variable<String>(theme);
    map['show_moving_avg'] = Variable<bool>(showMovingAvg);
    map['show_goal_line'] = Variable<bool>(showGoalLine);
    map['palette'] = Variable<String>(palette);
    map['check_updates'] = Variable<bool>(checkUpdates);
    if (!nullToAbsent || dismissedUpdateVersion != null) {
      map['dismissed_update_version'] = Variable<String>(
        dismissedUpdateVersion,
      );
    }
    map['onboarding_done'] = Variable<bool>(onboardingDone);
    map['hero_shows_trend'] = Variable<bool>(heroShowsTrend);
    map['show_energy_estimate'] = Variable<bool>(showEnergyEstimate);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      weightUnit: Value(weightUnit),
      lengthUnit: Value(lengthUnit),
      theme: Value(theme),
      showMovingAvg: Value(showMovingAvg),
      showGoalLine: Value(showGoalLine),
      palette: Value(palette),
      checkUpdates: Value(checkUpdates),
      dismissedUpdateVersion: dismissedUpdateVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(dismissedUpdateVersion),
      onboardingDone: Value(onboardingDone),
      heroShowsTrend: Value(heroShowsTrend),
      showEnergyEstimate: Value(showEnergyEstimate),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<int>(json['id']),
      weightUnit: serializer.fromJson<String>(json['weightUnit']),
      lengthUnit: serializer.fromJson<String>(json['lengthUnit']),
      theme: serializer.fromJson<String>(json['theme']),
      showMovingAvg: serializer.fromJson<bool>(json['showMovingAvg']),
      showGoalLine: serializer.fromJson<bool>(json['showGoalLine']),
      palette: serializer.fromJson<String>(json['palette']),
      checkUpdates: serializer.fromJson<bool>(json['checkUpdates']),
      dismissedUpdateVersion: serializer.fromJson<String?>(
        json['dismissedUpdateVersion'],
      ),
      onboardingDone: serializer.fromJson<bool>(json['onboardingDone']),
      heroShowsTrend: serializer.fromJson<bool>(json['heroShowsTrend']),
      showEnergyEstimate: serializer.fromJson<bool>(json['showEnergyEstimate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'weightUnit': serializer.toJson<String>(weightUnit),
      'lengthUnit': serializer.toJson<String>(lengthUnit),
      'theme': serializer.toJson<String>(theme),
      'showMovingAvg': serializer.toJson<bool>(showMovingAvg),
      'showGoalLine': serializer.toJson<bool>(showGoalLine),
      'palette': serializer.toJson<String>(palette),
      'checkUpdates': serializer.toJson<bool>(checkUpdates),
      'dismissedUpdateVersion': serializer.toJson<String?>(
        dismissedUpdateVersion,
      ),
      'onboardingDone': serializer.toJson<bool>(onboardingDone),
      'heroShowsTrend': serializer.toJson<bool>(heroShowsTrend),
      'showEnergyEstimate': serializer.toJson<bool>(showEnergyEstimate),
    };
  }

  Setting copyWith({
    int? id,
    String? weightUnit,
    String? lengthUnit,
    String? theme,
    bool? showMovingAvg,
    bool? showGoalLine,
    String? palette,
    bool? checkUpdates,
    Value<String?> dismissedUpdateVersion = const Value.absent(),
    bool? onboardingDone,
    bool? heroShowsTrend,
    bool? showEnergyEstimate,
  }) => Setting(
    id: id ?? this.id,
    weightUnit: weightUnit ?? this.weightUnit,
    lengthUnit: lengthUnit ?? this.lengthUnit,
    theme: theme ?? this.theme,
    showMovingAvg: showMovingAvg ?? this.showMovingAvg,
    showGoalLine: showGoalLine ?? this.showGoalLine,
    palette: palette ?? this.palette,
    checkUpdates: checkUpdates ?? this.checkUpdates,
    dismissedUpdateVersion: dismissedUpdateVersion.present
        ? dismissedUpdateVersion.value
        : this.dismissedUpdateVersion,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    heroShowsTrend: heroShowsTrend ?? this.heroShowsTrend,
    showEnergyEstimate: showEnergyEstimate ?? this.showEnergyEstimate,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      weightUnit: data.weightUnit.present
          ? data.weightUnit.value
          : this.weightUnit,
      lengthUnit: data.lengthUnit.present
          ? data.lengthUnit.value
          : this.lengthUnit,
      theme: data.theme.present ? data.theme.value : this.theme,
      showMovingAvg: data.showMovingAvg.present
          ? data.showMovingAvg.value
          : this.showMovingAvg,
      showGoalLine: data.showGoalLine.present
          ? data.showGoalLine.value
          : this.showGoalLine,
      palette: data.palette.present ? data.palette.value : this.palette,
      checkUpdates: data.checkUpdates.present
          ? data.checkUpdates.value
          : this.checkUpdates,
      dismissedUpdateVersion: data.dismissedUpdateVersion.present
          ? data.dismissedUpdateVersion.value
          : this.dismissedUpdateVersion,
      onboardingDone: data.onboardingDone.present
          ? data.onboardingDone.value
          : this.onboardingDone,
      heroShowsTrend: data.heroShowsTrend.present
          ? data.heroShowsTrend.value
          : this.heroShowsTrend,
      showEnergyEstimate: data.showEnergyEstimate.present
          ? data.showEnergyEstimate.value
          : this.showEnergyEstimate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('weightUnit: $weightUnit, ')
          ..write('lengthUnit: $lengthUnit, ')
          ..write('theme: $theme, ')
          ..write('showMovingAvg: $showMovingAvg, ')
          ..write('showGoalLine: $showGoalLine, ')
          ..write('palette: $palette, ')
          ..write('checkUpdates: $checkUpdates, ')
          ..write('dismissedUpdateVersion: $dismissedUpdateVersion, ')
          ..write('onboardingDone: $onboardingDone, ')
          ..write('heroShowsTrend: $heroShowsTrend, ')
          ..write('showEnergyEstimate: $showEnergyEstimate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    weightUnit,
    lengthUnit,
    theme,
    showMovingAvg,
    showGoalLine,
    palette,
    checkUpdates,
    dismissedUpdateVersion,
    onboardingDone,
    heroShowsTrend,
    showEnergyEstimate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.weightUnit == this.weightUnit &&
          other.lengthUnit == this.lengthUnit &&
          other.theme == this.theme &&
          other.showMovingAvg == this.showMovingAvg &&
          other.showGoalLine == this.showGoalLine &&
          other.palette == this.palette &&
          other.checkUpdates == this.checkUpdates &&
          other.dismissedUpdateVersion == this.dismissedUpdateVersion &&
          other.onboardingDone == this.onboardingDone &&
          other.heroShowsTrend == this.heroShowsTrend &&
          other.showEnergyEstimate == this.showEnergyEstimate);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<int> id;
  final Value<String> weightUnit;
  final Value<String> lengthUnit;
  final Value<String> theme;
  final Value<bool> showMovingAvg;
  final Value<bool> showGoalLine;
  final Value<String> palette;
  final Value<bool> checkUpdates;
  final Value<String?> dismissedUpdateVersion;
  final Value<bool> onboardingDone;
  final Value<bool> heroShowsTrend;
  final Value<bool> showEnergyEstimate;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.weightUnit = const Value.absent(),
    this.lengthUnit = const Value.absent(),
    this.theme = const Value.absent(),
    this.showMovingAvg = const Value.absent(),
    this.showGoalLine = const Value.absent(),
    this.palette = const Value.absent(),
    this.checkUpdates = const Value.absent(),
    this.dismissedUpdateVersion = const Value.absent(),
    this.onboardingDone = const Value.absent(),
    this.heroShowsTrend = const Value.absent(),
    this.showEnergyEstimate = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.weightUnit = const Value.absent(),
    this.lengthUnit = const Value.absent(),
    this.theme = const Value.absent(),
    this.showMovingAvg = const Value.absent(),
    this.showGoalLine = const Value.absent(),
    this.palette = const Value.absent(),
    this.checkUpdates = const Value.absent(),
    this.dismissedUpdateVersion = const Value.absent(),
    this.onboardingDone = const Value.absent(),
    this.heroShowsTrend = const Value.absent(),
    this.showEnergyEstimate = const Value.absent(),
  });
  static Insertable<Setting> custom({
    Expression<int>? id,
    Expression<String>? weightUnit,
    Expression<String>? lengthUnit,
    Expression<String>? theme,
    Expression<bool>? showMovingAvg,
    Expression<bool>? showGoalLine,
    Expression<String>? palette,
    Expression<bool>? checkUpdates,
    Expression<String>? dismissedUpdateVersion,
    Expression<bool>? onboardingDone,
    Expression<bool>? heroShowsTrend,
    Expression<bool>? showEnergyEstimate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weightUnit != null) 'weight_unit': weightUnit,
      if (lengthUnit != null) 'length_unit': lengthUnit,
      if (theme != null) 'theme': theme,
      if (showMovingAvg != null) 'show_moving_avg': showMovingAvg,
      if (showGoalLine != null) 'show_goal_line': showGoalLine,
      if (palette != null) 'palette': palette,
      if (checkUpdates != null) 'check_updates': checkUpdates,
      if (dismissedUpdateVersion != null)
        'dismissed_update_version': dismissedUpdateVersion,
      if (onboardingDone != null) 'onboarding_done': onboardingDone,
      if (heroShowsTrend != null) 'hero_shows_trend': heroShowsTrend,
      if (showEnergyEstimate != null)
        'show_energy_estimate': showEnergyEstimate,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? weightUnit,
    Value<String>? lengthUnit,
    Value<String>? theme,
    Value<bool>? showMovingAvg,
    Value<bool>? showGoalLine,
    Value<String>? palette,
    Value<bool>? checkUpdates,
    Value<String?>? dismissedUpdateVersion,
    Value<bool>? onboardingDone,
    Value<bool>? heroShowsTrend,
    Value<bool>? showEnergyEstimate,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      weightUnit: weightUnit ?? this.weightUnit,
      lengthUnit: lengthUnit ?? this.lengthUnit,
      theme: theme ?? this.theme,
      showMovingAvg: showMovingAvg ?? this.showMovingAvg,
      showGoalLine: showGoalLine ?? this.showGoalLine,
      palette: palette ?? this.palette,
      checkUpdates: checkUpdates ?? this.checkUpdates,
      dismissedUpdateVersion:
          dismissedUpdateVersion ?? this.dismissedUpdateVersion,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      heroShowsTrend: heroShowsTrend ?? this.heroShowsTrend,
      showEnergyEstimate: showEnergyEstimate ?? this.showEnergyEstimate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (weightUnit.present) {
      map['weight_unit'] = Variable<String>(weightUnit.value);
    }
    if (lengthUnit.present) {
      map['length_unit'] = Variable<String>(lengthUnit.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (showMovingAvg.present) {
      map['show_moving_avg'] = Variable<bool>(showMovingAvg.value);
    }
    if (showGoalLine.present) {
      map['show_goal_line'] = Variable<bool>(showGoalLine.value);
    }
    if (palette.present) {
      map['palette'] = Variable<String>(palette.value);
    }
    if (checkUpdates.present) {
      map['check_updates'] = Variable<bool>(checkUpdates.value);
    }
    if (dismissedUpdateVersion.present) {
      map['dismissed_update_version'] = Variable<String>(
        dismissedUpdateVersion.value,
      );
    }
    if (onboardingDone.present) {
      map['onboarding_done'] = Variable<bool>(onboardingDone.value);
    }
    if (heroShowsTrend.present) {
      map['hero_shows_trend'] = Variable<bool>(heroShowsTrend.value);
    }
    if (showEnergyEstimate.present) {
      map['show_energy_estimate'] = Variable<bool>(showEnergyEstimate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('weightUnit: $weightUnit, ')
          ..write('lengthUnit: $lengthUnit, ')
          ..write('theme: $theme, ')
          ..write('showMovingAvg: $showMovingAvg, ')
          ..write('showGoalLine: $showGoalLine, ')
          ..write('palette: $palette, ')
          ..write('checkUpdates: $checkUpdates, ')
          ..write('dismissedUpdateVersion: $dismissedUpdateVersion, ')
          ..write('onboardingDone: $onboardingDone, ')
          ..write('heroShowsTrend: $heroShowsTrend, ')
          ..write('showEnergyEstimate: $showEnergyEstimate')
          ..write(')'))
        .toString();
  }
}

class $BodyMeasurementsTable extends BodyMeasurements
    with TableInfo<$BodyMeasurementsTable, BodyMeasurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyMeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _measuredAtMeta = const VerificationMeta(
    'measuredAt',
  );
  @override
  late final GeneratedColumn<DateTime> measuredAt = GeneratedColumn<DateTime>(
    'measured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueCmMeta = const VerificationMeta(
    'valueCm',
  );
  @override
  late final GeneratedColumn<double> valueCm = GeneratedColumn<double>(
    'value_cm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    measuredAt,
    type,
    valueCm,
    note,
    source,
    externalId,
    profileId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_measurements';
  @override
  VerificationContext validateIntegrity(
    Insertable<BodyMeasurement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('measured_at')) {
      context.handle(
        _measuredAtMeta,
        measuredAt.isAcceptableOrUnknown(data['measured_at']!, _measuredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_measuredAtMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('value_cm')) {
      context.handle(
        _valueCmMeta,
        valueCm.isAcceptableOrUnknown(data['value_cm']!, _valueCmMeta),
      );
    } else if (isInserting) {
      context.missing(_valueCmMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BodyMeasurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyMeasurement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      measuredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}measured_at'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      valueCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value_cm'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BodyMeasurementsTable createAlias(String alias) {
    return $BodyMeasurementsTable(attachedDatabase, alias);
  }
}

class BodyMeasurement extends DataClass implements Insertable<BodyMeasurement> {
  final int id;

  /// Full timestamp of the reading.
  final DateTime measuredAt;

  /// Which body part, e.g. 'waist' | 'chest' | 'hips' | 'neck' | 'thigh'.
  final String type;

  /// Canonical measurement in centimetres.
  final double valueCm;
  final String? note;

  /// Provenance + source-native id, mirroring [WeightEntries] for idempotent
  /// re-import. Null for manual entries. v7.
  final String? source;
  final String? externalId;

  /// Owning profile (logically references [Profiles.id]); null = default. v7.
  final int? profileId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BodyMeasurement({
    required this.id,
    required this.measuredAt,
    required this.type,
    required this.valueCm,
    this.note,
    this.source,
    this.externalId,
    this.profileId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['measured_at'] = Variable<DateTime>(measuredAt);
    map['type'] = Variable<String>(type);
    map['value_cm'] = Variable<double>(valueCm);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<int>(profileId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BodyMeasurementsCompanion toCompanion(bool nullToAbsent) {
    return BodyMeasurementsCompanion(
      id: Value(id),
      measuredAt: Value(measuredAt),
      type: Value(type),
      valueCm: Value(valueCm),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BodyMeasurement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyMeasurement(
      id: serializer.fromJson<int>(json['id']),
      measuredAt: serializer.fromJson<DateTime>(json['measuredAt']),
      type: serializer.fromJson<String>(json['type']),
      valueCm: serializer.fromJson<double>(json['valueCm']),
      note: serializer.fromJson<String?>(json['note']),
      source: serializer.fromJson<String?>(json['source']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      profileId: serializer.fromJson<int?>(json['profileId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'measuredAt': serializer.toJson<DateTime>(measuredAt),
      'type': serializer.toJson<String>(type),
      'valueCm': serializer.toJson<double>(valueCm),
      'note': serializer.toJson<String?>(note),
      'source': serializer.toJson<String?>(source),
      'externalId': serializer.toJson<String?>(externalId),
      'profileId': serializer.toJson<int?>(profileId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BodyMeasurement copyWith({
    int? id,
    DateTime? measuredAt,
    String? type,
    double? valueCm,
    Value<String?> note = const Value.absent(),
    Value<String?> source = const Value.absent(),
    Value<String?> externalId = const Value.absent(),
    Value<int?> profileId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BodyMeasurement(
    id: id ?? this.id,
    measuredAt: measuredAt ?? this.measuredAt,
    type: type ?? this.type,
    valueCm: valueCm ?? this.valueCm,
    note: note.present ? note.value : this.note,
    source: source.present ? source.value : this.source,
    externalId: externalId.present ? externalId.value : this.externalId,
    profileId: profileId.present ? profileId.value : this.profileId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BodyMeasurement copyWithCompanion(BodyMeasurementsCompanion data) {
    return BodyMeasurement(
      id: data.id.present ? data.id.value : this.id,
      measuredAt: data.measuredAt.present
          ? data.measuredAt.value
          : this.measuredAt,
      type: data.type.present ? data.type.value : this.type,
      valueCm: data.valueCm.present ? data.valueCm.value : this.valueCm,
      note: data.note.present ? data.note.value : this.note,
      source: data.source.present ? data.source.value : this.source,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurement(')
          ..write('id: $id, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('type: $type, ')
          ..write('valueCm: $valueCm, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('profileId: $profileId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    measuredAt,
    type,
    valueCm,
    note,
    source,
    externalId,
    profileId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyMeasurement &&
          other.id == this.id &&
          other.measuredAt == this.measuredAt &&
          other.type == this.type &&
          other.valueCm == this.valueCm &&
          other.note == this.note &&
          other.source == this.source &&
          other.externalId == this.externalId &&
          other.profileId == this.profileId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BodyMeasurementsCompanion extends UpdateCompanion<BodyMeasurement> {
  final Value<int> id;
  final Value<DateTime> measuredAt;
  final Value<String> type;
  final Value<double> valueCm;
  final Value<String?> note;
  final Value<String?> source;
  final Value<String?> externalId;
  final Value<int?> profileId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BodyMeasurementsCompanion({
    this.id = const Value.absent(),
    this.measuredAt = const Value.absent(),
    this.type = const Value.absent(),
    this.valueCm = const Value.absent(),
    this.note = const Value.absent(),
    this.source = const Value.absent(),
    this.externalId = const Value.absent(),
    this.profileId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BodyMeasurementsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime measuredAt,
    required String type,
    required double valueCm,
    this.note = const Value.absent(),
    this.source = const Value.absent(),
    this.externalId = const Value.absent(),
    this.profileId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : measuredAt = Value(measuredAt),
       type = Value(type),
       valueCm = Value(valueCm);
  static Insertable<BodyMeasurement> custom({
    Expression<int>? id,
    Expression<DateTime>? measuredAt,
    Expression<String>? type,
    Expression<double>? valueCm,
    Expression<String>? note,
    Expression<String>? source,
    Expression<String>? externalId,
    Expression<int>? profileId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (measuredAt != null) 'measured_at': measuredAt,
      if (type != null) 'type': type,
      if (valueCm != null) 'value_cm': valueCm,
      if (note != null) 'note': note,
      if (source != null) 'source': source,
      if (externalId != null) 'external_id': externalId,
      if (profileId != null) 'profile_id': profileId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BodyMeasurementsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? measuredAt,
    Value<String>? type,
    Value<double>? valueCm,
    Value<String?>? note,
    Value<String?>? source,
    Value<String?>? externalId,
    Value<int?>? profileId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return BodyMeasurementsCompanion(
      id: id ?? this.id,
      measuredAt: measuredAt ?? this.measuredAt,
      type: type ?? this.type,
      valueCm: valueCm ?? this.valueCm,
      note: note ?? this.note,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      profileId: profileId ?? this.profileId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (measuredAt.present) {
      map['measured_at'] = Variable<DateTime>(measuredAt.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (valueCm.present) {
      map['value_cm'] = Variable<double>(valueCm.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('type: $type, ')
          ..write('valueCm: $valueCm, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('profileId: $profileId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $WeightEntriesTable weightEntries = $WeightEntriesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $BodyMeasurementsTable bodyMeasurements = $BodyMeasurementsTable(
    this,
  );
  late final WeightEntryDao weightEntryDao = WeightEntryDao(
    this as AppDatabase,
  );
  late final ProfileDao profileDao = ProfileDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final BodyMeasurementDao bodyMeasurementDao = BodyMeasurementDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    weightEntries,
    settings,
    bodyMeasurements,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      Value<double?> heightCm,
      Value<double?> goalWeightKg,
      Value<String?> sex,
      Value<DateTime?> birthDate,
      Value<DateTime> createdAt,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      Value<double?> heightCm,
      Value<double?> goalWeightKg,
      Value<String?> sex,
      Value<DateTime?> birthDate,
      Value<DateTime> createdAt,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get goalWeightKg => $composableBuilder(
    column: $table.goalWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get goalWeightKg => $composableBuilder(
    column: $table.goalWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get goalWeightKg => $composableBuilder(
    column: $table.goalWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<DateTime> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<double?> goalWeightKg = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<DateTime?> birthDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                heightCm: heightCm,
                goalWeightKg: goalWeightKg,
                sex: sex,
                birthDate: birthDate,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<double?> goalWeightKg = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<DateTime?> birthDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                heightCm: heightCm,
                goalWeightKg: goalWeightKg,
                sex: sex,
                birthDate: birthDate,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$WeightEntriesTableCreateCompanionBuilder =
    WeightEntriesCompanion Function({
      Value<int> id,
      required DateTime measuredAt,
      required double weightKg,
      Value<String?> note,
      Value<double?> bodyFatPct,
      Value<double?> musclePct,
      Value<double?> waterPct,
      Value<String?> source,
      Value<String?> externalId,
      Value<int?> profileId,
      Value<bool> isEvent,
      Value<String?> eventLabel,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$WeightEntriesTableUpdateCompanionBuilder =
    WeightEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> measuredAt,
      Value<double> weightKg,
      Value<String?> note,
      Value<double?> bodyFatPct,
      Value<double?> musclePct,
      Value<double?> waterPct,
      Value<String?> source,
      Value<String?> externalId,
      Value<int?> profileId,
      Value<bool> isEvent,
      Value<String?> eventLabel,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$WeightEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get musclePct => $composableBuilder(
    column: $table.musclePct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waterPct => $composableBuilder(
    column: $table.waterPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEvent => $composableBuilder(
    column: $table.isEvent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventLabel => $composableBuilder(
    column: $table.eventLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeightEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get musclePct => $composableBuilder(
    column: $table.musclePct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waterPct => $composableBuilder(
    column: $table.waterPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEvent => $composableBuilder(
    column: $table.isEvent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventLabel => $composableBuilder(
    column: $table.eventLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeightEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get musclePct =>
      $composableBuilder(column: $table.musclePct, builder: (column) => column);

  GeneratedColumn<double> get waterPct =>
      $composableBuilder(column: $table.waterPct, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<bool> get isEvent =>
      $composableBuilder(column: $table.isEvent, builder: (column) => column);

  GeneratedColumn<String> get eventLabel => $composableBuilder(
    column: $table.eventLabel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WeightEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightEntriesTable,
          WeightEntry,
          $$WeightEntriesTableFilterComposer,
          $$WeightEntriesTableOrderingComposer,
          $$WeightEntriesTableAnnotationComposer,
          $$WeightEntriesTableCreateCompanionBuilder,
          $$WeightEntriesTableUpdateCompanionBuilder,
          (
            WeightEntry,
            BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntry>,
          ),
          WeightEntry,
          PrefetchHooks Function()
        > {
  $$WeightEntriesTableTableManager(_$AppDatabase db, $WeightEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> measuredAt = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<double?> bodyFatPct = const Value.absent(),
                Value<double?> musclePct = const Value.absent(),
                Value<double?> waterPct = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<int?> profileId = const Value.absent(),
                Value<bool> isEvent = const Value.absent(),
                Value<String?> eventLabel = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WeightEntriesCompanion(
                id: id,
                measuredAt: measuredAt,
                weightKg: weightKg,
                note: note,
                bodyFatPct: bodyFatPct,
                musclePct: musclePct,
                waterPct: waterPct,
                source: source,
                externalId: externalId,
                profileId: profileId,
                isEvent: isEvent,
                eventLabel: eventLabel,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime measuredAt,
                required double weightKg,
                Value<String?> note = const Value.absent(),
                Value<double?> bodyFatPct = const Value.absent(),
                Value<double?> musclePct = const Value.absent(),
                Value<double?> waterPct = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<int?> profileId = const Value.absent(),
                Value<bool> isEvent = const Value.absent(),
                Value<String?> eventLabel = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WeightEntriesCompanion.insert(
                id: id,
                measuredAt: measuredAt,
                weightKg: weightKg,
                note: note,
                bodyFatPct: bodyFatPct,
                musclePct: musclePct,
                waterPct: waterPct,
                source: source,
                externalId: externalId,
                profileId: profileId,
                isEvent: isEvent,
                eventLabel: eventLabel,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeightEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightEntriesTable,
      WeightEntry,
      $$WeightEntriesTableFilterComposer,
      $$WeightEntriesTableOrderingComposer,
      $$WeightEntriesTableAnnotationComposer,
      $$WeightEntriesTableCreateCompanionBuilder,
      $$WeightEntriesTableUpdateCompanionBuilder,
      (
        WeightEntry,
        BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntry>,
      ),
      WeightEntry,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<String> weightUnit,
      Value<String> lengthUnit,
      Value<String> theme,
      Value<bool> showMovingAvg,
      Value<bool> showGoalLine,
      Value<String> palette,
      Value<bool> checkUpdates,
      Value<String?> dismissedUpdateVersion,
      Value<bool> onboardingDone,
      Value<bool> heroShowsTrend,
      Value<bool> showEnergyEstimate,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<String> weightUnit,
      Value<String> lengthUnit,
      Value<String> theme,
      Value<bool> showMovingAvg,
      Value<bool> showGoalLine,
      Value<String> palette,
      Value<bool> checkUpdates,
      Value<String?> dismissedUpdateVersion,
      Value<bool> onboardingDone,
      Value<bool> heroShowsTrend,
      Value<bool> showEnergyEstimate,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weightUnit => $composableBuilder(
    column: $table.weightUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lengthUnit => $composableBuilder(
    column: $table.lengthUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showMovingAvg => $composableBuilder(
    column: $table.showMovingAvg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showGoalLine => $composableBuilder(
    column: $table.showGoalLine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get palette => $composableBuilder(
    column: $table.palette,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get checkUpdates => $composableBuilder(
    column: $table.checkUpdates,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dismissedUpdateVersion => $composableBuilder(
    column: $table.dismissedUpdateVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get heroShowsTrend => $composableBuilder(
    column: $table.heroShowsTrend,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showEnergyEstimate => $composableBuilder(
    column: $table.showEnergyEstimate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weightUnit => $composableBuilder(
    column: $table.weightUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lengthUnit => $composableBuilder(
    column: $table.lengthUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showMovingAvg => $composableBuilder(
    column: $table.showMovingAvg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showGoalLine => $composableBuilder(
    column: $table.showGoalLine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get palette => $composableBuilder(
    column: $table.palette,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get checkUpdates => $composableBuilder(
    column: $table.checkUpdates,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dismissedUpdateVersion => $composableBuilder(
    column: $table.dismissedUpdateVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get heroShowsTrend => $composableBuilder(
    column: $table.heroShowsTrend,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showEnergyEstimate => $composableBuilder(
    column: $table.showEnergyEstimate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get weightUnit => $composableBuilder(
    column: $table.weightUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lengthUnit => $composableBuilder(
    column: $table.lengthUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<bool> get showMovingAvg => $composableBuilder(
    column: $table.showMovingAvg,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showGoalLine => $composableBuilder(
    column: $table.showGoalLine,
    builder: (column) => column,
  );

  GeneratedColumn<String> get palette =>
      $composableBuilder(column: $table.palette, builder: (column) => column);

  GeneratedColumn<bool> get checkUpdates => $composableBuilder(
    column: $table.checkUpdates,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dismissedUpdateVersion => $composableBuilder(
    column: $table.dismissedUpdateVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get heroShowsTrend => $composableBuilder(
    column: $table.heroShowsTrend,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showEnergyEstimate => $composableBuilder(
    column: $table.showEnergyEstimate,
    builder: (column) => column,
  );
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> weightUnit = const Value.absent(),
                Value<String> lengthUnit = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<bool> showMovingAvg = const Value.absent(),
                Value<bool> showGoalLine = const Value.absent(),
                Value<String> palette = const Value.absent(),
                Value<bool> checkUpdates = const Value.absent(),
                Value<String?> dismissedUpdateVersion = const Value.absent(),
                Value<bool> onboardingDone = const Value.absent(),
                Value<bool> heroShowsTrend = const Value.absent(),
                Value<bool> showEnergyEstimate = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                weightUnit: weightUnit,
                lengthUnit: lengthUnit,
                theme: theme,
                showMovingAvg: showMovingAvg,
                showGoalLine: showGoalLine,
                palette: palette,
                checkUpdates: checkUpdates,
                dismissedUpdateVersion: dismissedUpdateVersion,
                onboardingDone: onboardingDone,
                heroShowsTrend: heroShowsTrend,
                showEnergyEstimate: showEnergyEstimate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> weightUnit = const Value.absent(),
                Value<String> lengthUnit = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<bool> showMovingAvg = const Value.absent(),
                Value<bool> showGoalLine = const Value.absent(),
                Value<String> palette = const Value.absent(),
                Value<bool> checkUpdates = const Value.absent(),
                Value<String?> dismissedUpdateVersion = const Value.absent(),
                Value<bool> onboardingDone = const Value.absent(),
                Value<bool> heroShowsTrend = const Value.absent(),
                Value<bool> showEnergyEstimate = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                weightUnit: weightUnit,
                lengthUnit: lengthUnit,
                theme: theme,
                showMovingAvg: showMovingAvg,
                showGoalLine: showGoalLine,
                palette: palette,
                checkUpdates: checkUpdates,
                dismissedUpdateVersion: dismissedUpdateVersion,
                onboardingDone: onboardingDone,
                heroShowsTrend: heroShowsTrend,
                showEnergyEstimate: showEnergyEstimate,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$BodyMeasurementsTableCreateCompanionBuilder =
    BodyMeasurementsCompanion Function({
      Value<int> id,
      required DateTime measuredAt,
      required String type,
      required double valueCm,
      Value<String?> note,
      Value<String?> source,
      Value<String?> externalId,
      Value<int?> profileId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$BodyMeasurementsTableUpdateCompanionBuilder =
    BodyMeasurementsCompanion Function({
      Value<int> id,
      Value<DateTime> measuredAt,
      Value<String> type,
      Value<double> valueCm,
      Value<String?> note,
      Value<String?> source,
      Value<String?> externalId,
      Value<int?> profileId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$BodyMeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get valueCm => $composableBuilder(
    column: $table.valueCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BodyMeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valueCm => $composableBuilder(
    column: $table.valueCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BodyMeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get valueCm =>
      $composableBuilder(column: $table.valueCm, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BodyMeasurementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BodyMeasurementsTable,
          BodyMeasurement,
          $$BodyMeasurementsTableFilterComposer,
          $$BodyMeasurementsTableOrderingComposer,
          $$BodyMeasurementsTableAnnotationComposer,
          $$BodyMeasurementsTableCreateCompanionBuilder,
          $$BodyMeasurementsTableUpdateCompanionBuilder,
          (
            BodyMeasurement,
            BaseReferences<
              _$AppDatabase,
              $BodyMeasurementsTable,
              BodyMeasurement
            >,
          ),
          BodyMeasurement,
          PrefetchHooks Function()
        > {
  $$BodyMeasurementsTableTableManager(
    _$AppDatabase db,
    $BodyMeasurementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyMeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyMeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyMeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> measuredAt = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> valueCm = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<int?> profileId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BodyMeasurementsCompanion(
                id: id,
                measuredAt: measuredAt,
                type: type,
                valueCm: valueCm,
                note: note,
                source: source,
                externalId: externalId,
                profileId: profileId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime measuredAt,
                required String type,
                required double valueCm,
                Value<String?> note = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<int?> profileId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BodyMeasurementsCompanion.insert(
                id: id,
                measuredAt: measuredAt,
                type: type,
                valueCm: valueCm,
                note: note,
                source: source,
                externalId: externalId,
                profileId: profileId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BodyMeasurementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BodyMeasurementsTable,
      BodyMeasurement,
      $$BodyMeasurementsTableFilterComposer,
      $$BodyMeasurementsTableOrderingComposer,
      $$BodyMeasurementsTableAnnotationComposer,
      $$BodyMeasurementsTableCreateCompanionBuilder,
      $$BodyMeasurementsTableUpdateCompanionBuilder,
      (
        BodyMeasurement,
        BaseReferences<_$AppDatabase, $BodyMeasurementsTable, BodyMeasurement>,
      ),
      BodyMeasurement,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$WeightEntriesTableTableManager get weightEntries =>
      $$WeightEntriesTableTableManager(_db, _db.weightEntries);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$BodyMeasurementsTableTableManager get bodyMeasurements =>
      $$BodyMeasurementsTableTableManager(_db, _db.bodyMeasurements);
}
