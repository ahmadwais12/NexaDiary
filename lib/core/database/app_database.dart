import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// --- Tables ---

class Folders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get parentId => integer().nullable()();
  TextColumn get icon => text().withDefault(const Constant('folder'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
}

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get content => text().withDefault(const Constant(''))();
  BoolColumn get isRichText => boolean().withDefault(const Constant(true))();
  IntColumn get folderId => integer().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get color => text().withDefault(const Constant(''))();
  TextColumn get attachments => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get color => text().withDefault(const Constant('#6366f1'))();
  DateTimeColumn get createdAt => dateTime()();
}

class NoteTags extends Table {
  IntColumn get noteId => integer().references(Notes, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {noteId, tagId};
}

class AppFiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get filePath => text()();
  TextColumn get mimeType => text().withDefault(const Constant(''))();
  IntColumn get size => integer()();
  TextColumn get hash => text().nullable()();
  IntColumn get folderId => integer().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get color => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get dueTime => dateTime().nullable()();
  TextColumn get repeatRule => text().nullable()();
  IntColumn get category => integer().nullable()();
  IntColumn get noteId => integer().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get color => text().withDefault(const Constant(''))();
  BoolColumn get alarmEnabled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class TaskTags extends Table {
  IntColumn get taskId => integer().references(Tasks, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {taskId, tagId};
}

class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get reminderTime => dateTime()();
  TextColumn get repeatRule => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get taskId => integer().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get color => text().withDefault(const Constant(''))();
  BoolColumn get alarmEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
}

class TimetableEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get dayOfWeek => integer()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get color => text().withDefault(const Constant('#6366f1'))();
  IntColumn get taskId => integer().nullable()();
  IntColumn get noteId => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get alarmEnabled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

class CalendarEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();
  TextColumn get color => text().withDefault(const Constant('#6366f1'))();
  IntColumn get taskId => integer().nullable()();
  IntColumn get noteId => integer().nullable()();
  IntColumn get timetableEventId => integer().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get alarmEnabled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
}

class PlaylistItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId => integer().references(Playlists, #id)();
  IntColumn get fileId => integer().references(AppFiles, #id)();
  IntColumn get position => integer()();
  DateTimeColumn get addedAt => dateTime()();
}

class MediaHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fileId => integer().references(AppFiles, #id)();
  TextColumn get mediaType => text()();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get playedAt => dateTime()();
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class VaultItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemType => text()();
  IntColumn get itemId => integer()();
  TextColumn get encryptedName => text()();
  DateTimeColumn get addedAt => dateTime()();
}

class BackupHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get backupPath => text()();
  IntColumn get backupSize => integer()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status => text()();
}

class AdSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get launchCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAdShownAt => dateTime().nullable()();
  BoolColumn get adsEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get minimumAdIntervalMinutes =>
      integer().withDefault(const Constant(15))();
  IntColumn get minimumLaunchesBeforeAds =>
      integer().withDefault(const Constant(5))();
}

// --- Database ---

