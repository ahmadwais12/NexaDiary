import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_ps.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
    Locale('ps'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'NexaDiary'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'files'**
  String get files;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchEverything.
  ///
  /// In en, this message translates to:
  /// **'Search everything...'**
  String get searchEverything;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @timetable.
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get timetable;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @privateVault.
  ///
  /// In en, this message translates to:
  /// **'Private Vault'**
  String get privateVault;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme'**
  String get darkModeDescription;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @fontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get fontFamily;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @small.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get small;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @large.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get large;

  /// No description provided for @extraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra Large'**
  String get extraLarge;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @dari.
  ///
  /// In en, this message translates to:
  /// **'دری (Dari)'**
  String get dari;

  /// No description provided for @pashto.
  ///
  /// In en, this message translates to:
  /// **'پښتو (Pashto)'**
  String get pashto;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @advertising.
  ///
  /// In en, this message translates to:
  /// **'Advertising'**
  String get advertising;

  /// No description provided for @adsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Ads Enabled'**
  String get adsEnabled;

  /// No description provided for @adsEnabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Show ads when online'**
  String get adsEnabledDescription;

  /// No description provided for @adInterval.
  ///
  /// In en, this message translates to:
  /// **'Ad Interval'**
  String get adInterval;

  /// No description provided for @adIntervalDescription.
  ///
  /// In en, this message translates to:
  /// **'Show ads every {minutes} minutes'**
  String adIntervalDescription(Object minutes);

  /// No description provided for @minimumLaunches.
  ///
  /// In en, this message translates to:
  /// **'Minimum Launches'**
  String get minimumLaunches;

  /// No description provided for @minimumLaunchesDescription.
  ///
  /// In en, this message translates to:
  /// **'Show ads after {count} app launches'**
  String minimumLaunchesDescription(Object count);

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @storageUsage.
  ///
  /// In en, this message translates to:
  /// **'Storage Usage'**
  String get storageUsage;

  /// No description provided for @clearTrash.
  ///
  /// In en, this message translates to:
  /// **'Clear Trash'**
  String get clearTrash;

  /// No description provided for @clearTrashDescription.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete trashed items'**
  String get clearTrashDescription;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @howWeHandleData.
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get howWeHandleData;

  /// No description provided for @yourPrivateWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Your private digital workspace'**
  String get yourPrivateWorkspace;

  /// No description provided for @noAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'No account required. Your data is stored locally on your device.'**
  String get noAccountRequired;

  /// No description provided for @allDataStoredLocally.
  ///
  /// In en, this message translates to:
  /// **'All data is stored locally on your device.'**
  String get allDataStoredLocally;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yourPrivateWorkspaceTagline.
  ///
  /// In en, this message translates to:
  /// **'Your private workspace'**
  String get yourPrivateWorkspaceTagline;

  /// No description provided for @noTasksForToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks for today'**
  String get noTasksForToday;

  /// No description provided for @noUpcomingReminders.
  ///
  /// In en, this message translates to:
  /// **'No upcoming reminders'**
  String get noUpcomingReminders;

  /// No description provided for @noTimetableForToday.
  ///
  /// In en, this message translates to:
  /// **'No timetable for today'**
  String get noTimetableForToday;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotesYet;

  /// No description provided for @noFilesYet.
  ///
  /// In en, this message translates to:
  /// **'No files yet'**
  String get noFilesYet;

  /// No description provided for @noReminders.
  ///
  /// In en, this message translates to:
  /// **'No reminders'**
  String get noReminders;

  /// No description provided for @noEventsFor.
  ///
  /// In en, this message translates to:
  /// **'No events for {day}'**
  String noEventsFor(Object day);

  /// No description provided for @quickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get quickAdd;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @task.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get task;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @folder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folder;

  /// No description provided for @recentNotes.
  ///
  /// In en, this message translates to:
  /// **'Recent Notes'**
  String get recentNotes;

  /// No description provided for @recentFiles.
  ///
  /// In en, this message translates to:
  /// **'Recent Files'**
  String get recentFiles;

  /// No description provided for @upcomingReminders.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Reminders'**
  String get upcomingReminders;

  /// No description provided for @localStorage.
  ///
  /// In en, this message translates to:
  /// **'Local Storage'**
  String get localStorage;

  /// No description provided for @allDataLocal.
  ///
  /// In en, this message translates to:
  /// **'All data is stored locally on your device'**
  String get allDataLocal;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @startWriting.
  ///
  /// In en, this message translates to:
  /// **'Start writing...'**
  String get startWriting;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create a backup of all your data'**
  String get createBackup;

  /// No description provided for @restoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore data from a backup file'**
  String get restoreFromBackup;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @allDataLocalBackup.
  ///
  /// In en, this message translates to:
  /// **'All data is stored locally on your device. Backups are created as files that you can store anywhere you choose.'**
  String get allDataLocalBackup;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New Folder'**
  String get newFolder;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderName;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @allPriorities.
  ///
  /// In en, this message translates to:
  /// **'All priorities'**
  String get allPriorities;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @searchReminders.
  ///
  /// In en, this message translates to:
  /// **'Search reminders...'**
  String get searchReminders;

  /// No description provided for @searchTimetable.
  ///
  /// In en, this message translates to:
  /// **'Search timetable...'**
  String get searchTimetable;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get description;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task title'**
  String get taskTitle;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @noDueTime.
  ///
  /// In en, this message translates to:
  /// **'No due time'**
  String get noDueTime;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @weekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get weekdays;

  /// No description provided for @weekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get weekends;

  /// No description provided for @newReminder.
  ///
  /// In en, this message translates to:
  /// **'New Reminder'**
  String get newReminder;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder title'**
  String get reminderTitle;

  /// No description provided for @once.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get once;

  /// No description provided for @createReminder.
  ///
  /// In en, this message translates to:
  /// **'Create Reminder'**
  String get createReminder;

  /// No description provided for @newEvent.
  ///
  /// In en, this message translates to:
  /// **'New Event'**
  String get newEvent;

  /// No description provided for @eventTitle.
  ///
  /// In en, this message translates to:
  /// **'Event title'**
  String get eventTitle;

  /// No description provided for @allDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @createEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEvent;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get markComplete;

  /// No description provided for @markPending.
  ///
  /// In en, this message translates to:
  /// **'Mark pending'**
  String get markPending;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add favorite'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove favorite'**
  String get removeFavorite;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchive;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChanges;

  /// No description provided for @unsavedChangesLost.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes will be lost.'**
  String get unsavedChangesLost;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get noteSaved;

  /// No description provided for @trashCleared.
  ///
  /// In en, this message translates to:
  /// **'Trash cleared'**
  String get trashCleared;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupSaved;

  /// No description provided for @backupImported.
  ///
  /// In en, this message translates to:
  /// **'Backup imported'**
  String get backupImported;

  /// No description provided for @importedFiles.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} file(s)'**
  String importedFiles(Object count);

  /// No description provided for @noCompletedTasks.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks'**
  String get noCompletedTasks;

  /// No description provided for @productivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get productivity;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'Your private digital workspace'**
  String get aboutApp;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'No account required. Your notes and files are stored locally. Internet is not required for core functionality.'**
  String get aboutDescription;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get noNotes;

  /// No description provided for @noArchivedNotes.
  ///
  /// In en, this message translates to:
  /// **'No archived notes'**
  String get noArchivedNotes;

  /// No description provided for @archiveNotesDesc.
  ///
  /// In en, this message translates to:
  /// **'Archive notes to hide them from the main list'**
  String get archiveNotesDesc;

  /// No description provided for @starNote.
  ///
  /// In en, this message translates to:
  /// **'Star a note to add it to favorites'**
  String get starNote;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites'**
  String get noFavorites;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get newNote;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleHint;

  /// No description provided for @contentHint.
  ///
  /// In en, this message translates to:
  /// **'Start writing...'**
  String get contentHint;

  /// No description provided for @noFiles.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get noFiles;

  /// No description provided for @importFiles.
  ///
  /// In en, this message translates to:
  /// **'Import files to your workspace'**
  String get importFiles;

  /// No description provided for @filesStoredLocal.
  ///
  /// In en, this message translates to:
  /// **'Files are stored locally on your device'**
  String get filesStoredLocal;

  /// No description provided for @pickFiles.
  ///
  /// In en, this message translates to:
  /// **'Pick Files'**
  String get pickFiles;

  /// No description provided for @allNotes.
  ///
  /// In en, this message translates to:
  /// **'All Notes'**
  String get allNotes;

  /// No description provided for @inFolder.
  ///
  /// In en, this message translates to:
  /// **'In Folder'**
  String get inFolder;

  /// No description provided for @media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get media;

  /// No description provided for @filesAndMedia.
  ///
  /// In en, this message translates to:
  /// **'Files & Media'**
  String get filesAndMedia;

  /// No description provided for @filesAndMediaDescription.
  ///
  /// In en, this message translates to:
  /// **'All your files, images, videos and audio'**
  String get filesAndMediaDescription;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videos;

  /// No description provided for @playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// No description provided for @voiceRecorder.
  ///
  /// In en, this message translates to:
  /// **'Voice Recorder'**
  String get voiceRecorder;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get nowPlaying;

  /// No description provided for @noMedia.
  ///
  /// In en, this message translates to:
  /// **'No media files yet'**
  String get noMedia;

  /// No description provided for @importMedia.
  ///
  /// In en, this message translates to:
  /// **'Import media from the Files tab'**
  String get importMedia;

  /// No description provided for @recentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get recentlyPlayed;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// No description provided for @fileLabel.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get fileLabel;

  /// No description provided for @noImagesYet.
  ///
  /// In en, this message translates to:
  /// **'No images yet'**
  String get noImagesYet;

  /// No description provided for @importImagesHint.
  ///
  /// In en, this message translates to:
  /// **'Import images from the Files tab'**
  String get importImagesHint;

  /// No description provided for @noVideosYet.
  ///
  /// In en, this message translates to:
  /// **'No videos yet'**
  String get noVideosYet;

  /// No description provided for @importVideosHint.
  ///
  /// In en, this message translates to:
  /// **'Import videos from the Files tab'**
  String get importVideosHint;

  /// No description provided for @noAudioFilesYet.
  ///
  /// In en, this message translates to:
  /// **'No audio files yet'**
  String get noAudioFilesYet;

  /// No description provided for @importAudioHint.
  ///
  /// In en, this message translates to:
  /// **'Import audio from the Files tab'**
  String get importAudioHint;

  /// No description provided for @noPlaylistsYet.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get noPlaylistsYet;

  /// No description provided for @createPlaylistHint.
  ///
  /// In en, this message translates to:
  /// **'Create a playlist to organize your audio'**
  String get createPlaylistHint;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @cannotPlayVideo.
  ///
  /// In en, this message translates to:
  /// **'Cannot play this video'**
  String get cannotPlayVideo;

  /// No description provided for @failedToPlayVideo.
  ///
  /// In en, this message translates to:
  /// **'Failed to play video: {error}'**
  String failedToPlayVideo(Object error);

  /// No description provided for @audioNotFound.
  ///
  /// In en, this message translates to:
  /// **'Audio not found'**
  String get audioNotFound;

  /// No description provided for @failedToPlayAudio.
  ///
  /// In en, this message translates to:
  /// **'Failed to play audio: {error}'**
  String failedToPlayAudio(Object error);

  /// No description provided for @incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get incorrectPin;

  /// No description provided for @setVaultPin.
  ///
  /// In en, this message translates to:
  /// **'Set up your vault'**
  String get setVaultPin;

  /// No description provided for @createPinDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a PIN to protect your private files'**
  String get createPinDescription;

  /// No description provided for @createPin.
  ///
  /// In en, this message translates to:
  /// **'Create PIN'**
  String get createPin;

  /// No description provided for @useBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use Biometrics'**
  String get useBiometrics;

  /// No description provided for @useBiometricsInstead.
  ///
  /// In en, this message translates to:
  /// **'Use Biometrics Instead'**
  String get useBiometricsInstead;

  /// No description provided for @enterNewPin.
  ///
  /// In en, this message translates to:
  /// **'Enter new PIN'**
  String get enterNewPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get enterPin;

  /// No description provided for @pinsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pinsDoNotMatch;

  /// No description provided for @fileBrowser.
  ///
  /// In en, this message translates to:
  /// **'File Browser'**
  String get fileBrowser;

  /// No description provided for @importFilesDescription.
  ///
  /// In en, this message translates to:
  /// **'Import files to your workspace'**
  String get importFilesDescription;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @microphonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission required'**
  String get microphonePermissionRequired;

  /// No description provided for @recordingSaved.
  ///
  /// In en, this message translates to:
  /// **'Recording saved'**
  String get recordingSaved;

  /// No description provided for @readyToRecord.
  ///
  /// In en, this message translates to:
  /// **'Ready to record'**
  String get readyToRecord;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recording;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @allTasks.
  ///
  /// In en, this message translates to:
  /// **'All Tasks'**
  String get allTasks;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @searchAcrossContent.
  ///
  /// In en, this message translates to:
  /// **'Search across all your content'**
  String get searchAcrossContent;

  /// No description provided for @notesCount.
  ///
  /// In en, this message translates to:
  /// **'Notes ({count})'**
  String notesCount(Object count);

  /// No description provided for @tasksCount.
  ///
  /// In en, this message translates to:
  /// **'Tasks ({count})'**
  String tasksCount(Object count);

  /// No description provided for @filesCount.
  ///
  /// In en, this message translates to:
  /// **'Files ({count})'**
  String filesCount(Object count);

  /// No description provided for @allStatsCalculatedLocally.
  ///
  /// In en, this message translates to:
  /// **'All statistics are calculated locally.'**
  String get allStatsCalculatedLocally;

  /// No description provided for @exportSection.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportSection;

  /// No description provided for @exportDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a backup of all your data'**
  String get exportDescription;

  /// No description provided for @importSection.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importSection;

  /// No description provided for @importDescription.
  ///
  /// In en, this message translates to:
  /// **'Restore data from a backup file'**
  String get importDescription;

  /// No description provided for @privacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacySection;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(Object error);

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Share failed: {error}'**
  String shareFailed(Object error);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(Object error);

  /// No description provided for @clearTrashConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear Trash?'**
  String get clearTrashConfirm;

  /// No description provided for @clearTrashDescription2.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all trashed items.'**
  String get clearTrashDescription2;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get cacheCleared;

  /// No description provided for @tapToAddNoteToVault.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a note to your vault'**
  String get tapToAddNoteToVault;

  /// No description provided for @tapToAddImagesToVault.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add images to your vault'**
  String get tapToAddImagesToVault;

  /// No description provided for @tapToAddVideosToVault.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add videos to your vault'**
  String get tapToAddVideosToVault;

  /// No description provided for @tapToAddFilesToVault.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add files to your vault'**
  String get tapToAddFilesToVault;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Enable push notifications'**
  String get notificationsDescription;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off'**
  String get notificationsDisabled;

  /// No description provided for @notificationSound.
  ///
  /// In en, this message translates to:
  /// **'Notification Sound'**
  String get notificationSound;

  /// No description provided for @defaultSound.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultSound;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @vibrationDescription.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on notifications'**
  String get vibrationDescription;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// No description provided for @appLockDescription.
  ///
  /// In en, this message translates to:
  /// **'Lock app with PIN or biometrics'**
  String get appLockDescription;

  /// No description provided for @encryptBackups.
  ///
  /// In en, this message translates to:
  /// **'Encrypt Backups'**
  String get encryptBackups;

  /// No description provided for @encryptBackupsDescription.
  ///
  /// In en, this message translates to:
  /// **'Encrypt backup files'**
  String get encryptBackupsDescription;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @clearCacheDescription.
  ///
  /// In en, this message translates to:
  /// **'Clear temporary files'**
  String get clearCacheDescription;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @noNotesInFolder.
  ///
  /// In en, this message translates to:
  /// **'No notes in this folder'**
  String get noNotesInFolder;

  /// No description provided for @noArchivedNotesHint.
  ///
  /// In en, this message translates to:
  /// **'No archived notes'**
  String get noArchivedNotesHint;

  /// No description provided for @allArchived.
  ///
  /// In en, this message translates to:
  /// **'All (Archived)'**
  String get allArchived;

  /// No description provided for @startEndDate.
  ///
  /// In en, this message translates to:
  /// **'Start - End'**
  String get startEndDate;

  /// No description provided for @dueTime.
  ///
  /// In en, this message translates to:
  /// **'Due Time'**
  String get dueTime;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to NexaDiary'**
  String get welcomeTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Your private digital workspace. Create notes, manage tasks and store files — all offline, no account required.'**
  String get welcomeMessage;

  /// No description provided for @chooseLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguageTitle;

  /// No description provided for @chooseLanguageMessage.
  ///
  /// In en, this message translates to:
  /// **'Select the language you prefer to use the app in. You can change it anytime in settings.'**
  String get chooseLanguageMessage;

  /// No description provided for @chooseThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your theme'**
  String get chooseThemeTitle;

  /// No description provided for @chooseThemeMessage.
  ///
  /// In en, this message translates to:
  /// **'Select the appearance of the app. You can change it anytime in settings.'**
  String get chooseThemeMessage;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @onboardingDone.
  ///
  /// In en, this message translates to:
  /// **'Setup complete. Enjoy your private workspace!'**
  String get onboardingDone;

  /// No description provided for @rateAppDescription.
  ///
  /// In en, this message translates to:
  /// **'Rate us on the store'**
  String get rateAppDescription;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// No description provided for @backupAndRestoreDescription.
  ///
  /// In en, this message translates to:
  /// **'Export or import your data'**
  String get backupAndRestoreDescription;

  /// No description provided for @appLockSetup.
  ///
  /// In en, this message translates to:
  /// **'Set up app lock to protect your workspace'**
  String get appLockSetup;

  /// No description provided for @cacheClearingDescription.
  ///
  /// In en, this message translates to:
  /// **'This will clear temporary files to free up space'**
  String get cacheClearingDescription;

  /// No description provided for @noTrashedItems.
  ///
  /// In en, this message translates to:
  /// **'No trashed items to clear'**
  String get noTrashedItems;

  /// No description provided for @trashedItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} trashed item(s) found'**
  String trashedItemsCount(Object count);

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreBackup;

  /// No description provided for @backupHistory.
  ///
  /// In en, this message translates to:
  /// **'Backup History'**
  String get backupHistory;

  /// No description provided for @noBackupsYet.
  ///
  /// In en, this message translates to:
  /// **'No backups yet'**
  String get noBackupsYet;

  /// No description provided for @lastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {date}'**
  String lastBackup(Object date);

  /// No description provided for @calendarDescription.
  ///
  /// In en, this message translates to:
  /// **'Plan your schedule'**
  String get calendarDescription;

  /// No description provided for @timetableDescription.
  ///
  /// In en, this message translates to:
  /// **'Organize your classes'**
  String get timetableDescription;

  /// No description provided for @remindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Never miss a task'**
  String get remindersDescription;

  /// No description provided for @favoritesDescription.
  ///
  /// In en, this message translates to:
  /// **'Quick access to important items'**
  String get favoritesDescription;

  /// No description provided for @privateVaultDescription.
  ///
  /// In en, this message translates to:
  /// **'Secure your sensitive files'**
  String get privateVaultDescription;

  /// No description provided for @mediaDescription.
  ///
  /// In en, this message translates to:
  /// **'Images, videos & audio'**
  String get mediaDescription;

  /// No description provided for @statisticsDescription.
  ///
  /// In en, this message translates to:
  /// **'View your usage stats'**
  String get statisticsDescription;

  /// No description provided for @backupLocation.
  ///
  /// In en, this message translates to:
  /// **'Backup Location'**
  String get backupLocation;

  /// No description provided for @backupPathDescription.
  ///
  /// In en, this message translates to:
  /// **'Your backup files are stored at this path:'**
  String get backupPathDescription;

  /// No description provided for @changePath.
  ///
  /// In en, this message translates to:
  /// **'Change Path'**
  String get changePath;

  /// No description provided for @defaultPath.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultPath;

  /// No description provided for @noBackupsInLocation.
  ///
  /// In en, this message translates to:
  /// **'No backup files found in this location'**
  String get noBackupsInLocation;

  /// No description provided for @backupFiles.
  ///
  /// In en, this message translates to:
  /// **'Backup Files'**
  String get backupFiles;

  /// No description provided for @deleteBackup.
  ///
  /// In en, this message translates to:
  /// **'Delete Backup'**
  String get deleteBackup;

  /// No description provided for @confirmDeleteBackup.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this backup? This cannot be undone.'**
  String get confirmDeleteBackup;

  /// No description provided for @pathUpdated.
  ///
  /// In en, this message translates to:
  /// **'Backup path updated'**
  String get pathUpdated;

  /// No description provided for @pathUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update path'**
  String get pathUpdateFailed;

  /// No description provided for @backupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Backup deleted'**
  String get backupDeleted;

  /// No description provided for @trash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trash;

  /// No description provided for @trashDescription.
  ///
  /// In en, this message translates to:
  /// **'View and restore deleted items'**
  String get trashDescription;

  /// No description provided for @trashEmpty.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get trashEmpty;

  /// No description provided for @trashHint.
  ///
  /// In en, this message translates to:
  /// **'Items you delete will appear here'**
  String get trashHint;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanently;

  /// No description provided for @permanentDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete \"{name}\"? This cannot be undone.'**
  String permanentDeleteConfirm(Object name);

  /// No description provided for @noteRestored.
  ///
  /// In en, this message translates to:
  /// **'Note restored'**
  String get noteRestored;

  /// No description provided for @taskRestored.
  ///
  /// In en, this message translates to:
  /// **'Task restored'**
  String get taskRestored;

  /// No description provided for @fileRestored.
  ///
  /// In en, this message translates to:
  /// **'File restored'**
  String get fileRestored;

  /// No description provided for @exchangeCalendar.
  ///
  /// In en, this message translates to:
  /// **'Exchange Calendar'**
  String get exchangeCalendar;

  /// No description provided for @exchangeCalendarDescription.
  ///
  /// In en, this message translates to:
  /// **'Switch between Gregorian, Hijri and Shamsi'**
  String get exchangeCalendarDescription;

  /// No description provided for @gregorian.
  ///
  /// In en, this message translates to:
  /// **'Gregorian'**
  String get gregorian;

  /// No description provided for @hijri.
  ///
  /// In en, this message translates to:
  /// **'Hijri (Islamic)'**
  String get hijri;

  /// No description provided for @shamsi.
  ///
  /// In en, this message translates to:
  /// **'Shamsi (Solar)'**
  String get shamsi;

  /// No description provided for @calendarType.
  ///
  /// In en, this message translates to:
  /// **'Calendar Type'**
  String get calendarType;

  /// No description provided for @shamsiMonth1.
  ///
  /// In en, this message translates to:
  /// **'Hamal'**
  String get shamsiMonth1;

  /// No description provided for @shamsiMonth2.
  ///
  /// In en, this message translates to:
  /// **'Sawr'**
  String get shamsiMonth2;

  /// No description provided for @shamsiMonth3.
  ///
  /// In en, this message translates to:
  /// **'Jawza'**
  String get shamsiMonth3;

  /// No description provided for @shamsiMonth4.
  ///
  /// In en, this message translates to:
  /// **'Saratan'**
  String get shamsiMonth4;

  /// No description provided for @shamsiMonth5.
  ///
  /// In en, this message translates to:
  /// **'Asad'**
  String get shamsiMonth5;

  /// No description provided for @shamsiMonth6.
  ///
  /// In en, this message translates to:
  /// **'Sunbula'**
  String get shamsiMonth6;

  /// No description provided for @shamsiMonth7.
  ///
  /// In en, this message translates to:
  /// **'Mizan'**
  String get shamsiMonth7;

  /// No description provided for @shamsiMonth8.
  ///
  /// In en, this message translates to:
  /// **'Aqrab'**
  String get shamsiMonth8;

  /// No description provided for @shamsiMonth9.
  ///
  /// In en, this message translates to:
  /// **'Qaws'**
  String get shamsiMonth9;

  /// No description provided for @shamsiMonth10.
  ///
  /// In en, this message translates to:
  /// **'Jadi'**
  String get shamsiMonth10;

  /// No description provided for @shamsiMonth11.
  ///
  /// In en, this message translates to:
  /// **'Dalw'**
  String get shamsiMonth11;

  /// No description provided for @shamsiMonth12.
  ///
  /// In en, this message translates to:
  /// **'Hoot'**
  String get shamsiMonth12;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa', 'ps'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
    case 'ps':
      return AppLocalizationsPs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
