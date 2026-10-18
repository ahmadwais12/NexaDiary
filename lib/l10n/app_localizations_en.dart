// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NexaDiary';

  @override
  String get home => 'Home';

  @override
  String get notes => 'Notes';

  @override
  String get tasks => 'Tasks';

  @override
  String get files => 'files';

  @override
  String get more => 'More';

  @override
  String get settings => 'Settings';

  @override
  String get search => 'Search';

  @override
  String get searchEverything => 'Search everything...';

  @override
  String get calendar => 'Calendar';

  @override
  String get timetable => 'Timetable';

  @override
  String get reminders => 'Reminders';

  @override
  String get favorites => 'Favorites';

  @override
  String get privateVault => 'Private Vault';

  @override
  String get backup => 'Backup';

  @override
  String get statistics => 'Statistics';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeDescription => 'Use dark theme';

  @override
  String get language => 'Language';

  @override
  String get fontFamily => 'Font Family';

  @override
  String get fontSize => 'Font Size';

  @override
  String get small => 'Small';

  @override
  String get medium => 'Medium';

  @override
  String get large => 'Large';

  @override
  String get extraLarge => 'Extra Large';

  @override
  String get english => 'English';

  @override
  String get dari => 'دری (Dari)';

  @override
  String get pashto => 'پښتو (Pashto)';

  @override
  String get appearance => 'Appearance';

  @override
  String get advertising => 'Advertising';

  @override
  String get adsEnabled => 'Ads Enabled';

  @override
  String get adsEnabledDescription => 'Show ads when online';

  @override
  String get adInterval => 'Ad Interval';

  @override
  String adIntervalDescription(Object minutes) {
    return 'Show ads every $minutes minutes';
  }

  @override
  String get minimumLaunches => 'Minimum Launches';

  @override
  String minimumLaunchesDescription(Object count) {
    return 'Show ads after $count app launches';
  }

  @override
  String get data => 'Data';

  @override
  String get storageUsage => 'Storage Usage';

  @override
  String get clearTrash => 'Clear Trash';

  @override
  String get clearTrashDescription => 'Permanently delete trashed items';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get howWeHandleData => 'How we handle your data';

  @override
  String get yourPrivateWorkspace => 'Your private digital workspace';

  @override
  String get noAccountRequired =>
      'No account required. Your data is stored locally on your device.';

  @override
  String get allDataStoredLocally =>
      'All data is stored locally on your device.';

  @override
  String get today => 'Today';

  @override
  String get yourPrivateWorkspaceTagline => 'Your private workspace';

  @override
  String get noTasksForToday => 'No tasks for today';

  @override
  String get noUpcomingReminders => 'No upcoming reminders';

  @override
  String get noTimetableForToday => 'No timetable for today';

  @override
  String get noNotesYet => 'No notes yet';

  @override
  String get noFilesYet => 'No files yet';

  @override
  String get noReminders => 'No reminders';

  @override
  String noEventsFor(Object day) {
    return 'No events for $day';
  }

  @override
  String get quickAdd => 'Quick Add';

  @override
  String get note => 'Note';

  @override
  String get task => 'Task';

  @override
  String get reminder => 'Reminder';

  @override
  String get file => 'File';

  @override
  String get image => 'Image';

  @override
  String get audio => 'Audio';

  @override
  String get folder => 'Folder';

  @override
  String get recentNotes => 'Recent Notes';

  @override
  String get recentFiles => 'Recent Files';

  @override
  String get upcomingReminders => 'Upcoming Reminders';

  @override
  String get localStorage => 'Local Storage';

  @override
  String get allDataLocal => 'All data is stored locally on your device';

  @override
  String get title => 'Title';

  @override
  String get startWriting => 'Start writing...';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get discard => 'Discard';

  @override
  String get create => 'Create';

  @override
  String get rename => 'Rename';

  @override
  String get import => 'Import';

  @override
  String get export => 'Export';

  @override
  String get share => 'Share';

  @override
  String get exportData => 'Export Data';

  @override
  String get importBackup => 'Import Backup';

  @override
  String get createBackup => 'Create a backup of all your data';

  @override
  String get restoreFromBackup => 'Restore data from a backup file';

  @override
  String get privacy => 'Privacy';

  @override
  String get allDataLocalBackup =>
      'All data is stored locally on your device. Backups are created as files that you can store anywhere you choose.';

  @override
  String get newFolder => 'New Folder';

  @override
  String get folderName => 'Folder name';

  @override
  String get all => 'All';

  @override
  String get pending => 'Pending';

  @override
  String get completed => 'Completed';

  @override
  String get allPriorities => 'All priorities';

  @override
  String get urgent => 'Urgent';

  @override
  String get high => 'High';

  @override
  String get low => 'Low';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get searchReminders => 'Search reminders...';

  @override
  String get searchTimetable => 'Search timetable...';

  @override
  String get description => 'Description (optional)';

  @override
  String get taskTitle => 'Task title';

  @override
  String get dueDate => 'Due Date';

  @override
  String get noDueDate => 'No due date';

  @override
  String get noDueTime => 'No due time';

  @override
  String get repeat => 'Repeat';

  @override
  String get none => 'None';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get weekdays => 'Weekdays';

  @override
  String get weekends => 'Weekends';

  @override
  String get newReminder => 'New Reminder';

  @override
  String get reminderTitle => 'Reminder title';

  @override
  String get once => 'Once';

  @override
  String get createReminder => 'Create Reminder';

  @override
  String get newEvent => 'New Event';

  @override
  String get eventTitle => 'Event title';

  @override
  String get allDay => 'All day';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get createEvent => 'Create Event';

  @override
  String get markComplete => 'Mark complete';

  @override
  String get markPending => 'Mark pending';

  @override
  String get addFavorite => 'Add favorite';

  @override
  String get removeFavorite => 'Remove favorite';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get archive => 'Archive';

  @override
  String get unarchive => 'Unarchive';

  @override
  String get discardChanges => 'Discard changes?';

  @override
  String get unsavedChangesLost => 'Unsaved changes will be lost.';

  @override
  String get noteSaved => 'Note saved';

  @override
  String get trashCleared => 'Trash cleared';

  @override
  String get backupSaved => 'Backup saved';

  @override
  String get backupImported => 'Backup imported';

  @override
  String importedFiles(Object count) {
    return 'Imported $count file(s)';
  }

  @override
  String get noCompletedTasks => 'No completed tasks';

  @override
  String get productivity => 'Productivity';

  @override
  String get content => 'Content';

  @override
  String get tools => 'Tools';

  @override
  String get aboutApp => 'Your private digital workspace';

  @override
  String get aboutDescription =>
      'No account required. Your notes and files are stored locally. Internet is not required for core functionality.';

  @override
  String get noNotes => 'No notes';

  @override
  String get noArchivedNotes => 'No archived notes';

  @override
  String get archiveNotesDesc =>
      'Archive notes to hide them from the main list';

  @override
  String get starNote => 'Star a note to add it to favorites';

  @override
  String get noFavorites => 'No favorites';

  @override
  String get newNote => 'New Note';

  @override
  String get titleHint => 'Title';

  @override
  String get contentHint => 'Start writing...';

  @override
  String get noFiles => 'No files';

  @override
  String get importFiles => 'Import files to your workspace';

  @override
  String get filesStoredLocal => 'Files are stored locally on your device';

  @override
  String get pickFiles => 'Pick Files';

  @override
  String get allNotes => 'All Notes';

  @override
  String get inFolder => 'In Folder';

  @override
  String get media => 'Media';

  @override
  String get filesAndMedia => 'Files & Media';

  @override
  String get filesAndMediaDescription =>
      'All your files, images, videos and audio';

  @override
  String get images => 'Images';

  @override
  String get videos => 'Videos';

  @override
  String get playlists => 'Playlists';

  @override
  String get voiceRecorder => 'Voice Recorder';

  @override
  String get nowPlaying => 'Now Playing';

  @override
  String get noMedia => 'No media files yet';

  @override
  String get importMedia => 'Import media from the Files tab';

  @override
  String get recentlyPlayed => 'Recently Played';

  @override
  String get noteLabel => 'Note';

  @override
  String get fileLabel => 'File';

  @override
  String get noImagesYet => 'No images yet';

  @override
  String get importImagesHint => 'Import images from the Files tab';

  @override
  String get noVideosYet => 'No videos yet';

  @override
  String get importVideosHint => 'Import videos from the Files tab';

  @override
  String get noAudioFilesYet => 'No audio files yet';

  @override
  String get importAudioHint => 'Import audio from the Files tab';

  @override
  String get noPlaylistsYet => 'No playlists yet';

  @override
  String get createPlaylistHint => 'Create a playlist to organize your audio';

  @override
  String get video => 'Video';

  @override
  String get cannotPlayVideo => 'Cannot play this video';

  @override
  String failedToPlayVideo(Object error) {
    return 'Failed to play video: $error';
  }

  @override
  String get audioNotFound => 'Audio not found';

  @override
  String failedToPlayAudio(Object error) {
    return 'Failed to play audio: $error';
  }

  @override
  String get incorrectPin => 'Incorrect PIN';

  @override
  String get setVaultPin => 'Set up your vault';

  @override
  String get createPinDescription =>
      'Create a PIN to protect your private files';

  @override
  String get createPin => 'Create PIN';

  @override
  String get useBiometrics => 'Use Biometrics';

  @override
  String get useBiometricsInstead => 'Use Biometrics Instead';

  @override
  String get enterNewPin => 'Enter new PIN';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get enterPin => 'Enter your PIN';

  @override
  String get pinsDoNotMatch => 'PINs do not match';

  @override
  String get fileBrowser => 'File Browser';

  @override
  String get importFilesDescription => 'Import files to your workspace';

  @override
  String get error => 'Error';

  @override
  String get microphonePermissionRequired => 'Microphone permission required';

  @override
  String get recordingSaved => 'Recording saved';

  @override
  String get readyToRecord => 'Ready to record';

  @override
  String get recording => 'Recording...';

  @override
  String get paused => 'Paused';

  @override
  String get allTasks => 'All Tasks';

  @override
  String get priority => 'Priority';

  @override
  String get searchAcrossContent => 'Search across all your content';

  @override
  String notesCount(Object count) {
    return 'Notes ($count)';
  }

  @override
  String tasksCount(Object count) {
    return 'Tasks ($count)';
  }

  @override
  String filesCount(Object count) {
    return 'Files ($count)';
  }

  @override
  String get allStatsCalculatedLocally =>
      'All statistics are calculated locally.';

  @override
  String get exportSection => 'Export';

  @override
  String get exportDescription => 'Create a backup of all your data';

  @override
  String get importSection => 'Import';

  @override
  String get importDescription => 'Restore data from a backup file';

  @override
  String get privacySection => 'Privacy';

  @override
  String exportFailed(Object error) {
    return 'Export failed: $error';
  }

  @override
  String shareFailed(Object error) {
    return 'Share failed: $error';
  }

  @override
  String importFailed(Object error) {
    return 'Import failed: $error';
  }

  @override
  String get clearTrashConfirm => 'Clear Trash?';

  @override
  String get clearTrashDescription2 =>
      'This will permanently delete all trashed items.';

  @override
  String get cacheCleared => 'Cache cleared';

  @override
  String get tapToAddNoteToVault => 'Tap + to add a note to your vault';

  @override
  String get tapToAddImagesToVault => 'Tap + to add images to your vault';

  @override
  String get tapToAddVideosToVault => 'Tap + to add videos to your vault';

  @override
  String get tapToAddFilesToVault => 'Tap + to add files to your vault';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsDescription => 'Enable push notifications';

  @override
  String get notificationsDisabled => 'Notifications are turned off';

  @override
  String get notificationSound => 'Notification Sound';

  @override
  String get defaultSound => 'Default';

  @override
  String get vibration => 'Vibration';

  @override
  String get vibrationDescription => 'Vibrate on notifications';

  @override
  String get security => 'Security';

  @override
  String get appLock => 'App Lock';

  @override
  String get appLockDescription => 'Lock app with PIN or biometrics';

  @override
  String get encryptBackups => 'Encrypt Backups';

  @override
  String get encryptBackupsDescription => 'Encrypt backup files';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get clearCacheDescription => 'Clear temporary files';

  @override
  String get rateApp => 'Rate App';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get noNotesInFolder => 'No notes in this folder';

  @override
  String get noArchivedNotesHint => 'No archived notes';

  @override
  String get allArchived => 'All (Archived)';

  @override
  String get startEndDate => 'Start - End';

  @override
  String get dueTime => 'Due Time';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get welcomeTitle => 'Welcome to NexaDiary';

  @override
  String get welcomeMessage =>
      'Your private digital workspace. Create notes, manage tasks and store files — all offline, no account required.';

  @override
  String get chooseLanguageTitle => 'Choose your language';

  @override
  String get chooseLanguageMessage =>
      'Select the language you prefer to use the app in. You can change it anytime in settings.';

  @override
  String get chooseThemeTitle => 'Choose your theme';

  @override
  String get chooseThemeMessage =>
      'Select the appearance of the app. You can change it anytime in settings.';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get onboardingDone => 'Setup complete. Enjoy your private workspace!';

  @override
  String get rateAppDescription => 'Rate us on the store';

  @override
  String get backupAndRestore => 'Backup & Restore';

  @override
  String get backupAndRestoreDescription => 'Export or import your data';

  @override
  String get appLockSetup => 'Set up app lock to protect your workspace';

  @override
  String get cacheClearingDescription =>
      'This will clear temporary files to free up space';

  @override
  String get noTrashedItems => 'No trashed items to clear';

  @override
  String trashedItemsCount(Object count) {
    return '$count trashed item(s) found';
  }

  @override
  String get restoreBackup => 'Restore Backup';

  @override
  String get backupHistory => 'Backup History';

  @override
  String get noBackupsYet => 'No backups yet';

  @override
  String lastBackup(Object date) {
    return 'Last backup: $date';
  }

  @override
  String get calendarDescription => 'Plan your schedule';

  @override
  String get timetableDescription => 'Organize your classes';

  @override
  String get remindersDescription => 'Never miss a task';

  @override
  String get favoritesDescription => 'Quick access to important items';

  @override
  String get privateVaultDescription => 'Secure your sensitive files';

  @override
  String get mediaDescription => 'Images, videos & audio';

  @override
  String get statisticsDescription => 'View your usage stats';

  @override
  String get backupLocation => 'Backup Location';

  @override
  String get backupPathDescription =>
      'Your backup files are stored at this path:';

  @override
  String get changePath => 'Change Path';

  @override
  String get defaultPath => 'Default';

  @override
  String get noBackupsInLocation => 'No backup files found in this location';

  @override
  String get backupFiles => 'Backup Files';

  @override
  String get deleteBackup => 'Delete Backup';

  @override
  String get confirmDeleteBackup =>
      'Are you sure you want to delete this backup? This cannot be undone.';

  @override
  String get pathUpdated => 'Backup path updated';

  @override
  String get pathUpdateFailed => 'Failed to update path';

  @override
  String get backupDeleted => 'Backup deleted';

  @override
  String get trash => 'Trash';

  @override
  String get trashDescription => 'View and restore deleted items';

  @override
  String get trashEmpty => 'Trash is empty';

  @override
  String get trashHint => 'Items you delete will appear here';

  @override
  String get restore => 'Restore';

  @override
  String get deletePermanently => 'Delete Permanently';

  @override
  String permanentDeleteConfirm(Object name) {
    return 'Are you sure you want to permanently delete \"$name\"? This cannot be undone.';
  }

  @override
  String get noteRestored => 'Note restored';

  @override
  String get taskRestored => 'Task restored';

  @override
  String get fileRestored => 'File restored';

  @override
  String get exchangeCalendar => 'Exchange Calendar';

  @override
  String get exchangeCalendarDescription =>
      'Switch between Gregorian, Hijri and Shamsi';

  @override
  String get gregorian => 'Gregorian';

  @override
  String get hijri => 'Hijri (Islamic)';

  @override
  String get shamsi => 'Shamsi (Solar)';

  @override
  String get calendarType => 'Calendar Type';

  @override
  String get shamsiMonth1 => 'Hamal';

  @override
  String get shamsiMonth2 => 'Sawr';

  @override
  String get shamsiMonth3 => 'Jawza';

  @override
  String get shamsiMonth4 => 'Saratan';

  @override
  String get shamsiMonth5 => 'Asad';

  @override
  String get shamsiMonth6 => 'Sunbula';

  @override
  String get shamsiMonth7 => 'Mizan';

  @override
  String get shamsiMonth8 => 'Aqrab';

  @override
  String get shamsiMonth9 => 'Qaws';

  @override
  String get shamsiMonth10 => 'Jadi';

  @override
  String get shamsiMonth11 => 'Dalw';

  @override
  String get shamsiMonth12 => 'Hoot';
}
