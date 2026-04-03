import 'package:flutter/material.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final double currentGlucose = 118;
  final String glucoseStatus = "In Range";
  final String lastReading = "15 min ago";

  int selectedNavIndex = 0;

  final List<Map<String, dynamic>> meals = [
    {
      "title": "Breakfast",
      "status": "Not added yet",
      "icon": Icons.free_breakfast_rounded,
    },
    {
      "title": "Lunch",
      "status": "Not added yet",
      "icon": Icons.lunch_dining_rounded,
    },
    {
      "title": "Dinner",
      "status": "Not added yet",
      "icon": Icons.dinner_dining_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEAF6FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildGlucoseCard(),
              const SizedBox(height: 14),
              _buildMealsCard(),
              const SizedBox(height: 14),
              _buildBottomNav(),
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
                "welcome",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff17466E),
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Today’s overview",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xff5E87A8),
                ),
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
        color: const Color(0xff7EC8FF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Current Glucose",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currentGlucose.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Text(
                        "mg/dL",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "$glucoseStatus • Last: $lastReading",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff2F7DB7),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            child: const Text(
              "Add\nReading",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsCard() {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Meals",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xff17466E),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Choose a meal to continue",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xff6D93B1),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                children: meals.map((meal) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _mealTile(
                      title: meal["title"] as String,
                      status: meal["status"] as String,
                      icon: meal["icon"] as IconData,
                      onTap: () => _showMealOptions(meal["title"] as String),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {"icon": Icons.home_rounded, "label": "Home"},
      {"icon": Icons.restaurant_menu_rounded, "label": "Meals"},
      {"icon": Icons.grid_view_rounded, "label": "Menu"},
      {"icon": Icons.person_outline_rounded, "label": "Profile"},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isMenu = item["label"] == "Menu";
          final selected = selectedNavIndex == index && !isMenu;

          return GestureDetector(
            onTap: () {
              if (isMenu) {
                _showMainMenu();
                return;
              }

              setState(() {
                selectedNavIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? const Color(0xffD8EEFF) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item["icon"] as IconData,
                    color: selected
                        ? const Color(0xff2F7DB7)
                        : const Color(0xff7A9AB5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item["label"] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? const Color(0xff2F7DB7)
                          : const Color(0xff7A9AB5),
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
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
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Color(0xff4D7FA8)),
    );
  }

  Widget _mealTile({
    required String title,
    required String status,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xffF5FAFE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xffDDF0FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xff2F7DB7)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff17466E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xff7A9AB5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xff7A9AB5),
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
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xffC8DDEC),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                mealTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff17466E),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Choose how you want to continue",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xff7A9AB5),
                ),
              ),
              const SizedBox(height: 18),
              _optionTile(
                icon: Icons.edit_note_rounded,
                title: "Add My Meal",
                subtitle: "Enter your meal and calculate carbs",
              ),
              const SizedBox(height: 10),
              _optionTile(
                icon: Icons.qr_code_scanner_rounded,
                title: "Scan Barcode",
                subtitle: "Scan packaged food",
              ),
              const SizedBox(height: 10),
              _optionTile(
                icon: Icons.lightbulb_outline_rounded,
                title: "Suggest a Meal",
                subtitle: "Get meal ideas if you're not sure",
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMainMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xffC8DDEC),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Menu",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff17466E),
                ),
              ),
              const SizedBox(height: 16),
              _menuOptionTile(Icons.directions_walk_rounded, "Activity"),
              const SizedBox(height: 10),
              _menuOptionTile(Icons.water_drop_outlined, "Water"),
              const SizedBox(height: 10),
              _menuOptionTile(Icons.insert_chart_outlined_rounded, "Reports"),
              const SizedBox(height: 10),
              _menuOptionTile(Icons.medical_information_outlined, "Doctor"),
              const SizedBox(height: 10),
              _menuOptionTile(Icons.family_restroom_outlined, "Family"),
              const SizedBox(height: 10),
              _menuOptionTile(Icons.settings_outlined, "Settings"),
            ],
          ),
        );
      },
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xffF5FAFE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xffDDF0FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xff2F7DB7)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xff17466E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xff7A9AB5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xff7A9AB5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuOptionTile(IconData icon, String title) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xffF5FAFE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xffDDF0FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xff2F7DB7)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xff17466E),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xff7A9AB5),
            ),
          ],
        ),
      ),
    );
  }
}