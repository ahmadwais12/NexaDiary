// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'NexaDiary';

  @override
  String get home => 'خانه';

  @override
  String get notes => 'یادداشت‌ها';

  @override
  String get tasks => 'وظایف';

  @override
  String get files => 'فایل';

  @override
  String get more => 'بیشتر';

  @override
  String get settings => 'تنظیمات';

  @override
  String get search => 'جستجو';

  @override
  String get searchEverything => 'همه چیز را جستجو کنید...';

  @override
  String get calendar => 'تقویم';

  @override
  String get timetable => 'برنامه زمانی';

  @override
  String get reminders => 'یادآوری‌ها';

  @override
  String get favorites => 'علاقه‌مندی‌ها';

  @override
  String get privateVault => 'گاوصندوق خصوصی';

  @override
  String get backup => 'نسخه پشتیبان';

  @override
  String get statistics => 'آمار';

  @override
  String get darkMode => 'حالت تاریک';

  @override
  String get darkModeDescription => 'استفاده از تم تاریک';

  @override
  String get language => 'زبان';

  @override
  String get fontFamily => 'خانواده فونت';

  @override
  String get fontSize => 'اندازه فونت';

  @override
  String get small => 'کوچک';

  @override
  String get medium => 'متوسط';

  @override
  String get large => 'بزرگ';

  @override
  String get extraLarge => 'خیلی بزرگ';

  @override
  String get english => 'English';

  @override
  String get dari => 'دری (Dari)';

  @override
  String get pashto => 'پښتو (Pashto)';

  @override
  String get appearance => 'ظاهر';

  @override
  String get advertising => 'تبلیغات';

  @override
  String get adsEnabled => 'تبلیغات فعال';

  @override
  String get adsEnabledDescription => 'نمایش تبلیغات هنگام آنلاین بودن';

  @override
  String get adInterval => 'فاصله تبلیغات';

  @override
  String adIntervalDescription(Object minutes) {
    return 'نمایش تبلیغات هر $minutes دقیقه';
  }

  @override
  String get minimumLaunches => 'حداقل اجراها';

  @override
  String minimumLaunchesDescription(Object count) {
    return 'نمایش تبلیغات پس از $count بار اجرا';
  }

  @override
  String get data => 'داده‌ها';

  @override
  String get storageUsage => 'فضای ذخیره‌سازی';

  @override
  String get clearTrash => 'پاک کردن سطل زباله';

  @override
  String get clearTrashDescription => 'حذف دائمی موارد سطل زباله';

  @override
  String get about => 'درباره';

  @override
  String get version => 'نسخه';

  @override
  String get privacyPolicy => 'حریم خصوصی';

  @override
  String get howWeHandleData => 'نحوه مدیریت داده‌های شما';

  @override
  String get yourPrivateWorkspace => 'فضای کاری خصوصی شما';

  @override
  String get noAccountRequired =>
      'نیازی به حساب کاربری نیست. داده‌های شما به صورت محلی ذخیره می‌شوند.';

  @override
  String get allDataStoredLocally => 'همه داده‌ها به صورت محلی ذخیره می‌شوند.';

  @override
  String get today => 'امروز';

  @override
  String get yourPrivateWorkspaceTagline => 'فضای کاری خصوصی شما';

  @override
  String get noTasksForToday => 'وظیفه‌ای برای امروز نیست';

  @override
  String get noUpcomingReminders => 'یادآوری آینده‌ای نیست';

  @override
  String get noTimetableForToday => 'برنامه زمانی امروز خالی است';

  @override
  String get noNotesYet => 'هنوز یادداشتی نیست';

  @override
  String get noFilesYet => 'هنوز فایلی نیست';

  @override
  String get noReminders => 'یادآوری نیست';

  @override
  String noEventsFor(Object day) {
    return 'رویدادی برای $day نیست';
  }

  @override
  String get quickAdd => 'افزودن سریع';

  @override
  String get note => 'یادداشت';

  @override
  String get task => 'وظیفه';

  @override
  String get reminder => 'یادآوری';

  @override
  String get file => 'فایل';

  @override
  String get image => 'تصویر';

  @override
  String get audio => 'صدا';

  @override
  String get folder => 'پوشه';

  @override
  String get recentNotes => 'یادداشت‌های اخیر';

  @override
  String get recentFiles => 'فایل‌های اخیر';

  @override
  String get upcomingReminders => 'یادآوری‌های آینده';

  @override
  String get localStorage => 'ذخیره‌سازی محلی';

  @override
  String get allDataLocal => 'همه داده‌ها به صورت محلی ذخیره می‌شوند';

  @override
  String get title => 'عنوان';

  @override
  String get startWriting => 'شروع به نوشتن...';

  @override
  String get save => 'ذخیره';

  @override
  String get cancel => 'لغو';

  @override
  String get delete => 'حذف';

  @override
  String get discard => 'رها کردن';

  @override
  String get create => 'ایجاد';

  @override
  String get rename => 'تغییر نام';

  @override
  String get import => 'وارد کردن';

  @override
  String get export => 'خروجی';

  @override
  String get share => 'اشتراک‌گذاری';

  @override
  String get exportData => 'خروجی داده‌ها';

  @override
  String get importBackup => 'وارد کردن نسخه پشتیبان';

  @override
  String get createBackup => 'ایجاد نسخه پشتیبان از همه داده‌ها';

  @override
  String get restoreFromBackup => 'بازیابی از فایل پشتیبان';

  @override
  String get privacy => 'حریم خصوصی';

  @override
  String get allDataLocalBackup =>
      'همه داده‌ها به صورت محلی ذخیره می‌شوند. نسخه‌های پشتیبان به صورت فایل‌هایی ایجاد می‌شوند که می‌توانید هر جا بخواهید ذخیره کنید.';

  @override
  String get newFolder => 'پوشه جدید';

  @override
  String get folderName => 'نام پوشه';

  @override
  String get all => 'همه';

  @override
  String get pending => 'در انتظار';

  @override
  String get completed => 'تکمیل شده';

  @override
  String get allPriorities => 'همه اولویت‌ها';

  @override
  String get urgent => 'فوری';

  @override
  String get high => 'بالا';

  @override
  String get low => 'پایین';

  @override
  String get active => 'فعال';

  @override
  String get inactive => 'غیرفعال';

  @override
  String get searchReminders => 'جستجوی یادآوری‌ها...';

  @override
  String get searchTimetable => 'جستجوی برنامه هفتگی...';

  @override
  String get description => 'توضیحات (اختیاری)';

  @override
  String get taskTitle => 'عنوان وظیفه';

  @override
  String get dueDate => 'تاریخ سررسید';

  @override
  String get noDueDate => 'بدون تاریخ سررسید';

  @override
  String get noDueTime => 'بدون ساعت سررسید';

  @override
  String get repeat => 'تکرار';

  @override
  String get none => 'هیچ';

  @override
  String get daily => 'روزانه';

  @override
  String get weekly => 'هفتگی';

  @override
  String get monthly => 'ماهانه';

  @override
  String get yearly => 'سالانه';

  @override
  String get weekdays => 'روزهای کاری';

  @override
  String get weekends => 'آخر هفته';

  @override
  String get newReminder => 'یادآوری جدید';

  @override
  String get reminderTitle => 'عنوان یادآوری';

  @override
  String get once => 'یک بار';

  @override
  String get createReminder => 'ایجاد یادآوری';

  @override
  String get newEvent => 'رویداد جدید';

  @override
  String get eventTitle => 'عنوان رویداد';

  @override
  String get allDay => 'تمام روز';

  @override
  String get start => 'شروع';

  @override
  String get end => 'پایان';

  @override
  String get createEvent => 'ایجاد رویداد';

  @override
  String get markComplete => 'تکمیل کردن';

  @override
  String get markPending => 'در انتظار کردن';

  @override
  String get addFavorite => 'افزودن به علاقه‌مندی‌ها';

  @override
  String get removeFavorite => 'حذف از علاقه‌مندی‌ها';

  @override
  String get pin => 'سنجاق کردن';

  @override
  String get unpin => 'حذف سنجاق';

  @override
  String get archive => 'بایگانی';

  @override
  String get unarchive => 'حذف بایگانی';

  @override
  String get discardChanges => 'تغییرات را رها کنید؟';

  @override
  String get unsavedChangesLost => 'تغییرات ذخیره نشده از بین خواهند رفت.';

  @override
  String get noteSaved => 'یادداشت ذخیره شد';

  @override
  String get trashCleared => 'سطل زباله پاک شد';

  @override
  String get backupSaved => 'نسخه پشتیبان ذخیره شد';

  @override
  String get backupImported => 'نسخه پشتیبان وارد شد';

  @override
  String importedFiles(Object count) {
    return '$count فایل وارد شد';
  }

  @override
  String get noCompletedTasks => 'وظیفه تکمیل شده‌ای نیست';

  @override
  String get productivity => 'بهره‌وری';

  @override
  String get content => 'محتوا';

  @override
  String get tools => 'ابزارها';

  @override
  String get aboutApp => 'فضای کاری خصوصی دیجیتال شما';

  @override
  String get aboutDescription =>
      'نیازی به حساب کاربری نیست. یادداشت‌ها و فایل‌های شما به صورت محلی ذخیره می‌شوند.';

  @override
  String get noNotes => 'یادداشتی نیست';

  @override
  String get noArchivedNotes => 'یادداشت بایگانی شده‌ای نیست';

  @override
  String get archiveNotesDesc =>
      'یادداشت‌ها را بایگانی کنید تا از لیست اصلی مخفی شوند';

  @override
  String get starNote =>
      'یک یادداشت را ستاره‌دار کنید تا به علاقه‌مندی‌ها اضافه شود';

  @override
  String get noFavorites => 'علاقه‌مندی‌ای نیست';

  @override
  String get newNote => 'یادداشت جدید';

  @override
  String get titleHint => 'عنوان';

  @override
  String get contentHint => 'شروع به نوشتن...';

  @override
  String get noFiles => 'فایلی نیست';

  @override
  String get importFiles => 'فایل‌ها را به فضای کاری وارد کنید';

  @override
  String get filesStoredLocal => 'فایل‌ها به صورت محلی ذخیره می‌شوند';

  @override
  String get pickFiles => 'انتخاب فایل';

  @override
  String get allNotes => 'همه یادداشت‌ها';

  @override
  String get inFolder => 'در پوشه';

  @override
  String get media => 'رسانه';

  @override
  String get filesAndMedia => 'فایل‌ها و رسانه';

  @override
  String get filesAndMediaDescription =>
      'همه فایل‌ها، تصاویر، ویدیوها و صداهای شما';

  @override
  String get images => 'تصاویر';

  @override
  String get videos => 'ویدیوها';

  @override
  String get playlists => 'لیست پخش';

  @override
  String get voiceRecorder => 'ضبط صدا';

  @override
  String get nowPlaying => 'در حال پخش';

  @override
  String get noMedia => 'هنوز فایل رسانه‌ای نیست';

  @override
  String get importMedia => 'رسانه را از بخش فایل‌ها وارد کنید';

  @override
  String get recentlyPlayed => 'اخیراً پخش شده';

  @override
  String get noteLabel => 'یادداشت';

  @override
  String get fileLabel => 'فایل';

  @override
  String get noImagesYet => 'هنوز تصویری نیست';

  @override
  String get importImagesHint => 'تصاویر را از بخش فایل‌ها وارد کنید';

  @override
  String get noVideosYet => 'هنوز ویدیویی نیست';

  @override
  String get importVideosHint => 'ویدیوها را از بخش فایل‌ها وارد کنید';

  @override
  String get noAudioFilesYet => 'هنوز فایل صوتی نیست';

  @override
  String get importAudioHint => 'صدا را از بخش فایل‌ها وارد کنید';

  @override
  String get noPlaylistsYet => 'هنوز لیست پخشی نیست';

  @override
  String get createPlaylistHint => 'یک لیست پخش برای سازماندهی صدا ایجاد کنید';

  @override
  String get video => 'ویدیو';

  @override
  String get cannotPlayVideo => 'پخش این ویدیو ممکن نیست';

  @override
  String failedToPlayVideo(Object error) {
    return 'خطا در پخش ویدیو: $error';
  }

  @override
  String get audioNotFound => 'صدا یافت نشد';

  @override
  String failedToPlayAudio(Object error) {
    return 'خطا در پخش صدا: $error';
  }

  @override
  String get incorrectPin => 'پین نادرست';

  @override
  String get setVaultPin => 'گاوصندوق خود را تنظیم کنید';

  @override
  String get createPinDescription =>
      'یک پین برای محافظت از فایل‌های خصوصی خود ایجاد کنید';

  @override
  String get createPin => 'ایجاد پین';

  @override
  String get useBiometrics => 'استفاده از اثر انگشت';

  @override
  String get useBiometricsInstead => 'استفاده از اثر انگشت';

  @override
  String get enterNewPin => 'پین جدید را وارد کنید';

  @override
  String get confirmPin => 'تأیید پین';

  @override
  String get enterPin => 'پین خود را وارد کنید';

  @override
  String get pinsDoNotMatch => 'پین‌ها مطابقت ندارند';

  @override
  String get fileBrowser => 'مرورگر فایل';

  @override
  String get importFilesDescription => 'فایل‌ها را به فضای کاری خود وارد کنید';

  @override
  String get error => 'خطا';

  @override
  String get microphonePermissionRequired => 'مجوز میکروفون لازم است';

  @override
  String get recordingSaved => 'ضبط ذخیره شد';

  @override
  String get readyToRecord => 'آماده ضبط';

  @override
  String get recording => 'در حال ضبط...';

  @override
  String get paused => 'متوقف شده';

  @override
  String get allTasks => 'همه وظایف';

  @override
  String get priority => 'اولویت';

  @override
  String get searchAcrossContent => 'جستجو در همه محتوا';

  @override
  String notesCount(Object count) {
    return 'یادداشت‌ها ($count)';
  }

  @override
  String tasksCount(Object count) {
    return 'وظایف ($count)';
  }

  @override
  String filesCount(Object count) {
    return 'فایل‌ها ($count)';
  }

  @override
  String get allStatsCalculatedLocally =>
      'همه آمار به صورت محلی محاسبه می‌شوند.';

  @override
  String get exportSection => 'خروجی';

  @override
  String get exportDescription => 'ایجاد نسخه پشتیبان از همه داده‌ها';

  @override
  String get importSection => 'وارد کردن';

  @override
  String get importDescription => 'بازیابی از فایل پشتیبان';

  @override
  String get privacySection => 'حریم خصوصی';

  @override
  String exportFailed(Object error) {
    return 'خطا در خروجی: $error';
  }

  @override
  String shareFailed(Object error) {
    return 'خطا در اشتراک‌گذاری: $error';
  }

  @override
  String importFailed(Object error) {
    return 'خطا در وارد کردن: $error';
  }

  @override
  String get clearTrashConfirm => 'سطل زباله پاک شود؟';

  @override
  String get clearTrashDescription2 =>
      'این کار همه موارد سطل زباله را به صورت دائمی حذف می‌کند.';

  @override
  String get cacheCleared => 'حافظه پنهان پاک شد';

  @override
  String get tapToAddNoteToVault =>
      'روی + بزنید تا یادداشتی به گاوصندوق اضافه کنید';

  @override
  String get tapToAddImagesToVault =>
      'روی + بزنید تا تصاویری به گاوصندوق اضافه کنید';

  @override
  String get tapToAddVideosToVault =>
      'روی + بزنید تا ویدیوهایی به گاوصندوق اضافه کنید';

  @override
  String get tapToAddFilesToVault =>
      'روی + بزنید تا فایل‌هایی به گاوصندوق اضافه کنید';

  @override
  String get settingsTitle => 'تنظیمات';

  @override
  String get notifications => 'اعلانات';

  @override
  String get notificationsDescription => 'فعال‌سازی اعلان‌ها';

  @override
  String get notificationsDisabled => 'اعلان‌ها خاموش هستند';

  @override
  String get notificationSound => 'صدای اعلان';

  @override
  String get defaultSound => 'پیش‌فرض';

  @override
  String get vibration => 'لرزش';

  @override
  String get vibrationDescription => 'لرزش هنگام دریافت اعلان';

  @override
  String get security => 'امنیت';

  @override
  String get appLock => 'قفل برنامه';

  @override
  String get appLockDescription => 'قفل برنامه با پین یا اثر انگشت';

  @override
  String get encryptBackups => 'رمزگذاری نسخه‌های پشتیبان';

  @override
  String get encryptBackupsDescription => 'رمزگذاری فایل‌های پشتیبان';

  @override
  String get clearCache => 'پاک کردن حافظه پنهان';

  @override
  String get clearCacheDescription => 'پاک کردن فایل‌های موقت';

  @override
  String get rateApp => 'امتیازدهی به برنامه';

  @override
  String get termsOfService => 'شرایط استفاده';

  @override
  String get noNotesInFolder => 'در این پوشه یادداشتی نیست';

  @override
  String get noArchivedNotesHint => 'یادداشت بایگانی شده‌ای نیست';

  @override
  String get allArchived => 'همه (بایگانی شده)';

  @override
  String get startEndDate => 'شروع - پایان';

  @override
  String get dueTime => 'ساعت سررسید';

  @override
  String get skip => 'رد شدن';

  @override
  String get next => 'بعدی';

  @override
  String get getStarted => 'شروع کنید';

  @override
  String get welcomeTitle => 'به کارگاه خوش آمدید';

  @override
  String get welcomeMessage =>
      'فضای کاری خصوصی شما. یادداشت بسازید، وظایف را مدیریت کنید و فایل‌ها را ذخیره کنید — همه بدون اتصال به اینترنت و بدون نیاز به حساب کاربری.';

  @override
  String get chooseLanguageTitle => 'زبان خود را انتخاب کنید';

  @override
  String get chooseLanguageMessage =>
      'زبانی را که ترجیح می‌دهید برنامه به آن زبان باشد انتخاب کنید. می‌توانید آن را هر زمان در تنظیمات تغییر دهید.';

  @override
  String get chooseThemeTitle => 'تم خود را انتخاب کنید';

  @override
  String get chooseThemeMessage =>
      'ظاهر برنامه را انتخاب کنید. می‌توانید آن را هر زمان در تنظیمات تغییر دهید.';

  @override
  String get lightTheme => 'روشن';

  @override
  String get darkTheme => 'تاریک';

  @override
  String get onboardingDone =>
      'راه‌اندازی کامل شد. از فضای کاری خصوصی خود لذت ببرید!';

  @override
  String get rateAppDescription => 'ما را در فروشگاه امتیاز دهید';

  @override
  String get backupAndRestore => 'پشتیبان‌گیری و بازیابی';

  @override
  String get backupAndRestoreDescription =>
      'داده‌های خود را خروجی یا وارد کنید';

  @override
  String get appLockSetup =>
      'قفل برنامه را برای محافظت از فضای کاری خود تنظیم کنید';

  @override
  String get cacheClearingDescription =>
      'این فایل‌های موقت را پاک می‌کند تا فضا آزاد شود';

  @override
  String get noTrashedItems => 'آیتم حذف شده‌ای برای پاک کردن وجود ندارد';

  @override
  String trashedItemsCount(Object count) {
    return '$count آیتم حذف شده یافت شد';
  }

  @override
  String get restoreBackup => 'بازیابی پشتیبان';

  @override
  String get backupHistory => 'تاریخچه پشتیبان';

  @override
  String get noBackupsYet => 'هنوز پشتیبانی وجود ندارد';

  @override
  String lastBackup(Object date) {
    return 'آخرین پشتیبان: $date';
  }

  @override
  String get calendarDescription => 'برنامه زمانی خود را مدیریت کنید';

  @override
  String get timetableDescription => 'کلاس‌های خود را سازماندهی کنید';

  @override
  String get remindersDescription => 'هیچ وظیفه‌ای را فراموش نکنید';

  @override
  String get favoritesDescription => 'دسترسی سریع به موارد مهم';

  @override
  String get privateVaultDescription => 'فایل‌های حساس خود را ایمن کنید';

  @override
  String get mediaDescription => 'تصاویر، ویدیوها و صدا';

  @override
  String get statisticsDescription => 'آمار استفاده خود را مشاهده کنید';

  @override
  String get backupLocation => 'محل پشتیبان';

  @override
  String get backupPathDescription =>
      'فایل‌های پشتیبان شما در این مسیر ذخیره می‌شوند:';

  @override
  String get changePath => 'تغییر مسیر';

  @override
  String get defaultPath => 'پیش‌فرض';

  @override
  String get noBackupsInLocation => 'فایل پشتیبانی در این مسیر یافت نشد';

  @override
  String get backupFiles => 'فایل‌های پشتیبان';

  @override
  String get deleteBackup => 'حذف پشتیبان';

  @override
  String get confirmDeleteBackup =>
      'آیا مطمئن هستید که می‌خواهید این پشتیبان را حذف کنید؟ این غیرقابل بازگشت است.';

  @override
  String get pathUpdated => 'مسیر پشتیبان به‌روزرسانی شد';

  @override
  String get pathUpdateFailed => 'خطا در به‌روزرسانی مسیر';

  @override
  String get backupDeleted => 'پشتیبان حذف شد';

  @override
  String get trash => 'سطل زباله';

  @override
  String get trashDescription => 'مشاهده و بازیابی موارد حذف شده';

  @override
  String get trashEmpty => 'سطل زباله خالی است';

  @override
  String get trashHint => 'مواردی که حذف می‌کنید اینجا نمایش داده می‌شوند';

  @override
  String get restore => 'بازیابی';

  @override
  String get deletePermanently => 'حذف دائمی';

  @override
  String permanentDeleteConfirm(Object name) {
    return 'آیا مطمئن هستید که می‌خواهید \"$name\" را به صورت دائمی حذف کنید؟ این غیرقابل بازگشت است.';
  }

  @override
  String get noteRestored => 'یادداشت بازیابی شد';

  @override
  String get taskRestored => 'وظیفه بازیابی شد';

  @override
  String get fileRestored => 'فایل بازیابی شد';

  @override
  String get exchangeCalendar => 'تبدیل تقویم';

  @override
  String get exchangeCalendarDescription =>
      'بین تقویم میلادی، هجری و شمسی جابجا شوید';

  @override
  String get gregorian => 'میلادی';

  @override
  String get hijri => 'هجری (اسلامی)';

  @override
  String get shamsi => 'شمسی (خورشیدی)';

  @override
  String get calendarType => 'نوع تقویم';

  @override
  String get shamsiMonth1 => 'حمل';

  @override
  String get shamsiMonth2 => 'ثور';

  @override
  String get shamsiMonth3 => 'جوزا';

  @override
  String get shamsiMonth4 => 'سرطان';

  @override
  String get shamsiMonth5 => 'اسد';

  @override
  String get shamsiMonth6 => 'سنبله';

  @override
  String get shamsiMonth7 => 'میزان';

  @override
  String get shamsiMonth8 => 'عقرب';

  @override
  String get shamsiMonth9 => 'قوس';

  @override
  String get shamsiMonth10 => 'جدی';

  @override
  String get shamsiMonth11 => 'دلو';

  @override
  String get shamsiMonth12 => 'حوت';
}
