import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_model.dart';
import '../providers/app_settings_provider.dart';
import '../services/profile_api.dart';
import 'auth_screen.dart';
import 'notification_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  String? _errorMessage;
  ProfileModel? profile;

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  static const Color _lightBg = Color(0xFFF3F7FB);
  static const Color _lightCard = Colors.white;
  static const Color _lightRow = Color(0xFFF7FBFF);
  static const Color _lightIconBg = Color(0xFFE4F3FF);
  static const Color _lightTitle = Color(0xFF123B63);
  static const Color _lightSubTitle = Color(0xFF6B7280);
  static const Color _mainBlue = Color(0xFF1A73B8);

  static const Color _darkBg = Color(0xff071A2F);
  static const Color _darkCard = Color(0xff102A46);
  static const Color _darkRow = Color(0xff183A5C);
  static const Color _darkIconBg = Color(0xff173A5E);
  static const Color _darkTitle = Colors.white;
  static const Color _darkSubTitle = Color(0xffAFC7DD);

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'profile': 'Profile',
      'save': 'Save',
      'edit': 'Edit',
      'patientProfile': 'Patient Profile',
      'type1Patient': 'Type 1 Diabetes Patient',

      'personalInfo': 'Personal Information',
      'age': 'Age',
      'years': 'years',
      'weight': 'Weight',
      'height': 'Height',
      'bmi': 'BMI',

      'diabetesInfo': 'Diabetes Information',
      'carbRatio': 'Carb Ratio',
      'correctionFactor': 'Correction Factor',
      'lantusDose': 'Lantus Dose',
      'units': 'units',
      'lantusTime': 'Lantus Time',

      'foodAllergy': 'Food Allergy',
      'allergy': 'Allergy',
      'noFoodAllergy': 'No food allergy',

      'doctor': 'Doctor',
      'doctorName': 'Doctor Name',
      'specialty': 'Specialty',

      'notSet': 'Not set',
      'logOut': 'Log Out',

      'noLoggedUser': 'No logged-in user found',
      'failedLoad': 'Failed to load profile data',
      'validWeightHeight': 'Please enter valid weight and height',
      'profileUpdated': 'Profile updated successfully',
      'failedUpdate': 'Failed to update profile',
    },
    'ar': {
      'profile': 'الملف الشخصي',
      'save': 'حفظ',
      'edit': 'تعديل',
      'patientProfile': 'ملف المريض',
      'type1Patient': 'مريض سكري النوع الأول',

      'personalInfo': 'المعلومات الشخصية',
      'age': 'العمر',
      'years': 'سنة',
      'weight': 'الوزن',
      'height': 'الطول',
      'bmi': 'مؤشر كتلة الجسم',

      'diabetesInfo': 'معلومات السكري',
      'carbRatio': 'نسبة الكربوهيدرات',
      'correctionFactor': 'معامل التصحيح',
      'lantusDose': 'جرعة اللانتوس',
      'units': 'وحدات',
      'lantusTime': 'وقت اللانتوس',

      'foodAllergy': 'حساسية الطعام',
      'allergy': 'الحساسية',
      'noFoodAllergy': 'لا توجد حساسية طعام',

      'doctor': 'الطبيب',
      'doctorName': 'اسم الطبيب',
      'specialty': 'التخصص',

      'notSet': 'غير محدد',
      'logOut': 'تسجيل الخروج',

      'noLoggedUser': 'لا يوجد مستخدم مسجل الدخول',
      'failedLoad': 'فشل تحميل بيانات الملف الشخصي',
      'validWeightHeight': 'يرجى إدخال وزن وطول صحيحين',
      'profileUpdated': 'تم تحديث الملف الشخصي بنجاح',
      'failedUpdate': 'فشل تحديث الملف الشخصي',
    },
  };

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBg => _isDark ? _darkBg : _lightBg;
  Color get _cardColor => _isDark ? _darkCard : _lightCard;
  Color get _rowColor => _isDark ? _darkRow : _lightRow;
  Color get _iconBgColor => _isDark ? _darkIconBg : _lightIconBg;
  Color get _titleColor => _isDark ? _darkTitle : _lightTitle;
  Color get _subTitleColor => _isDark ? _darkSubTitle : _lightSubTitle;
  Color get _borderColor =>
      _isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE1EEF8);
  Color get _shadowColor =>
      _isDark ? Colors.black.withOpacity(0.18) : Colors.black.withOpacity(0.07);

  String get _language => context.read<AppSettingsProvider>().language;

  bool get _isArabic => _language == 'ar';

  TextDirection get _pageDirection {
    return _isArabic ? TextDirection.rtl : TextDirection.ltr;
  }

  String t(String key) {
    final lang = context.read<AppSettingsProvider>().language;
    return _strings[lang]?[key] ?? _strings['en']?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = t('noLoggedUser');
        });
        return;
      }

      final data = await ProfileApi.getProfile(userId);

      if (!mounted) return;
      setState(() {
        profile = data;
        _weightController.text = data.weight?.toString() ?? '';
        _heightController.text = data.height?.toString() ?? '';
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = t('failedLoad');
      });
    }
  }

  Future<void> _saveProfile() async {
    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());

    if (weight == null || height == null || weight <= 0 || height <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('validWeightHeight'))));
      return;
    }

    try {
      setState(() => _isSaving = true);

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        throw Exception(t('noLoggedUser'));
      }

      await ProfileApi.updateProfile(
        userId: userId,
        weight: weight,
        height: height,
      );

      await _loadProfile();

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('profileUpdated'))));
    } catch (e) {
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${t('failedUpdate')}: $e')));
    }
  }

  double? _calculateBmi() {
    final weight = _isEditing
        ? double.tryParse(_weightController.text.trim())
        : profile?.weight;

    final height = _isEditing
        ? double.tryParse(_heightController.text.trim())
        : profile?.height;

    if (weight == null || height == null) return null;
    final heightM = height / 100;
    if (heightM <= 0) return null;

    return weight / (heightM * heightM);
  }

  String _value(dynamic value, {String suffix = ''}) {
    if (value == null) return t('notSet');
    final text = value.toString();
    if (text.trim().isEmpty) return t('notSet');
    return suffix.isEmpty ? text : '$text $suffix';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppSettingsProvider>().language;

    return Directionality(
      textDirection: _pageDirection,
      child: Scaffold(
        backgroundColor: _pageBg,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              )
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildUserCard(),
                          const SizedBox(height: 16),
                          _buildPersonalInfoCard(),
                          const SizedBox(height: 16),
                          _buildDiabetesCard(),
                          const SizedBox(height: 16),
                          _buildAllergyCard(),
                          const SizedBox(height: 16),
                          _buildDoctorCard(),
                          const SizedBox(height: 24),
                          _buildLogoutButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A73B8), Color(0xFF63B8F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              t('profile'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: _isSaving
                ? null
                : () async {
                    if (_isEditing) {
                      await _saveProfile();
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _isEditing ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isEditing ? t('save') : t('edit'),
                      style: TextStyle(
                        color: _isEditing
                            ? const Color(0xFF1A73B8)
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    final name = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : t('patientProfile');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: _iconBgColor,
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 34,
                color: Color(0xFF1A73B8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _titleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t('type1Patient'),
            style: TextStyle(color: _subTitleColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    final bmi = _calculateBmi();

    return _buildSectionCard(
      title: t('personalInfo'),
      icon: Icons.person_outline,
      children: [
        _buildInfoRow(
          Icons.cake_outlined,
          t('age'),
          _value(profile?.age, suffix: t('years')),
        ),
        _buildEditableInfoRow(
          Icons.monitor_weight_outlined,
          t('weight'),
          _weightController,
          'kg',
        ),
        _buildEditableInfoRow(
          Icons.height_outlined,
          t('height'),
          _heightController,
          'cm',
        ),
        _buildInfoRow(
          Icons.favorite_border,
          t('bmi'),
          bmi == null ? t('notSet') : bmi.toStringAsFixed(1),
        ),
      ],
    );
  }

  Widget _buildDiabetesCard() {
    return _buildSectionCard(
      title: t('diabetesInfo'),
      icon: Icons.medical_services_outlined,
      children: [
        _buildInfoRow(
          Icons.restaurant_menu,
          t('carbRatio'),
          _value(profile?.carbRatio),
        ),
        _buildInfoRow(
          Icons.trending_down,
          t('correctionFactor'),
          _value(profile?.correctionFactor),
        ),
        _buildInfoRow(
          Icons.water_drop_outlined,
          t('lantusDose'),
          _value(profile?.lantusDose, suffix: t('units')),
        ),
        _buildInfoRow(
          Icons.access_time,
          t('lantusTime'),
          _value(profile?.lantusTime),
        ),
      ],
    );
  }

  Widget _buildAllergyCard() {
    final hasAllergy = profile?.hasFoodAllergy == true;
    final allergyText = hasAllergy
        ? _value(profile?.allergyDetails)
        : t('noFoodAllergy');

    return _buildSectionCard(
      title: t('foodAllergy'),
      icon: Icons.warning_amber_rounded,
      children: [
        _buildInfoRow(
          hasAllergy ? Icons.error_outline : Icons.check_circle_outline,
          t('allergy'),
          allergyText,
        ),
      ],
    );
  }

  Widget _buildDoctorCard() {
    return _buildSectionCard(
      title: t('doctor'),
      icon: Icons.local_hospital_outlined,
      children: [
        _buildInfoRow(
          Icons.person,
          t('doctorName'),
          _value(profile?.doctorName),
        ),
        _buildInfoRow(
          Icons.badge_outlined,
          t('specialty'),
          _value(profile?.doctorSpecialty),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _iconBgColor,
                child: Icon(icon, color: const Color(0xFF1A73B8), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _rowColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A73B8), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: _subTitleColor),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 15,
                color: _titleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow(
    IconData icon,
    String label,
    TextEditingController controller,
    String suffix,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _rowColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A73B8), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: _subTitleColor),
            ),
          ),
          _isEditing
              ? SizedBox(
                  width: 90,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.end,
                    style: TextStyle(color: _titleColor),
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: suffix,
                      suffixStyle: TextStyle(color: _subTitleColor),
                      border: const UnderlineInputBorder(),
                    ),
                  ),
                )
              : Flexible(
                  child: Text(
                    controller.text.trim().isEmpty
                        ? t('notSet')
                        : '${controller.text} $suffix',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 15,
                      color: _titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _borderColor, width: 0.5),
      boxShadow: [
        BoxShadow(
          color: _shadowColor,
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AuthScreen()),
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout),
        label: Text(t('logOut')),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE74C4C),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
