import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/settings_api.dart';
import 'providers/app_settings_provider.dart';

class PatientSettingsScreen extends StatefulWidget {
  final String userId;

  const PatientSettingsScreen({super.key, required this.userId});

  @override
  State<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends State<PatientSettingsScreen> {
  static const Color _softBlue = Color(0xffEEF7FF);
  static const Color _softBlue2 = Color(0xffDCEEFF);
  static const Color _mainBlue = Color(0xff185FA5);
  static const Color _textBlue = Color(0xff0C447C);

  static const Color _darkBg = Color(0xff071A2F);
  static const Color _darkCard = Color(0xff102A46);
  static const Color _darkTile = Color(0xff183A5C);
  static const Color _darkText = Colors.white;
  static const Color _darkSubText = Color(0xffAFC7DD);

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'settings': 'Settings',
      'settingsSubtitle': 'Security and app preferences',
      'appSettings': 'App Settings',
      'appSettingsDesc':
          'Manage your password, language, theme, and app information.',

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
          'T1D is a smart health application designed to support people with diabetes and help them manage their daily routine in an organized and simple way.\n\n'
          'The app allows patients to track glucose readings, meals, water intake, activity, reports, appointments, and health-related reminders. It also helps improve communication between patients, family members, doctors, and nutritionists, making follow-up easier, clearer, and safer.\n\n'
          'T1D is designed for monitoring and support purposes only. It does not replace medical advice, diagnosis, or treatment from qualified healthcare professionals.\n\n'
          'For support or inquiries, please contact us at:\n'
          'rdrdeng@gmail.com',

      'darkModeEnabled': 'Dark mode enabled',
      'lightModeEnabled': 'Light mode enabled',
      'deleteComingSoon': 'Delete account will be added soon',
    },

