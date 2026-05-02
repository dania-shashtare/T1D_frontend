import 'package:flutter/material.dart';

class WaterTrackerPage extends StatefulWidget {
  const WaterTrackerPage({super.key});

  @override
  State<WaterTrackerPage> createState() => _WaterTrackerPageState();
}

class _WaterTrackerPageState extends State<WaterTrackerPage> {
  double currentLiters = 1.7;
  final double dailyGoal = 2.5;
  final double weight = 75;

  int lastBloodSugar = 214;
  String lastDrink = "2 hours ago";

  final List<String> weekDays = ["S", "S", "M", "T", "W", "T", "F"];
  final List<bool> reachedGoal = [true, true, false, true, true, false, false];

  void addWater(double ml) {
    setState(() {
      currentLiters += ml / 1000;
      if (currentLiters > dailyGoal) {
        currentLiters = dailyGoal;
      }
      lastDrink = "just now";
    });
  }

  void showCustomWaterDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add custom water"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Enter amount in ml",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final double? amount = double.tryParse(controller.text);

                if (amount != null && amount > 0) {
                  addWater(amount);
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double percent = currentLiters / dailyGoal;
    final double remaining = dailyGoal - currentLiters;

    return Scaffold(
      backgroundColor: const Color(0xffEAF6FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 24),

              _buildGoalCard(percent, remaining),

              const SizedBox(height: 14),

              _buildButtons(),

              const SizedBox(height: 18),

              const Text(
                "Blood sugar & water",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff4A4A4A),
                ),
              ),

              const SizedBox(height: 10),

              _buildBloodSugarCard(),

              const SizedBox(height: 18),

              const Text(
                "Weekly stats",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff4A4A4A),
                ),
              ),

              const SizedBox(height: 10),

              _buildWeeklyStatsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          "Water Tracker",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: Color(0xff1E1E1E),
          ),
        ),
        Text(
          "Fri, May 1",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xff333333),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(double percent, double remaining) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 110,
            width: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 105,
                  width: 105,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 9,
                    backgroundColor: const Color(0xffBBD9F7),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xff1765AF),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentLiters.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff222222),
                      ),
                    ),
                    const Text(
                      "liters",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xff333333),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 26),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Daily goal",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xff333333),
                  ),
                ),
                Text(
                  "${dailyGoal.toStringAsFixed(1)} L",
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff111111),
                  ),
                ),
                Text(
                  "Based on weight ${weight.toInt()} kg",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xff333333),
                  ),
                ),

                const SizedBox(height: 16),

                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 7,
                    backgroundColor: const Color(0xffBBD9F7),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xff1765AF),
                    ),
                  ),
                ),

                const SizedBox(height: 11),

                Text(
                  "${(percent * 100).round()}% done — ${remaining.toStringAsFixed(1)} L remaining",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xff444444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: _waterButton(
            text: "+ 150 ml",
            isPrimary: false,
            onTap: () => addWater(150),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _waterButton(
            text: "+ 250 ml",
            isPrimary: false,
            onTap: () => addWater(250),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _waterButton(
            text: "+ Custom",
            isPrimary: true,
            onTap: showCustomWaterDialog,
          ),
        ),
      ],
    );
  }

  Widget _waterButton({
    required String text,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 49,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor:
              isPrimary ? const Color(0xff1765AF) : Colors.white,
          foregroundColor:
              isPrimary ? Colors.white : const Color(0xff111111),
          side: BorderSide(
            color: isPrimary
                ? const Color(0xff1765AF)
                : const Color(0xffB8B8B8),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildBloodSugarCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Column(
        children: [
          _infoRow(
            title: "Last blood sugar reading",
            value: "$lastBloodSugar mg/dL",
          ),
          const Divider(height: 18),
          _infoRow(
            title: "Last drink",
            value: lastDrink,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xffE4F1FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(
                  Icons.info_outline,
                  color: Color(0xff0B4E91),
                  size: 20,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    "Your blood sugar is high — drink a glass of water now to help your body flush out excess glucose.",
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.25,
                      color: Color(0xff0B4E91),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Column(
        children: [
          _weeklyRow(
            title: "Daily average this week",
            value: "2.1 L",
          ),
          const Divider(height: 20),
          _weeklyRow(
            title: "Days goal reached",
            value: "4 of 7",
          ),
          const Divider(height: 20),
          _weeklyRow(
            title: "Best day",
            value: "2.8 L",
            badge: "Wed",
            badgeColor: const Color(0xffDCEEFF),
            badgeTextColor: const Color(0xff1765AF),
          ),
          const Divider(height: 20),
          _weeklyRow(
            title: "Worst day",
            value: "1.4 L",
            badge: "Thu",
            badgeColor: const Color(0xffFFE9C8),
            badgeTextColor: const Color(0xffB06A00),
          ),
          const Divider(height: 22),

          Row(
            children: [
              const Text(
                "This week",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xff3D3D3D),
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(weekDays.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: _dayCircle(
                      text: weekDays[index],
                      active: reachedGoal[index],
                      index: index,
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xff3B3B3B),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xff111111),
          ),
        ),
      ],
    );
  }

  Widget _weeklyRow({
    required String title,
    required String value,
    String? badge,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xff3D3D3D),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xff111111),
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _dayCircle({
    required String text,
    required bool active,
    required int index,
  }) {
    Color backgroundColor;
    Color textColor;

    if (active) {
      backgroundColor = const Color(0xff1765AF);
      textColor = Colors.white;
    } else {
      if (index == 2 || index == 6) {
        backgroundColor = const Color(0xffBBD9F7);
        textColor = const Color(0xff104A80);
      } else {
        backgroundColor = const Color(0xffEFEFEF);
        textColor = const Color(0xff777777);
      }
    }

    return Container(
      width: 31,
      height: 31,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}