@DriftDatabase(
  tables: [
    Folders,
    Notes,
    Tags,
    NoteTags,
    AppFiles,
    Tasks,
    TaskTags,
    Reminders,
    TimetableEvents,
    CalendarEvents,
    Playlists,
    PlaylistItems,
    MediaHistory,
    Settings,
    VaultItems,
    BackupHistory,
    AdSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  static AppDatabase? _instance;

  AppDatabase._internal() : super(_openConnection());

  factory AppDatabase() => _instance ??= AppDatabase._internal();

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA journal_mode=WAL');
        await customStatement('PRAGMA foreign_keys=ON');
      },
      onCreate: (m) async {
        await m.createAll();
        await into(adSettings).insert(
          AdSettingsCompanion.insert(
            launchCount: const Value(0),
            adsEnabled: const Value(true),
            minimumAdIntervalMinutes: const Value(15),
            minimumLaunchesBeforeAds: const Value(3),
          ),
        );
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await customStatement(
            'UPDATE ad_settings '
            'SET ads_enabled = 1, '
            'minimum_ad_interval_minutes = 15, '
            'minimum_launches_before_ads = 3',
          );
        }
        if (from < 3) {
          await customStatement(
            "ALTER TABLE notes ADD COLUMN color TEXT NOT NULL DEFAULT ''",
          );
          await customStatement(
            "ALTER TABLE tasks ADD COLUMN color TEXT NOT NULL DEFAULT ''",
          );
          await customStatement(
            "ALTER TABLE reminders ADD COLUMN color TEXT NOT NULL DEFAULT ''",
          );
          await customStatement(
            "ALTER TABLE app_files ADD COLUMN color TEXT NOT NULL DEFAULT ''",
          );
        }
        if (from < 4) {
          await customStatement(
            "ALTER TABLE notes ADD COLUMN attachments TEXT NOT NULL DEFAULT '[]'",
          );
        }
        if (from < 5) {
          await customStatement(
            'ALTER TABLE tasks ADD COLUMN alarm_enabled INTEGER NOT NULL DEFAULT 0',
          );
          await customStatement(
            'ALTER TABLE reminders ADD COLUMN alarm_enabled INTEGER NOT NULL DEFAULT 1',
          );
          await customStatement(
            'ALTER TABLE timetable_events ADD COLUMN alarm_enabled INTEGER NOT NULL DEFAULT 0',
          );
          await customStatement(
            'ALTER TABLE calendar_events ADD COLUMN alarm_enabled INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }

  // --- Folders ---
  Future<List<Folder>> getAllFolders() =>
      (select(folders)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  Stream<List<Folder>> watchAllFolders() =>
      (select(folders)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  Future<Folder> getFolder(int id) =>
      (select(folders)..where((t) => t.id.equals(id))).getSingle();
  Future<int> createFolder(FoldersCompanion folder) =>
      into(folders).insert(folder);
  Future<int> updateFolder(FoldersCompanion folder) {
    final query = update(folders)..where((t) => t.id.equals(folder.id.value));
    return query.write(folder);
  }

  Future<int> deleteFolder(int id) =>
      (delete(folders)..where((t) => t.id.equals(id))).go();
  Stream<List<Folder>> watchSubFolders(int? parentId) {
    if (parentId != null) {
      return (select(
        folders,
      )..where((t) => t.parentId.equals(parentId))).watch();
    }
    return (select(folders)..where((t) => t.parentId.isNull())).watch();
  }

  // --- Notes ---
  Future<List<Note>> getAllNotes() =>
      (select(notes)
            ..where((t) => t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]))
          .get();
  Stream<List<Note>> watchAllNotes() =>
      (select(notes)
            ..where((t) => t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]))
          .watch();
  Future<List<Note>> getNotesByFolder(int? folderId) {
    final query = select(notes)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    if (folderId != null) query.where((t) => t.folderId.equals(folderId));
    return query.get();
  }

  Stream<List<Note>> watchNotesByFolder(int? folderId) {
    final query = select(notes)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    if (folderId != null) query.where((t) => t.folderId.equals(folderId));
    return query.watch();
  }

  Future<List<Note>> getFavoriteNotes() =>
      (select(notes)
            ..where(
              (t) => t.isFavorite.equals(true) & t.isDeleted.equals(false),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]))
          .get();
  Stream<List<Note>> watchFavoriteNotes() =>
      (select(notes)
            ..where(
              (t) => t.isFavorite.equals(true) & t.isDeleted.equals(false),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]))
          .watch();
  Future<Note> getNote(int id) =>
      (select(notes)..where((t) => t.id.equals(id))).getSingle();
  Future<int> createNote(NotesCompanion note) => into(notes).insert(note);
  Future<int> updateNote(NotesCompanion note) {
    final query = update(notes)..where((t) => t.id.equals(note.id.value));
    return query.write(note);
  }

  Future<int> deleteNote(int id) =>
      (delete(notes)..where((t) => t.id.equals(id))).go();
  Future<void> trashNote(int id) async {
    await (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isDeleted: const Value(true),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<Note>> searchNotes(String query) =>
      (select(notes)
            ..where(
              (t) =>
                  t.title.like('%$query%') |
                  t.content.like('%$query%') & t.isDeleted.equals(false),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]))
          .get();

  // --- Tags ---
  Future<List<Tag>> getAllTags() =>
      (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  Stream<List<Tag>> watchAllTags() =>
      (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  Future<int> createTag(TagsCompanion tag) => into(tags).insert(tag);
  Future<int> updateTag(TagsCompanion tag) {
    final query = update(tags)..where((t) => t.id.equals(tag.id.value));
    return query.write(tag);
  }

  Future<int> deleteTag(int id) =>
      (delete(tags)..where((t) => t.id.equals(id))).go();
  Future<void> addNoteTag(int noteId, int tagId) => into(noteTags).insert(
    NoteTagsCompanion.insert(noteId: noteId, tagId: tagId),
    mode: InsertMode.insertOrIgnore,
  );
  Future<void> removeNoteTag(int noteId, int tagId) => (delete(
    noteTags,
  )..where((t) => t.noteId.equals(noteId) & t.tagId.equals(tagId))).go();
  Future<void> removeNoteTags(int noteId) =>
      (delete(noteTags)..where((t) => t.noteId.equals(noteId))).go();
  Stream<List<Tag>> watchTagsForNote(int noteId) {
    final query = select(tags).join([
      innerJoin(noteTags, noteTags.tagId.equalsExp(tags.id)),
    ])..where(noteTags.noteId.equals(noteId));
    return query.map((row) => row.readTable(tags)).watch();
  }

  // --- AppFiles ---
  Future<List<AppFile>> getAllFiles() =>
      (select(appFiles)
            ..where((t) => t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]))
          .get();
  Stream<List<AppFile>> watchAllFiles() =>
      (select(appFiles)
            ..where((t) => t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]))
          .watch();
  Future<List<AppFile>> getFilesByFolder(int? folderId) {
    final query = select(appFiles)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    if (folderId != null) query.where((t) => t.folderId.equals(folderId));
    return query.get();
  }

  Stream<List<AppFile>> watchFilesByFolder(int? folderId) {
    final query = select(appFiles)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    if (folderId != null) query.where((t) => t.folderId.equals(folderId));
    return query.watch();
  }

  Future<AppFile> getFile(int id) =>
      (select(appFiles)..where((t) => t.id.equals(id))).getSingle();
  Future<int> createFile(AppFilesCompanion file) => into(appFiles).insert(file);
  Future<int> updateFile(AppFilesCompanion file) {
    final query = update(appFiles)..where((t) => t.id.equals(file.id.value));
    return query.write(file);
  }

  Future<int> deleteFile(int id) =>
      (delete(appFiles)..where((t) => t.id.equals(id))).go();
  Future<void> trashFile(int id) async {
    await (update(appFiles)..where((t) => t.id.equals(id))).write(
      AppFilesCompanion(
        isDeleted: const Value(true),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<AppFile>> watchFavoriteFiles() =>
      (select(appFiles)..where(
            (t) => t.isFavorite.equals(true) & t.isDeleted.equals(false),
          ))
          .watch();

  // --- Tasks ---
  Future<List<Task>> getAllTasks() =>
      (select(tasks)
            ..where((t) => t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();
  Stream<List<Task>> watchAllTasks() =>
      (select(tasks)
            ..where((t) => t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();
  Future<List<Task>> getTodayTasks() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(tasks)
          ..where(
            (t) =>
                t.dueDate.isBetweenValues(startOfDay, endOfDay) &
                t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.dueTime)]))
        .get();
  }

  Stream<List<Task>> watchTodayTasks() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(tasks)
          ..where(
            (t) =>
                t.dueDate.isBetweenValues(startOfDay, endOfDay) &
                t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.dueTime)]))
        .watch();
  }

  Future<Task> getTask(int id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingle();
  Future<int> createTask(TasksCompanion task) => into(tasks).insert(task);
  Future<int> updateTask(TasksCompanion task) {
    final query = update(tasks)..where((t) => t.id.equals(task.id.value));
    return query.write(task);
  }

  Future<int> deleteTask(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();
  Future<void> trashTask(int id) async {
    await (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isDeleted: const Value(true),
      ),
    );
  }
  Future<void> completeTask(int id) async {
    await (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        status: const Value('completed'),
        completedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Reminders ---
  Future<List<Reminder>> getAllReminders() => (select(
    reminders,
  )..orderBy([(t) => OrderingTerm.asc(t.reminderTime)])).get();
  Stream<List<Reminder>> watchAllReminders() => (select(
    reminders,
  )..orderBy([(t) => OrderingTerm.asc(t.reminderTime)])).watch();
  Future<List<Reminder>> getUpcomingReminders() {
    return (select(reminders)
          ..where(
            (t) =>
                t.isActive.equals(true) &
                t.reminderTime.isBiggerOrEqualValue(DateTime.now()),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.reminderTime)])
          ..limit(10))
        .get();
  }

  Stream<List<Reminder>> watchUpcomingReminders() {
    return (select(reminders)
          ..where(
            (t) =>
                t.isActive.equals(true) &
                t.reminderTime.isBiggerOrEqualValue(DateTime.now()),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.reminderTime)])
          ..limit(10))
        .watch();
  }

  Future<int> createReminder(RemindersCompanion reminder) =>
      into(reminders).insert(reminder);
  Future<int> updateReminder(RemindersCompanion reminder) {
    final query = update(reminders)
      ..where((t) => t.id.equals(reminder.id.value));
    return query.write(reminder);
  }

  Future<int> deleteReminder(int id) =>
      (delete(reminders)..where((t) => t.id.equals(id))).go();

  // --- Timetable ---
  Future<List<TimetableEvent>> getTimetableForDay(int dayOfWeek) =>
      (select(timetableEvents)
            ..where(
              (t) => t.dayOfWeek.equals(dayOfWeek) & t.isActive.equals(true),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
          .get();
  Stream<List<TimetableEvent>> watchTimetableForDay(int dayOfWeek) =>
      (select(timetableEvents)
            ..where(
              (t) => t.dayOfWeek.equals(dayOfWeek) & t.isActive.equals(true),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
          .watch();
  Future<int> createTimetableEvent(TimetableEventsCompanion event) =>
      into(timetableEvents).insert(event);
  Future<int> updateTimetableEvent(TimetableEventsCompanion event) {
    final query = update(timetableEvents)
      ..where((t) => t.id.equals(event.id.value));
    return query.write(event);
  }

  Future<int> deleteTimetableEvent(int id) =>
      (delete(timetableEvents)..where((t) => t.id.equals(id))).go();

  // --- Calendar ---
  Future<List<CalendarEvent>> getEventsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(calendarEvents)
          ..where(
            (t) =>
                t.startTime.isBiggerOrEqualValue(start) &
                t.startTime.isSmallerThanValue(end) &
                t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
  }

  Stream<List<CalendarEvent>> watchEventsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(calendarEvents)
          ..where(
            (t) =>
                t.startTime.isBiggerOrEqualValue(start) &
                t.startTime.isSmallerThanValue(end) &
                t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .watch();
  }

  Future<int> createCalendarEvent(CalendarEventsCompanion event) =>
      into(calendarEvents).insert(event);
  Future<int> updateCalendarEvent(CalendarEventsCompanion event) {
    final query = update(calendarEvents)
      ..where((t) => t.id.equals(event.id.value));
    return query.write(event);
  }

  Future<int> deleteCalendarEvent(int id) =>
      (delete(calendarEvents)..where((t) => t.id.equals(id))).go();
  Future<void> trashCalendarEvent(int id) async {
    await (update(calendarEvents)..where((t) => t.id.equals(id))).write(
      CalendarEventsCompanion(
        isDeleted: const Value(true),
      ),
    );
  }

  // --- Playlists ---
  Future<List<Playlist>> getAllPlaylists() =>
      (select(playlists)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  Stream<List<Playlist>> watchAllPlaylists() =>
      (select(playlists)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  Future<int> createPlaylist(PlaylistsCompanion playlist) =>
      into(playlists).insert(playlist);
  Future<int> updatePlaylist(PlaylistsCompanion playlist) {
    final query = update(playlists)
      ..where((t) => t.id.equals(playlist.id.value));
    return query.write(playlist);
  }

  Future<int> deletePlaylist(int id) =>
      (delete(playlists)..where((t) => t.id.equals(id))).go();

  // --- Media History ---
  Future<void> recordMediaPlay(
    int fileId,
    String mediaType,
    int positionMs,
    int durationMs,
  ) => into(mediaHistory).insert(
    MediaHistoryCompanion.insert(
      fileId: fileId,
      mediaType: mediaType,
      positionMs: Value(positionMs),
      durationMs: Value(durationMs),
      playedAt: DateTime.now(),
    ),
  );
  Stream<List<MediaHistoryData>> watchRecentlyPlayed({int limit = 20}) {
    return (select(mediaHistory)
          ..orderBy([(t) => OrderingTerm.desc(t.playedAt)])
          ..limit(limit))
        .watch();
  }

  // --- Settings ---
  Future<String?> getSetting(String key) async {
    final result = await (select(
      settings,
    )..where((t) => t.key.equals(key))).get();
    return result.isNotEmpty ? result.first.value : null;
  }

  Future<void> setSetting(String key, String value) async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion(key: Value(key), value: Value(value)),
    );
  }

  // --- Ad Settings ---
  Future<AdSetting> getAdSettings() => select(adSettings).getSingle();
  Stream<AdSetting> watchAdSettings() => select(adSettings).watchSingle();
  Future<void> updateAdSettings(AdSettingsCompanion adSettingsData) =>
      update(adSettings).write(adSettingsData);
  Future<void> incrementLaunchCount() async {
    final current = await getAdSettings();
    await (update(adSettings)..where((t) => t.id.equals(current.id))).write(
      AdSettingsCompanion(launchCount: Value(current.launchCount + 1)),
    );
  }

  Future<void> recordAdShown() async {
    await update(
      adSettings,
    ).write(AdSettingsCompanion(lastAdShownAt: Value(DateTime.now())));
  }

  // --- Search ---
  Future<List<Note>> searchAllNotes(String query) =>
      (select(notes)..where(
            (t) =>
                (t.title.like('%$query%') | t.content.like('%$query%')) &
                t.isDeleted.equals(false),
          ))
          .get();
  Future<List<Task>> searchAllTasks(String query) =>
      (select(tasks)..where(
            (t) =>
                (t.title.like('%$query%') | t.description.like('%$query%')) &
                t.isDeleted.equals(false),
          ))
          .get();
  Future<List<AppFile>> searchAllFiles(String query) => (select(
    appFiles,
  )..where((t) => t.name.like('%$query%') & t.isDeleted.equals(false))).get();

  // --- Backup ---
  Future<Map<String, dynamic>> exportAllData() async {
    final allNotes = await getAllNotes();
    final allTasks = await getAllTasks();
    final allFolders = await getAllFolders();
    final allTags = await getAllTags();
    final allReminders = await getAllReminders();

    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'notes': allNotes
          .map(
            (n) => {
              'id': n.id,
              'title': n.title,
              'content': n.content,
              'isFavorite': n.isFavorite,
              'isPinned': n.isPinned,
              'folderId': n.folderId,
              'createdAt': n.createdAt.toIso8601String(),
              'modifiedAt': n.modifiedAt.toIso8601String(),
            },
          )
          .toList(),
      'tasks': allTasks
          .map(
            (t) => {
              'id': t.id,
              'title': t.title,
              'description': t.description,
              'priority': t.priority,
              'status': t.status,
              'dueDate': t.dueDate?.toIso8601String(),
              'createdAt': t.createdAt.toIso8601String(),
            },
          )
          .toList(),
      'folders': allFolders
          .map((f) => {'id': f.id, 'name': f.name, 'parentId': f.parentId})
          .toList(),
      'tags': allTags
          .map((t) => {'id': t.id, 'name': t.name, 'color': t.color})
          .toList(),
      'reminders': allReminders
          .map(
            (r) => {
              'id': r.id,
              'title': r.title,
              'reminderTime': r.reminderTime.toIso8601String(),
              'repeatRule': r.repeatRule,
            },
          )
          .toList(),
    };
  }

  // --- Trash Restore ---
  Future<void> restoreNote(int id) async {
    await (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isDeleted: const Value(false),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> restoreTask(int id) async {
    await (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isDeleted: const Value(false),
      ),
    );
  }

  Future<void> restoreFile(int id) async {
    await (update(appFiles)..where((t) => t.id.equals(id))).write(
      AppFilesCompanion(
        isDeleted: const Value(false),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<Note>> watchTrashedNotes() =>
      (select(notes)
            ..where((t) => t.isDeleted.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]))
          .watch();

  Stream<List<Task>> watchTrashedTasks() =>
      (select(tasks)
            ..where((t) => t.isDeleted.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Stream<List<AppFile>> watchTrashedFiles() =>
      (select(appFiles)
            ..where((t) => t.isDeleted.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]))
          .watch();

  // --- Trash Management ---
  Future<void> clearTrashedNotes() async {
    await (delete(notes)..where((t) => t.isDeleted.equals(true))).go();
  }

  Future<void> clearTrashedTasks() async {
    await (delete(tasks)..where((t) => t.isDeleted.equals(true))).go();
  }

  Future<void> clearTrashedFiles() async {
    await (delete(appFiles)..where((t) => t.isDeleted.equals(true))).go();
  }

  Future<void> clearAllTrashed() async {
    await clearTrashedNotes();
    await clearTrashedTasks();
    await clearTrashedFiles();
  }

  Future<int> getTrashedCount() async {
    final notesCount = await (select(
      notes,
    )..where((t) => t.isDeleted.equals(true))).get();
    final tasksCount = await (select(
      tasks,
    )..where((t) => t.isDeleted.equals(true))).get();
    final filesCount = await (select(
      appFiles,
    )..where((t) => t.isDeleted.equals(true))).get();
    return notesCount.length + tasksCount.length + filesCount.length;
  }

  // --- Storage Stats ---
  Future<int> getNotesCount() async {
    final result = await customSelect(
      'SELECT COUNT(*) as count FROM notes WHERE is_deleted = 0',
    ).get();
    return result.first.data['count'] as int;
  }

  Future<int> getTasksCount() async {
    final result = await customSelect(
      'SELECT COUNT(*) as count FROM tasks WHERE is_deleted = 0',
    ).get();
    return result.first.data['count'] as int;
  }

  Future<int> getFilesCount() async {
    final result = await customSelect(
      'SELECT COUNT(*) as count FROM app_files WHERE is_deleted = 0',
    ).get();
    return result.first.data['count'] as int;
  }

  Future<int> getRemindersCount() async {
    final result = await customSelect(
      'SELECT COUNT(*) as count FROM reminders WHERE is_active = 1',
    ).get();
    return result.first.data['count'] as int;
  }

  Future<int> getTimetableEventsCount() async {
    final result = await customSelect(
      'SELECT COUNT(*) as count FROM timetable_events WHERE is_active = 1',
    ).get();
    return result.first.data['count'] as int;
  }

  Future<int> getCalendarEventsCount() async {
    final result = await customSelect(
      'SELECT COUNT(*) as count FROM calendar_events WHERE is_deleted = 0',
    ).get();
    return result.first.data['count'] as int;
  }

  // --- Backup History ---
  Stream<List<BackupHistoryData>> watchBackupHistory() {
    return (select(
      backupHistory,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Future<List<BackupHistoryData>> getBackupHistory() {
    return (select(
      backupHistory,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'workspace.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
