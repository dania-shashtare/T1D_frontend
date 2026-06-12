class AppStrings {
  static const Map<String, Map<String, String>> _values = {
    'en': {
      'settings': 'Settings',
      'settingsSubtitle': 'Security and app preferences',
      'patientSettings': 'Patient Settings',
      'patientSettingsDesc':
          'Manage password, language, theme, and app information.',

      'privacySecurity': 'Privacy & Security',
      'changePassword': 'Change Password',
      'changePasswordSubtitle': 'Update your account password',
      'deleteAccount': 'Delete Account',
      'deleteAccountSubtitle': 'Permanently remove your account',

      'appPreferences': 'App Preferences',
      'language': 'Language',
      'languageSubtitle': 'Change app language',
      'darkMode': 'Dark Mode',
      'darkModeSubtitle': 'Use a darker app appearance',
      'aboutApp': 'About App',
      'aboutAppSubtitle': 'App version and information',

      'chooseLanguage': 'Choose Language',
      'english': 'English',
      'arabic': 'العربية',

      'changePasswordTitle': 'Change Password',
      'changePasswordDesc': 'Enter your current password and choose a new one.',
      'currentPassword': 'Current Password',
      'newPassword': 'New Password',
      'confirmNewPassword': 'Confirm New Password',
      'savePassword': 'Save Password',

      'fillAllPasswordFields': 'Please fill all password fields.',
      'passwordMinLength': 'New password must be at least 6 characters.',
      'passwordNotMatch': 'New password and confirm password do not match.',
      'passwordChanged': 'Password changed successfully.',

      'deleteAccountQuestion':
          'Are you sure you want to delete your account? This action cannot be undone.',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'close': 'Close',

      'aboutAppText':
          'Diabetes Care App helps patients track glucose readings, meals, water, activity, reports, appointments, and communication with doctors and nutritionists.',

      'darkModeEnabled': 'Dark mode enabled',
      'lightModeEnabled': 'Light mode enabled',
    },

    'ar': {
      'settings': 'الإعدادات',
      'settingsSubtitle': 'الأمان وتفضيلات التطبيق',
      'patientSettings': 'إعدادات المريض',
      'patientSettingsDesc':
          'إدارة كلمة السر، اللغة، المظهر، ومعلومات التطبيق.',

      'privacySecurity': 'الخصوصية والأمان',
      'changePassword': 'تغيير كلمة السر',
      'changePasswordSubtitle': 'تحديث كلمة سر الحساب',
      'deleteAccount': 'حذف الحساب',
      'deleteAccountSubtitle': 'حذف الحساب بشكل نهائي',

      'appPreferences': 'تفضيلات التطبيق',
      'language': 'اللغة',
      'languageSubtitle': 'تغيير لغة التطبيق',
      'darkMode': 'الوضع الداكن',
      'darkModeSubtitle': 'استخدام مظهر داكن للتطبيق',
      'aboutApp': 'عن التطبيق',
      'aboutAppSubtitle': 'إصدار التطبيق والمعلومات',

      'chooseLanguage': 'اختاري اللغة',
      'english': 'English',
      'arabic': 'العربية',

      'changePasswordTitle': 'تغيير كلمة السر',
      'changePasswordDesc': 'أدخلي كلمة السر الحالية واختاري كلمة سر جديدة.',
      'currentPassword': 'كلمة السر الحالية',
      'newPassword': 'كلمة السر الجديدة',
      'confirmNewPassword': 'تأكيد كلمة السر الجديدة',
      'savePassword': 'حفظ كلمة السر',

      'fillAllPasswordFields': 'يرجى تعبئة جميع حقول كلمة السر.',
      'passwordMinLength': 'كلمة السر الجديدة يجب أن تكون 6 أحرف على الأقل.',
      'passwordNotMatch': 'كلمة السر الجديدة وتأكيدها غير متطابقين.',
      'passwordChanged': 'تم تغيير كلمة السر بنجاح.',

      'deleteAccountQuestion':
          'هل أنتِ متأكدة من حذف الحساب؟ لا يمكن التراجع عن هذه العملية.',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'close': 'إغلاق',

      'aboutAppText':
          'يساعد تطبيق رعاية السكري المرضى على متابعة قراءات السكر، الوجبات، الماء، النشاط، التقارير، المواعيد، والتواصل مع الأطباء وأخصائيي التغذية.',

      'darkModeEnabled': 'تم تفعيل الوضع الداكن',
      'lightModeEnabled': 'تم تفعيل الوضع الفاتح',
    },
  };

  static String text(String key, String language) {
    return _values[language]?[key] ?? _values['en']?[key] ?? key;
  }
}
