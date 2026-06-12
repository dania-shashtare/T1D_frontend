import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/family_api.dart';
import 'auth_screen.dart';
import 'providers/app_settings_provider.dart';

class FamilyProfilePage extends StatefulWidget {
  final String familyUserId;

  const FamilyProfilePage({super.key, required this.familyUserId});

  @override
  State<FamilyProfilePage> createState() => _FamilyProfilePageState();
}

class _FamilyProfilePageState extends State<FamilyProfilePage> {
  bool isLoading = true;
  bool isSaving = false;

  String parentName = '';
  String relationship = '';
  String phone = '';
  String patientName = '';
  String patientEmail = '';

  final TextEditingController parentNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String selectedRelationship = 'Mother';

  static const Color _mainBlue = Color(0xff185FA5);
  static const Color _textBlue = Color(0xff0C447C);
  static const Color _softBlue = Color(0xffEAF6FF);

  static const Color _darkBg = Color(0xff071A2F);
  static const Color _darkCard = Color(0xff102A46);
  static const Color _darkTile = Color(0xff183A5C);
  static const Color _darkSubText = Color(0xffAFC7DD);

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'familyProfile': 'Family Profile',
      'edit': 'Edit',
      'logout': 'Logout',
      'editFamilyInformation': 'Edit Family Information',
      'fullName': 'Full Name',
      'relationship': 'Relationship',
      'phone': 'Phone',
      'mother': 'Mother',
      'father': 'Father',
      'sibling': 'Sibling',
      'relative': 'Relative',
      'caregiver': 'Caregiver',
      'cancel': 'Cancel',
      'save': 'Save',
      'saving': 'Saving...',
      'pleaseFillAllFields': 'Please fill all fields',
      'profileUpdated': 'Profile updated successfully',
      'failedLoadProfile': 'Failed to load family profile',
      'familyMember': 'Family Member',
      'familyInformation': 'Family Information',
      'name': 'Name',
      'linkedPatient': 'Linked Patient',
      'patient': 'Patient',
      'email': 'Email',
    },
    'ar': {
      'familyProfile': 'ملف الأهل',
      'edit': 'تعديل',
      'logout': 'تسجيل الخروج',
      'editFamilyInformation': 'تعديل معلومات الأهل',
      'fullName': 'الاسم الكامل',
      'relationship': 'صلة القرابة',
      'phone': 'رقم الهاتف',
      'mother': 'الأم',
      'father': 'الأب',
      'sibling': 'الأخ/الأخت',
      'relative': 'قريب',
      'caregiver': 'مرافق',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'saving': 'جاري الحفظ...',
      'pleaseFillAllFields': 'يرجى تعبئة جميع الحقول',
      'profileUpdated': 'تم تحديث الملف بنجاح',
      'failedLoadProfile': 'فشل تحميل ملف الأهل',
      'familyMember': 'فرد من الأهل',
      'familyInformation': 'معلومات الأهل',
      'name': 'الاسم',
      'linkedPatient': 'المريض المرتبط',
      'patient': 'المريض',
      'email': 'البريد الإلكتروني',
    },
  };

  String t(String key) {
    final lang = context.watch<AppSettingsProvider>().language;
    return _strings[lang]?[key] ?? _strings['en']?[key] ?? key;
  }

  bool get _isArabic => context.watch<AppSettingsProvider>().language == 'ar';
  bool get _isDark => context.watch<AppSettingsProvider>().darkMode;

  TextDirection get _pageDirection =>
      _isArabic ? TextDirection.rtl : TextDirection.ltr;

  Color get _pageBg => _isDark ? _darkBg : _softBlue;
  Color get _cardColor => _isDark ? _darkCard : Colors.white;
  Color get _tileColor => _isDark ? _darkTile : const Color(0xffF8FCFF);
  Color get _titleColor => _isDark ? Colors.white : _textBlue;
  Color get _subtitleColor => _isDark ? _darkSubText : const Color(0xff6D8AA5);
  Color get _borderColor =>
      _isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04);
  Color get _inputBorderColor =>
      _isDark ? Colors.white.withOpacity(0.12) : const Color(0xffBBDEFB);

  @override
  void initState() {
    super.initState();
    _loadFamilyProfile();
  }

  @override
  void dispose() {
    parentNameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyProfile() async {
    try {
      final data = await FamilyApi.getFamilyProfile(widget.familyUserId);

      final parentProfile = data['parentProfile'];
      final linkedPatient = parentProfile['linkedPatientId'];

      setState(() {
        parentName = parentProfile['parentName']?.toString() ?? '';
        relationship = parentProfile['relationship']?.toString() ?? '';
        phone = parentProfile['phone']?.toString() ?? '';

        parentNameController.text = parentName;
        phoneController.text = phone;
        selectedRelationship = relationship.trim().isEmpty
            ? 'Mother'
            : relationship;

        if (linkedPatient is Map) {
          patientName =
              '${linkedPatient['firstName'] ?? ''} ${linkedPatient['lastName'] ?? ''}'
                  .trim();
          patientEmail = linkedPatient['email']?.toString() ?? '';
        }

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load family profile: $e');

      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${t('failedLoadProfile')}: $e')));
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('userId');
    await prefs.remove('role');
    await prefs.remove('savedUserId');
    await prefs.remove('savedRole');

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  String _relationshipDisplay(String value) {
    switch (value) {
      case 'Mother':
        return t('mother');
      case 'Father':
        return t('father');
      case 'Sibling':
        return t('sibling');
      case 'Relative':
        return t('relative');
      case 'Caregiver':
        return t('caregiver');
      default:
        return value.trim().isEmpty ? '-' : value;
    }
  }

  void _showEditFamilyDialog() {
    parentNameController.text = parentName;
    phoneController.text = phone;
    selectedRelationship = relationship.trim().isEmpty
        ? 'Mother'
        : relationship;

    showDialog(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: _pageDirection,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: _cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                title: Text(
                  t('editFamilyInformation'),
                  style: TextStyle(
                    color: _titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: parentNameController,
                        style: TextStyle(color: _titleColor),
                        decoration: _dialogInputDecoration(
                          label: t('fullName'),
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedRelationship,
                        isExpanded: true,
                        dropdownColor: _cardColor,
                        style: TextStyle(color: _titleColor),
                        decoration: _dialogInputDecoration(
                          label: t('relationship'),
                          icon: Icons.family_restroom,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Mother',
                            child: Text(t('mother')),
                          ),
                          DropdownMenuItem(
                            value: 'Father',
                            child: Text(t('father')),
                          ),
                          DropdownMenuItem(
                            value: 'Sibling',
                            child: Text(t('sibling')),
                          ),
                          DropdownMenuItem(
                            value: 'Relative',
                            child: Text(t('relative')),
                          ),
                          DropdownMenuItem(
                            value: 'Caregiver',
                            child: Text(t('caregiver')),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedRelationship = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: _titleColor),
                        decoration: _dialogInputDecoration(
                          label: t('phone'),
                          icon: Icons.phone_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    child: Text(t('cancel')),
                  ),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = parentNameController.text.trim();
                            final phoneText = phoneController.text.trim();

                            if (name.isEmpty || phoneText.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(t('pleaseFillAllFields')),
                                ),
                              );
                              return;
                            }

                            setDialogState(() => isSaving = true);

                            try {
                              await FamilyApi.updateFamilyProfile(
                                userId: widget.familyUserId,
                                parentName: name,
                                relationship: selectedRelationship,
                                phone: phoneText,
                              );

                              if (!mounted) return;

                              setState(() {
                                parentName = name;
                                relationship = selectedRelationship;
                                phone = phoneText;
                              });

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(t('profileUpdated'))),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceAll('Exception: ', ''),
                                  ),
                                ),
                              );
                            } finally {
                              setDialogState(() => isSaving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mainBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isSaving ? t('saving') : t('save')),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  InputDecoration _dialogInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _subtitleColor),
      prefixIcon: Icon(icon, color: _mainBlue),
      filled: true,
      fillColor: _tileColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: _inputBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: _inputBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _mainBlue, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _pageDirection,
      child: Scaffold(
        backgroundColor: _pageBg,
        appBar: AppBar(
          title: Text(t('familyProfile')),
          backgroundColor: _isDark ? const Color(0xff102A46) : _mainBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: isLoading ? null : _showEditFamilyDialog,
              icon: const Icon(Icons.edit_outlined),
              tooltip: t('edit'),
            ),
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              tooltip: t('logout'),
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadFamilyProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _mainCard(),
                      const SizedBox(height: 14),
                      _infoCard(
                        title: t('familyInformation'),
                        children: [
                          _row(t('name'), parentName),
                          _row(
                            t('relationship'),
                            _relationshipDisplay(relationship),
                          ),
                          _row(t('phone'), phone),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _infoCard(
                        title: t('linkedPatient'),
                        children: [
                          _row(
                            t('patient'),
                            patientName.isEmpty ? t('patient') : patientName,
                          ),
                          _row(t('email'), patientEmail),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _mainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _mainBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _mainBlue.withOpacity(_isDark ? 0.10 : 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
              color: _mainBlue,
              size: 38,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            parentName.isEmpty ? t('familyMember') : parentName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            relationship.isEmpty ? '-' : _relationshipDisplay(relationship),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _titleColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(
                color: _subtitleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: TextStyle(color: _titleColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
