import 'package:drift/drift.dart';
import 'package:everslot/core/database/tables/synced_columns.dart';

@DataClassName('HabitRow')
class Habits extends Table with SyncedColumns {
  /// build | quit
  TextColumn get kind => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text().nullable()();
  IntColumn get color => integer().nullable()();
  TextColumn get categoryId => text().nullable()();

  /// check | count | duration | numeric
  TextColumn get goalType => text().withDefault(const Constant('check'))();
  RealColumn get targetValue => real().nullable()();

  /// gte | lte | eq
  TextColumn get targetOp => text().withDefault(const Constant('gte'))();
  TextColumn get unit => text().nullable()();

  /// Recurrence JSON (arch §8.1); null for quit trackers.
  TextColumn get schedule => text().nullable()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text().nullable()();
  TextColumn get timeZone => text().nullable()();

  /// neutral | breaks
  TextColumn get skipPolicy => text().withDefault(const Constant('neutral'))();
  IntColumn get freezesPerMonth => integer().withDefault(const Constant(0))();

  /// abstain | reduce
  TextColumn get quitMode => text().nullable()();
  TextColumn get quitSubstance => text().nullable()();
  DateTimeColumn get quitStartedAt => dateTime().nullable()();
  RealColumn get dailyLimit => real().nullable()();
  RealColumn get baselinePerDay => real().nullable()();
  RealColumn get unitCost => real().nullable()();
  TextColumn get currency => text().nullable()();
  RealColumn get timePerUnitMinutes => real().nullable()();
  RealColumn get lifeMinutesPerUnit => real().nullable()();
  BoolColumn get autoSuccess => boolean().withDefault(const Constant(true))();
  TextColumn get motivation => text().nullable()();
  TextColumn get sectionId => text().nullable()();

  /// HabitSettings JSON v1.
  TextColumn get settings => text().withDefault(const Constant('{}'))();
  TextColumn get sortKey => text()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  TextColumn get notifyMode => text().withDefault(const Constant('inherit'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HabitSectionRow')
class HabitSections extends Table with SyncedColumns {
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get sortKey => text()();
  TextColumn get startTime => text().nullable()();
  TextColumn get endTime => text().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HabitVocabRow')
class HabitVocab extends Table with SyncedColumns {
  /// trigger | place | coping | distraction
  TextColumn get kind => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  IntColumn get color => integer().nullable()();
  TextColumn get sortKey => text()();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  String get tableName => 'habit_vocab';

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HabitLogRow')
class HabitLogs extends Table with SyncedColumns {
  TextColumn get habitId => text()();
  TextColumn get occurrenceKey => text().nullable()();

  /// done | fail | progress | skip | excuse | clean | relapse | craving | note | use | restart | pledge | freeze | survey
  TextColumn get kind => text()();
  RealColumn get value => real().nullable()();
  DateTimeColumn get loggedAt => dateTime()();
  TextColumn get localDate => text()();
  IntColumn get mood => integer().nullable()();
  IntColumn get intensity => integer().nullable()();
  BoolColumn get resisted => boolean().nullable()();
  TextColumn get trigger => text().nullable()();
  TextColumn get place => text().nullable()();
  TextColumn get coping => text().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get note => text().nullable()();

  /// manual | notification | widget | auto | import
  TextColumn get source => text().withDefault(const Constant('manual'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HabitPauseRow')
class HabitPauses extends Table with SyncedColumns {
  TextColumn get habitId => text().nullable()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text().nullable()();
  TextColumn get reason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HabitRevisionRow')
class HabitRevisions extends Table with SyncedColumns {
  TextColumn get habitId => text()();
  TextColumn get effectiveFrom => text()();
  TextColumn get schedule => text().nullable()();
  TextColumn get goalType => text().nullable()();
  RealColumn get targetValue => real().nullable()();
  TextColumn get targetOp => text().nullable()();
  TextColumn get unit => text().nullable()();
  RealColumn get baselinePerDay => real().nullable()();
  RealColumn get unitCost => real().nullable()();
  RealColumn get dailyLimit => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
