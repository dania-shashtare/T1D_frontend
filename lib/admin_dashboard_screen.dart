import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/admin_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String selectedSection = 'patients';
  String searchQuery = '';

  bool isLoading = true;
  Map<String, dynamic> stats = {};

  List<dynamic> patients = [];
  List<dynamic> family = [];
  List<dynamic> doctors = [];
  List<dynamic> nutritionists = [];

  @override
  void initState() {
    super.initState();
    loadAdminData();
  }

  Future<void> loadAdminData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final statsData = await AdminApi.getStats();
      final patientsData = await AdminApi.getPatients();
      final familyData = await AdminApi.getFamily();
      final doctorsData = await AdminApi.getDoctors();
      final nutritionistsData = await AdminApi.getNutritionists();

      setState(() {
        stats = statsData;
        patients = patientsData;
        family = familyData;
        doctors = doctorsData;
        nutritionists = nutritionistsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading admin data: $e')));
    }
  }

  String safeText(dynamic value) {
    if (value == null) return 'N/A';
    if (value.toString().trim().isEmpty) return 'N/A';
    return value.toString();
  }

  String getFullName(Map<String, dynamic>? user) {
    if (user == null) return 'N/A';

    final firstName = user['firstName'] ?? '';
    final lastName = user['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    return fullName.isEmpty ? 'N/A' : fullName;
  }

  int? calculateAge(dynamic birthDate) {
    if (birthDate == null) return null;

    try {
      final date = DateTime.parse(birthDate.toString());
      final now = DateTime.now();

      int age = now.year - date.year;

      if (now.month < date.month ||
          (now.month == date.month && now.day < date.day)) {
        age--;
      }

      return age;
    } catch (_) {
      return null;
    }
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'disabled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return Colors.green.withOpacity(0.12);
      case 'pending':
        return Colors.orange.withOpacity(0.14);
      case 'rejected':
      case 'disabled':
        return Colors.red.withOpacity(0.12);
      default:
        return Colors.blue.withOpacity(0.12);
    }
  }

  Future<void> openFile(String filePath) async {
    if (filePath.trim().isEmpty || filePath == 'N/A') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No file uploaded')));
      return;
    }

    String url;

    if (filePath.startsWith('/uploads')) {
      if (AdminApi.fileBaseUrl.contains('/uploads')) {
        final base = AdminApi.fileBaseUrl.replaceAll('/uploads', '');
        url = '$base$filePath';
      } else {
        url = '${AdminApi.fileBaseUrl}$filePath';
      }
    } else {
      url = '${AdminApi.fileBaseUrl}/$filePath';
    }

    final uri = Uri.parse(url);

    final canOpen = await canLaunchUrl(uri);

    if (!canOpen) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cannot open file: $url')));
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<dynamic> getCurrentList() {
    if (selectedSection == 'patients') return patients;
    if (selectedSection == 'family') return family;
    if (selectedSection == 'doctors') return doctors;
    return nutritionists;
  }

  List<dynamic> getFilteredList() {
    final list = getCurrentList();

    if (searchQuery.trim().isEmpty) return list;

    final q = searchQuery.toLowerCase();

    return list.where((item) {
      final map = item as Map<String, dynamic>;
      final user = map['userId'] is Map<String, dynamic>
          ? map['userId'] as Map<String, dynamic>
          : null;

      final name = getFullName(user).toLowerCase();
      final email = safeText(user?['email']).toLowerCase();
      final parentName = safeText(map['parentName']).toLowerCase();
      final specialty = safeText(map['specialty']).toLowerCase();

      return name.contains(q) ||
          email.contains(q) ||
          parentName.contains(q) ||
          specialty.contains(q);
    }).toList();
  }

  String getSearchHint() {
    if (selectedSection == 'patients') return 'Search by patient name...';
    if (selectedSection == 'family') return 'Search by parent name...';
    if (selectedSection == 'doctors') return 'Search by doctor name...';
    return 'Search by nutritionist name...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f9ff),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadAdminData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Admin Dashboard',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff06457c),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Manage patients, family accounts, doctors, and nutritionists',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          ElevatedButton.icon(
                            onPressed: logoutAdmin,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff06457c),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _buildStatsCards(),
                      const SizedBox(height: 32),
                      _buildTableContainer(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 900;

        return GridView.count(
          crossAxisCount: isSmall ? 2 : 4,
          crossAxisSpacing: 22,
          mainAxisSpacing: 22,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isSmall ? 1.5 : 1.8,
          children: [
            _statCard(
              title: 'Patients',
              value: safeText(stats['patients'] ?? 0),
              subtitle: 'all patients',
              icon: Icons.groups_rounded,
              section: 'patients',
            ),
            _statCard(
              title: 'Doctors',
              value: safeText(stats['doctors'] ?? 0),
              subtitle: '${stats['pendingDoctors'] ?? 0} pending',
              icon: Icons.medical_services_rounded,
              section: 'doctors',
            ),
            _statCard(
              title: 'Nutritionists',
              value: safeText(stats['nutritionists'] ?? 0),
              subtitle: '${stats['pendingNutritionists'] ?? 0} pending',
              icon: Icons.restaurant_rounded,
              section: 'nutritionists',
            ),
            _statCard(
              title: 'Family',
              value: safeText(stats['family'] ?? 0),
              subtitle: 'all active',
              icon: Icons.family_restroom_rounded,
              section: 'family',
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required String section,
  }) {
    final selected = selectedSection == section;

    return InkWell(
      onTap: () {
        setState(() {
          selectedSection = section;
          searchQuery = '';
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff9FC8EA) : const Color(0xffC8DDF0),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xff0A5FA8) : const Color(0xffB5D1EA),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xff06457c), size: 30),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: Color(0xff06457c),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xff075ea8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Color(0xff2a83d8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xffEAF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: getSearchHint(),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xffF2F9FF),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          if (selectedSection == 'patients') _patientsTable(),
          if (selectedSection == 'family') _familyTable(),
          if (selectedSection == 'doctors') _doctorsTable(),
          if (selectedSection == 'nutritionists') _nutritionistsTable(),
        ],
      ),
    );
  }

  Widget _headerRow(List<String> headers) {
    return Container(
      color: const Color(0xffCFE4F7),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
      child: Row(
        children: headers.map((h) {
          return Expanded(
            child: Text(
              h,
              style: const TextStyle(
                color: Color(0xff075ea8),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Text(
          'No data found',
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _patientsTable() {
    final data = getFilteredList();

    if (data.isEmpty) return _emptyState();

    return Column(
      children: [
        _headerRow(['Name', 'Diabetes type', 'Status', 'Action']),
        ...data.map((item) {
          final patient = item as Map<String, dynamic>;
          final user = patient['userId'] is Map<String, dynamic>
              ? patient['userId'] as Map<String, dynamic>
              : null;

          final name = getFullName(user);
          final age = calculateAge(user?['birthDate']);
          final diabetesType = safeText(
            patient['diabetesType'] ??
                patient['typeOfDiabetes'] ??
                patient['diabetes_type'] ??
                'Type 1',
          );

          final isActive = user?['isActive'] == false ? 'Disabled' : 'Active';

          return _dataRow(
            cells: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: _mainCellStyle()),
                  const SizedBox(height: 3),
                  Text(
                    age == null ? 'Age N/A' : 'Age $age',
                    style: _subCellStyle(),
                  ),
                ],
              ),
              Text(diabetesType, style: _mainCellStyle()),
              _statusBadge(isActive),
              _viewButton(() => showPatientDetails(patient)),
            ],
          );
        }),
      ],
    );
  }

  Widget _familyTable() {
    final data = getFilteredList();

    if (data.isEmpty) return _emptyState();

    return Column(
      children: [
        _headerRow(['Parent Name', 'Relationship', 'Linked Patient', 'Action']),
        ...data.map((item) {
          final profile = item as Map<String, dynamic>;
          final linkedPatient =
              profile['linkedPatientId'] is Map<String, dynamic>
              ? profile['linkedPatientId'] as Map<String, dynamic>
              : null;

          return _dataRow(
            cells: [
              Text(safeText(profile['parentName']), style: _mainCellStyle()),
              Text(safeText(profile['relationship']), style: _mainCellStyle()),
              Text(getFullName(linkedPatient), style: _mainCellStyle()),
              _viewButton(() => showFamilyDetails(profile)),
            ],
          );
        }),
      ],
    );
  }

  Widget _doctorsTable() {
    final data = getFilteredList();

    if (data.isEmpty) return _emptyState();

    return Column(
      children: [
        _headerRow(['Name', 'Specialty', 'Verification', 'Action']),
        ...data.map((item) {
          final doctor = item as Map<String, dynamic>;
          final user = doctor['userId'] is Map<String, dynamic>
              ? doctor['userId'] as Map<String, dynamic>
              : null;

          final status = safeText(doctor['verificationStatus'] ?? 'pending');

          return _dataRow(
            cells: [
              Text(getFullName(user), style: _mainCellStyle()),
              Text(safeText(doctor['specialty']), style: _mainCellStyle()),
              _statusBadge(status),
              _viewButton(() => showDoctorDetails(doctor)),
            ],
          );
        }),
      ],
    );
  }

  Widget _nutritionistsTable() {
    final data = getFilteredList();

    if (data.isEmpty) return _emptyState();

    return Column(
      children: [
        _headerRow(['Name', 'Specialty', 'Verification', 'Action']),
        ...data.map((item) {
          final nutritionist = item as Map<String, dynamic>;
          final user = nutritionist['userId'] is Map<String, dynamic>
              ? nutritionist['userId'] as Map<String, dynamic>
              : null;

          final status = safeText(
            nutritionist['verificationStatus'] ?? 'pending',
          );

          return _dataRow(
            cells: [
              Text(getFullName(user), style: _mainCellStyle()),
              Text(
                safeText(nutritionist['specialty']),
                style: _mainCellStyle(),
              ),
              _statusBadge(status),
              _viewButton(() => showNutritionistDetails(nutritionist)),
            ],
          );
        }),
      ],
    );
  }

  Widget _dataRow({required List<Widget> cells}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: cells.map((cell) {
          return Expanded(child: cell);
        }).toList(),
      ),
    );
  }

  TextStyle _mainCellStyle() {
    return const TextStyle(
      fontSize: 16,
      color: Colors.black87,
      fontWeight: FontWeight.w500,
    );
  }

  TextStyle _subCellStyle() {
    return const TextStyle(fontSize: 14, color: Colors.black54);
  }

  Widget _statusBadge(String status) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: statusBgColor(status),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: statusColor(status),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _viewButton(VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.visibility_outlined, size: 18),
        label: const Text('View'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade400),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _detailRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              '$title:',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xff06457c),
              ),
            ),
          ),
          Expanded(
            child: Text(
              safeText(value),
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void showBaseDialog({
    required String title,
    required List<Widget> children,
    List<Widget>? actions,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xff06457c),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
          actions:
              actions ??
              [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
        );
      },
    );
  }

  void showPatientDetails(Map<String, dynamic> patient) {
    final user = patient['userId'] is Map<String, dynamic>
        ? patient['userId'] as Map<String, dynamic>
        : null;

    final age = calculateAge(user?['birthDate']);

    showBaseDialog(
      title: 'Patient Details',
      children: [
        _detailRow('Full Name', getFullName(user)),
        _detailRow('Email', user?['email']),
        _detailRow('Age', age == null ? 'N/A' : age),
        _detailRow('Height', patient['height']),
        _detailRow('Weight', patient['weight']),
        _detailRow('Diagnosis Date', patient['diagnosisDate']),
        _detailRow('Management Type', patient['managementType']),
        _detailRow('Carb Ratio', patient['carbRatio']),
        _detailRow('Correction Factor', patient['correctionFactor']),
        _detailRow('Lantus Dose', patient['lantusDose']),
        _detailRow('Lantus Time', patient['lantusTime']),
        _detailRow(
          'Food Allergy',
          patient['hasFoodAllergy'] == true ? 'Yes' : 'No',
        ),
        _detailRow('Allergy Details', patient['allergyDetails']),
      ],
    );
  }

  void showFamilyDetails(Map<String, dynamic> profile) {
    final user = profile['userId'] is Map<String, dynamic>
        ? profile['userId'] as Map<String, dynamic>
        : null;

    final linkedPatient = profile['linkedPatientId'] is Map<String, dynamic>
        ? profile['linkedPatientId'] as Map<String, dynamic>
        : null;

    showBaseDialog(
      title: 'Family Details',
      children: [
        _detailRow('Parent Name', profile['parentName']),
        _detailRow('User Name', getFullName(user)),
        _detailRow('Email', user?['email']),
        _detailRow('Phone', profile['phone']),
        _detailRow('Relationship', profile['relationship']),
        const Divider(height: 24),
        _detailRow('Linked Patient', getFullName(linkedPatient)),
        _detailRow('Patient Email', linkedPatient?['email']),
        _detailRow('Patient Role', linkedPatient?['role']),
      ],
    );
  }

  void showDoctorDetails(Map<String, dynamic> doctor) {
    final user = doctor['userId'] is Map<String, dynamic>
        ? doctor['userId'] as Map<String, dynamic>
        : null;

    final cvFile = safeText(
      doctor['cvFileUrl'] ??
          doctor['professionalProofUrl'] ??
          doctor['cvFileName'] ??
          doctor['professionalProofName'] ??
          doctor['proofFileName'],
    );
    showBaseDialog(
      title: 'Doctor Details',
      children: [
        _detailRow('Full Name', getFullName(user)),
        _detailRow('Email', user?['email']),
        _detailRow('Phone', doctor['phone']),
        _detailRow('Workplace', doctor['workplace']),
        _detailRow('Specialty', doctor['specialty']),
        _detailRow('Other Specialty', doctor['otherSpecialty']),
        _detailRow('Years Experience', doctor['yearsOfExperience']),
        _detailRow('Treats Type 1', doctor['treatsType1']),
        _detailRow('Verification', doctor['verificationStatus']),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(child: _detailRow('CV / Proof', cvFile)),
            ElevatedButton.icon(
              onPressed: () => openFile(cvFile),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open CV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff075ea8),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await updateDoctorVerification(doctor['_id'], 'rejected');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Reject'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await updateDoctorVerification(doctor['_id'], 'approved');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Approve'),
        ),
      ],
    );
  }

  void showNutritionistDetails(Map<String, dynamic> nutritionist) {
    final user = nutritionist['userId'] is Map<String, dynamic>
        ? nutritionist['userId'] as Map<String, dynamic>
        : null;

    final cvFile = safeText(
      nutritionist['cvFileUrl'] ??
          nutritionist['professionalProofUrl'] ??
          nutritionist['cvFileName'] ??
          nutritionist['professionalProofName'] ??
          nutritionist['proofFileName'],
    );

    showBaseDialog(
      title: 'Nutritionist Details',
      children: [
        _detailRow('Full Name', getFullName(user)),
        _detailRow('Email', user?['email']),
        _detailRow('Phone', nutritionist['phone']),
        _detailRow('Workplace', nutritionist['workplace']),
        _detailRow('Specialty', nutritionist['specialty']),
        _detailRow('Years Experience', nutritionist['yearsOfExperience']),
        _detailRow('Planning Style', nutritionist['planningStyle']),
        _detailRow('Other Planning Style', nutritionist['otherPlanningStyle']),
        _detailRow('Type 1 Experience', nutritionist['hasType1Experience']),
        _detailRow('Verification', nutritionist['verificationStatus']),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(child: _detailRow('CV / Proof', cvFile)),
            ElevatedButton.icon(
              onPressed: () => openFile(cvFile),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open CV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff075ea8),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await updateNutritionistVerification(
              nutritionist['_id'],
              'rejected',
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Reject'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await updateNutritionistVerification(
              nutritionist['_id'],
              'approved',
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Approve'),
        ),
      ],
    );
  }

  Future<void> updateDoctorVerification(String doctorId, String status) async {
    try {
      await AdminApi.updateDoctorStatus(
        doctorProfileId: doctorId,
        status: status,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Doctor $status successfully')));

      await loadAdminData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating doctor: $e')));
    }
  }

  Future<void> logoutAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('role');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }

  Future<void> updateNutritionistVerification(
    String nutritionistId,
    String status,
  ) async {
    try {
      await AdminApi.updateNutritionistStatus(
        nutritionistProfileId: nutritionistId,
        status: status,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nutritionist $status successfully')),
      );

      await loadAdminData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating nutritionist: $e')),
      );
    }
  }
}
