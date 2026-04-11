import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'barcode_scanner_screen.dart';
import 'barcode_product_result_screen.dart';
import 'food_product.dart';
import 'services/openfoodfacts_service.dart';
import 'services/onboarding_api.dart';

class PatientHomeScreen extends StatefulWidget {
  final String userId;

  const PatientHomeScreen({super.key, required this.userId});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  double currentGlucose = 118;
  String glucoseStatus = 'In Range';
  String lastReading = 'just now';
  Color statusColor = const Color(0xff1D9E75);

  int selectedNavIndex = 0;

  final List<FlSpot> glucoseSpots = [
    const FlSpot(0, 105),
    const FlSpot(1, 130),
    const FlSpot(2, 118),
    const FlSpot(3, 142),
    const FlSpot(4, 118),
  ];

  final List<String> glucoseLabels = ['8:00', '9:30', '11:00', '12:30', 'Now'];

  final List<Map<String, dynamic>> meals = [
    {
      'title': 'Breakfast',
      'icon': Icons.free_breakfast_rounded,
      'status': 'Not added yet',
    },
    {
      'title': 'Morning Snack',
      'icon': Icons.cookie_rounded,
      'status': 'Not added yet',
    },
    {
      'title': 'Lunch',
      'icon': Icons.lunch_dining_rounded,
      'status': 'Not added yet',
    },
    {
      'title': 'Afternoon Snack',
      'icon': Icons.icecream_rounded,
      'status': 'Not added yet',
    },
    {
      'title': 'Dinner',
      'icon': Icons.dinner_dining_rounded,
      'status': 'Not added yet',
    },
  ];

  final TextEditingController _glucoseController = TextEditingController();

  @override
  void dispose() {
    _glucoseController.dispose();
    super.dispose();
  }

  Color _getGlucoseColor(double v) {
    if (v < 70 || v > 180) return const Color(0xffE24B4A);
    if (v > 140) return const Color(0xffEF9F27);
    return const Color(0xff1D9E75);
  }

  String _getGlucoseStatus(double v) {
    if (v < 70) return 'Low · check now';
    if (v > 180) return 'High · take action';
    if (v > 140) return 'Slightly high';
    return 'In Range';
  }