    'ar': {
      'settings': 'الإعدادات',
      'settingsSubtitle': 'الأمان وتفضيلات التطبيق',
      'appSettings': 'إعدادات التطبيق',
      'appSettingsDesc': 'إدارة كلمة السر، اللغة، المظهر، ومعلومات التطبيق.',

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
          'تطبيق T1D هو تطبيق صحي ذكي صُمم لدعم مرضى السكري ومساعدتهم على تنظيم روتينهم اليومي بطريقة سهلة ومرتبة.\n\n'
          'يوفر التطبيق إمكانية متابعة قراءات السكر، الوجبات، شرب الماء، النشاط، التقارير، المواعيد، والتنبيهات الصحية. كما يساعد على تحسين التواصل بين المريض، الأهل، الطبيب، وأخصائي التغذية، مما يجعل المتابعة أوضح وأسهل وأكثر أمانًا.\n\n'
          'تطبيق T1D مخصص للمساعدة والمتابعة فقط، ولا يُعتبر بديلًا عن الاستشارة الطبية أو التشخيص أو العلاج من قبل الأطباء والمختصين.\n\n'
          'للدعم أو الاستفسار، يمكنكم التواصل معنا عبر البريد الإلكتروني:\n'
          'rdrdeng@gmail.com',

      'darkModeEnabled': 'تم تفعيل الوضع الداكن',
      'lightModeEnabled': 'تم تفعيل الوضع الفاتح',
      'deleteComingSoon': 'سيتم إضافة حذف الحساب قريبًا',
    },
  };

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String t(String key) {
    final lang = context.watch<AppSettingsProvider>().language;
    return _strings[lang]?[key] ?? _strings['en']?[key] ?? key;
  }

  String get _selectedLanguageText {
    final lang = context.watch<AppSettingsProvider>().language;
    return lang == 'ar' ? 'العربية' : 'English';
  }

  TextDirection get _pageDirection {
    final lang = context.watch<AppSettingsProvider>().language;
    return lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;
  }

  bool _isDark(BuildContext context) {
    return context.watch<AppSettingsProvider>().darkMode;
  }

  Color _pageBg(BuildContext context) {
    return _isDark(context) ? _darkBg : _softBlue;
  }

  Color _cardColor(BuildContext context) {
    return _isDark(context) ? _darkCard : Colors.white;
  }

  Color _iconBg(BuildContext context) {
    return _isDark(context) ? _darkTile : _softBlue2;
  }

  Color _titleColor(BuildContext context) {
    return _isDark(context) ? _darkText : _textBlue;
  }

  Color _subtitleColor(BuildContext context) {
    return _isDark(context) ? _darkSubText : const Color(0xff7A9AB5);
  }

  Color _dividerColor(BuildContext context) {
    return _isDark(context)
        ? Colors.white.withOpacity(0.08)
        : Colors.grey.withOpacity(0.18);
  }

  Color _sheetBg(BuildContext context) {
    return _isDark(context) ? const Color(0xff0D223A) : const Color(0xffF9FCFF);
  }

  Color _fieldFill(BuildContext context) {
    return _isDark(context) ? const Color(0xff102A46) : Colors.white;
  }

  void _showComingSoon(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changeTheme(bool value) async {
    await context.read<AppSettingsProvider>().setDarkMode(value);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? t('darkModeEnabled') : t('lightModeEnabled')),
      ),
    );
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final currentLanguage = context.watch<AppSettingsProvider>().language;

        return Directionality(
          textDirection: _pageDirection,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              decoration: BoxDecoration(
                color: _sheetBg(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 16),
                  Text(
                    t('chooseLanguage'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _titleColor(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _optionTile(
                    title: 'English',
                    selected: currentLanguage == 'en',
                    onTap: () async {
                      await context.read<AppSettingsProvider>().setLanguage(
                        'en',
                      );

                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  _optionTile(
                    title: 'العربية',
                    selected: currentLanguage == 'ar',
                    onTap: () async {
                      await context.read<AppSettingsProvider>().setLanguage(
                        'ar',
                      );

                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: _pageDirection,
          child: AlertDialog(
            backgroundColor: _cardColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              t('aboutApp'),
              style: TextStyle(color: _titleColor(context)),
            ),
            content: SingleChildScrollView(
              child: Text(
                t('aboutAppText'),
                style: TextStyle(
                  height: 1.5,
                  color: _subtitleColor(context),
                  fontSize: 14,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('close')),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangePasswordSheet() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Directionality(
              textDirection: _pageDirection,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    decoration: BoxDecoration(
                      color: _sheetBg(context),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _sheetHandle(),
                          const SizedBox(height: 16),
                          Text(
                            t('changePasswordTitle'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _titleColor(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t('changePasswordDesc'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: _subtitleColor(context),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _passwordField(
                            controller: _currentPasswordController,
                            label: t('currentPassword'),
                            hidden: _hideCurrentPassword,
                            onToggle: () {
                              setSheetState(() {
                                _hideCurrentPassword = !_hideCurrentPassword;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _passwordField(
                            controller: _newPasswordController,
                            label: t('newPassword'),
                            hidden: _hideNewPassword,
                            onToggle: () {
                              setSheetState(() {
                                _hideNewPassword = !_hideNewPassword;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _passwordField(
                            controller: _confirmPasswordController,
                            label: t('confirmNewPassword'),
                            hidden: _hideConfirmPassword,
                            onToggle: () {
                              setSheetState(() {
                                _hideConfirmPassword = !_hideConfirmPassword;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _mainBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                t('savePassword'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('fillAllPasswordFields'))));
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('passwordMinLength'))));
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('passwordNotMatch'))));
      return;
    }

    try {
      await SettingsApi.changePassword(
        userId: widget.userId,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('passwordChanged'))));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: _pageDirection,
          child: AlertDialog(
            backgroundColor: _cardColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              t('deleteAccount'),
              style: TextStyle(color: _titleColor(context)),
            ),
            content: Text(
              t('deleteAccountQuestion'),
              style: TextStyle(height: 1.5, color: _subtitleColor(context)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showComingSoon(t('deleteComingSoon'));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(t('delete')),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = context.watch<AppSettingsProvider>().darkMode;

    return Directionality(
      textDirection: _pageDirection,
      child: Scaffold(
        backgroundColor: _pageBg(context),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWideScreen = constraints.maxWidth >= 900;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isWideScreen ? 32 : 16,
                  isWideScreen ? 24 : 14,
                  isWideScreen ? 32 : 16,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWideScreen ? 980 : 620,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 18),
                        _buildHeroCard(),
                        const SizedBox(height: 22),

                        if (isWideScreen)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _sectionBlock(
                                  title: t('privacySecurity'),
                                  child: _settingsCard(
                                    children: [
                                      _settingsTile(
                                        icon: Icons.lock_outline_rounded,
                                        title: t('changePassword'),
                                        subtitle: t('changePasswordSubtitle'),
                                        onTap: _showChangePasswordSheet,
                                      ),
                                      _divider(),
                                      _settingsTile(
                                        icon: Icons.delete_outline_rounded,
                                        title: t('deleteAccount'),
                                        subtitle: t('deleteAccountSubtitle'),
                                        iconColor: Colors.red,
                                        onTap: _deleteAccount,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 22),
                              Expanded(
                                child: _sectionBlock(
                                  title: t('appPreferences'),
                                  child: _settingsCard(
                                    children: [
                                      _settingsTile(
                                        icon: Icons.language_rounded,
                                        title: t('language'),
                                        subtitle: t('languageSubtitle'),
                                        trailingText: _selectedLanguageText,
                                        onTap: _showLanguageSheet,
                                      ),
                                      _divider(),
                                      _switchTile(
                                        icon: Icons.dark_mode_outlined,
                                        title: t('darkMode'),
                                        subtitle: t('darkModeSubtitle'),
                                        value: darkMode,
                                        onChanged: _changeTheme,
                                      ),
                                      _divider(),
                                      _settingsTile(
                                        icon: Icons.info_outline_rounded,
                                        title: t('aboutApp'),
                                        subtitle: t('aboutAppSubtitle'),
                                        trailingText: 'v1.0.0',
                                        onTap: _showAboutDialog,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _sectionBlock(
                            title: t('privacySecurity'),
                            child: _settingsCard(
                              children: [
                                _settingsTile(
                                  icon: Icons.lock_outline_rounded,
                                  title: t('changePassword'),
                                  subtitle: t('changePasswordSubtitle'),
                                  onTap: _showChangePasswordSheet,
                                ),
                                _divider(),
                                _settingsTile(
                                  icon: Icons.delete_outline_rounded,
                                  title: t('deleteAccount'),
                                  subtitle: t('deleteAccountSubtitle'),
                                  iconColor: Colors.red,
                                  onTap: _deleteAccount,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _sectionBlock(
                            title: t('appPreferences'),
                            child: _settingsCard(
                              children: [
                                _settingsTile(
                                  icon: Icons.language_rounded,
                                  title: t('language'),
                                  subtitle: t('languageSubtitle'),
                                  trailingText: _selectedLanguageText,
                                  onTap: _showLanguageSheet,
                                ),
                                _divider(),
                                _switchTile(
                                  icon: Icons.dark_mode_outlined,
                                  title: t('darkMode'),
                                  subtitle: t('darkModeSubtitle'),
                                  value: darkMode,
                                  onChanged: _changeTheme,
                                ),
                                _divider(),
                                _settingsTile(
                                  icon: Icons.info_outline_rounded,
                                  title: t('aboutApp'),
                                  subtitle: t('aboutAppSubtitle'),
                                  trailingText: 'v1.0.0',
                                  onTap: _showAboutDialog,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _sectionBlock({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_sectionTitle(title), child],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: _circleIcon(Icons.arrow_back_ios_new_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('settings'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _titleColor(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t('settingsSubtitle'),
                style: TextStyle(
                  fontSize: 13,
                  color: _isDark(context)
                      ? _darkSubText
                      : const Color(0xff378ADD),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 430;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isSmall ? 16 : 22),
          decoration: BoxDecoration(
            color: _mainBlue,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _mainBlue.withOpacity(_isDark(context) ? 0.10 : 0.18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: isSmall
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heroIcon(),
                    const SizedBox(height: 14),
                    Text(
                      t('appSettings'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t('appSettingsDesc'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _heroIcon(),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('appSettings'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t('appSettingsDesc'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _heroIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.settings_rounded, color: Colors.white, size: 34),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: _titleColor(context),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isDark(context)
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailingText,
    Color iconColor = _mainBlue,
  }) {
    final bool isDelete = iconColor == Colors.red;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: const Color(0xffBFE2FF).withOpacity(0.20),
        highlightColor: const Color(0xffD9EEFF).withOpacity(0.18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isDelete
                      ? Colors.red.withOpacity(_isDark(context) ? 0.16 : 0.08)
                      : _iconBg(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDelete ? Colors.red : _titleColor(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: _subtitleColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingText != null) ...[
                const SizedBox(width: 8),
                Text(
                  trailingText,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isDark(context)
                        ? const Color(0xff8CC7F5)
                        : const Color(0xff378ADD),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: _isDark(context)
                    ? const Color(0xff8CC7F5)
                    : const Color(0xff9FC9F5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _iconBg(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _mainBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: _titleColor(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: _subtitleColor(context),
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, activeColor: _mainBlue, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool hidden,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: hidden,
      style: TextStyle(color: _titleColor(context)),
      textDirection: _pageDirection,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _subtitleColor(context)),
        filled: true,
        fillColor: _fieldFill(context),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xff378ADD),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _isDark(context)
                ? Colors.white.withOpacity(0.12)
                : const Color(0xffB5D4F4),
            width: 0.7,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _isDark(context)
                ? Colors.white.withOpacity(0.12)
                : const Color(0xffB5D4F4),
            width: 0.7,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xff378ADD), width: 1.2),
        ),
      ),
    );
  }

  Widget _optionTile({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: selected ? _iconBg(context) : _cardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? _mainBlue
                  : _isDark(context)
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xffD8EBFF),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: _titleColor(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: _mainBlue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _cardColor(context),
        shape: BoxShape.circle,
        border: Border.all(
          color: _isDark(context)
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: _isDark(context)
            ? const Color(0xff8CC7F5)
            : const Color(0xff378ADD),
      ),
    );
  }

  Widget _sheetHandle() {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: _isDark(context)
            ? Colors.white.withOpacity(0.18)
            : const Color(0xffC8DDEC),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 0.6,
      indent: 72,
      endIndent: 16,
      color: _dividerColor(context),
    );
  }
}
