// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unique_records_dao.dart';

// ignore_for_file: type=lint
mixin _$UniqueRecordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ComradeSettingsTableTable get comradeSettingsTable =>
      attachedDatabase.comradeSettingsTable;
  $ParentalControlsTableTable get parentalControlsTable =>
      attachedDatabase.parentalControlsTable;
  $BedtimeScheduleTableTable get bedtimeScheduleTable =>
      attachedDatabase.bedtimeScheduleTable;
  $FocusModeTableTable get focusModeTable => attachedDatabase.focusModeTable;
  $WellbeingTableTable get wellbeingTable => attachedDatabase.wellbeingTable;
  $SharedUniqueDataTableTable get sharedUniqueDataTable =>
      attachedDatabase.sharedUniqueDataTable;
  $NotificationSettingsTableTable get notificationSettingsTable =>
      attachedDatabase.notificationSettingsTable;
  UniqueRecordsDaoManager get managers => UniqueRecordsDaoManager(this);
}

class UniqueRecordsDaoManager {
  final _$UniqueRecordsDaoMixin _db;
  UniqueRecordsDaoManager(this._db);
  $$ComradeSettingsTableTableTableManager get comradeSettingsTable =>
      $$ComradeSettingsTableTableTableManager(
          _db.attachedDatabase, _db.comradeSettingsTable);
  $$ParentalControlsTableTableTableManager get parentalControlsTable =>
      $$ParentalControlsTableTableTableManager(
          _db.attachedDatabase, _db.parentalControlsTable);
  $$BedtimeScheduleTableTableTableManager get bedtimeScheduleTable =>
      $$BedtimeScheduleTableTableTableManager(
          _db.attachedDatabase, _db.bedtimeScheduleTable);
  $$FocusModeTableTableTableManager get focusModeTable =>
      $$FocusModeTableTableTableManager(
          _db.attachedDatabase, _db.focusModeTable);
  $$WellbeingTableTableTableManager get wellbeingTable =>
      $$WellbeingTableTableTableManager(
          _db.attachedDatabase, _db.wellbeingTable);
  $$SharedUniqueDataTableTableTableManager get sharedUniqueDataTable =>
      $$SharedUniqueDataTableTableTableManager(
          _db.attachedDatabase, _db.sharedUniqueDataTable);
  $$NotificationSettingsTableTableTableManager get notificationSettingsTable =>
      $$NotificationSettingsTableTableTableManager(
          _db.attachedDatabase, _db.notificationSettingsTable);
}