  void _addReading() {
    final val = double.tryParse(_glucoseController.text);
    if (val == null || val < 40 || val > 400) return;
    setState(() {
      final nextX = glucoseSpots.length.toDouble();
      glucoseSpots.add(FlSpot(nextX, val));
      final now = TimeOfDay.now();
      glucoseLabels.add(
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      );
      currentGlucose = val;
      glucoseStatus = _getGlucoseStatus(val);
      statusColor = _getGlucoseColor(val);
      lastReading = 'just now';
    });
    _glucoseController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEAF6FF),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: _buildBottomNav(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildGlucoseCard(),
              const SizedBox(height: 10),
              _buildInputRow(),
              const SizedBox(height: 14),
              _buildMealsCard(),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff0C447C),
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Today's overview",
                style: TextStyle(fontSize: 13, color: Color(0xff378ADD)),
              ),
            ],
          ),
        ),
        _circleIcon(Icons.notifications_none_rounded),
        const SizedBox(width: 10),
        _circleIcon(Icons.person_outline_rounded),
      ],
    );
  }

  Widget _buildGlucoseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff185FA5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT GLUCOSE',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currentGlucose.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Text(
                            'mg/dL',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$glucoseStatus · $lastReading',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Focus input
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xff185FA5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  '+ Add\nreading',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: LineChart(
              LineChartData(
                minY: 60,
                maxY: 200,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= glucoseLabels.length)
                          return const SizedBox();
                        return Text(
                          glucoseLabels[idx],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white60,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Colors.white10, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: glucoseSpots,
                    isCurved: true,
                    color: const Color(0xff85B7EB),
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 5,
                        color: _getGlucoseColor(spot.y),
                        strokeColor: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _glucoseController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter mg/dL...',
              hintStyle: const TextStyle(color: Color(0xff9AB8D0)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xffB5D4F4),
                  width: 0.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xffB5D4F4),
                  width: 0.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xff378ADD),
                  width: 1,
                ),
              ),
            ),
            onSubmitted: (_) => _addReading(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _addReading,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff185FA5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          ),
          child: const Text(
            'Add',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildMealsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Meals',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff17466E),
                ),
              ),
              Text(
                'Tap to add',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...meals.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _mealTile(
                title: e.value['title'] as String,
                status: e.value['status'] as String,
                icon: e.value['icon'] as IconData,
                onTap: () => _showMealOptions(e.value['title'] as String),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.restaurant_menu_rounded, 'label': 'Meals'},
      {'icon': Icons.grid_view_rounded, 'label': 'Menu'},
      {'icon': Icons.bolt_rounded, 'label': 'Activity'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isMenu = item['label'] == 'Menu';
          final selected = selectedNavIndex == index && !isMenu;

          return GestureDetector(
            onTap: () {
              if (isMenu) {
                _showMainMenu();
                return;
              }
              setState(() => selectedNavIndex = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xffE6F1FB) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 18,
                    color: selected
                        ? const Color(0xff185FA5)
                        : const Color(0xff888780),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: selected
                          ? const Color(0xff185FA5)
                          : const Color(0xff888780),
                      fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
      ),
      child: Icon(icon, size: 16, color: const Color(0xff378ADD)),
    );
  }

  Widget _mealTile({
    required String title,
    required String status,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xffF5FAFE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xffE6F1FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: const Color(0xff185FA5)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff17466E),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    status,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff7A9AB5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xffB5D4F4),
            ),
          ],
        ),
      ),
    );
  }

  void _showMealOptions(String mealTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 14),
              Text(
                mealTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff0C447C),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose how you want to continue',
                style: TextStyle(fontSize: 13, color: Color(0xff7A9AB5)),
              ),
              const SizedBox(height: 18),
              _sheetOption(
                icon: Icons.edit_note_rounded,
                title: 'Add my meal',
                subtitle: 'Enter your meal and calculate carbs',
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),
              _sheetOption(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan barcode',
                subtitle: 'Scan packaged food',
                onTap: () async {
                  Navigator.pop(context);
                  final barcode = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BarcodeScannerScreen(),
                    ),
                  );
                  if (barcode == null || barcode.toString().isEmpty) return;
                  if (!mounted) return;
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );
                  final FoodProduct? product =
                      await OpenFoodFactsService.getProductByBarcode(barcode);
                  if (mounted) Navigator.pop(context);
                  if (!mounted) return;
                  if (product == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Product not found')),
                    );
                    return;
                  }
                  final patientProfile = await OnboardingApi.getPatientProfile(
                    userId: widget.userId,
                  );
                  final double? carbRatio =
                      patientProfile != null &&
                          patientProfile['carbRatio'] != null
                      ? double.tryParse(patientProfile['carbRatio'].toString())
                      : null;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BarcodeProductResultScreen(
                        mealTitle: mealTitle,
                        product: product,
                        carbRatio: carbRatio,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _sheetOption(
                icon: Icons.lightbulb_outline_rounded,
                title: 'Suggest a meal',
                subtitle: "Get meal ideas if you're not sure",
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMainMenu() {
    final menuItems = [
      {'icon': Icons.medical_information_outlined, 'label': 'Doctor'},
      {'icon': Icons.contact_support_outlined, 'label': 'Contact'},
      {
        'icon': Icons.chat_bubble_outline_rounded,
        'label': 'Chat / Ask anything',
      },
      {'icon': Icons.restaurant_outlined, 'label': 'Nutritionist'},
      {'icon': Icons.water_drop_outlined, 'label': 'Water'},
      {'icon': Icons.insert_chart_outlined_rounded, 'label': 'Reports'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _sheetHandle(),
                const SizedBox(height: 14),
                const Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff0C447C),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: menuItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _menuTile(
                      icon: menuItems[i]['icon'] as IconData,
                      label: menuItems[i]['label'] as String,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xffC8DDEC),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xffF5FAFE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xffE6F1FB),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 20, color: const Color(0xff185FA5)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff0C447C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff7A9AB5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xffB5D4F4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xffF5FAFE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xffE6F1FB),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 22, color: const Color(0xff185FA5)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff0C447C),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xffB5D4F4),
            ),
          ],
        ),
      ),
    );
  }
}
