import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'services/glucose_api.dart';
import 'patient_screen.dart';

class TreatmentOption {
  final String key;
  final String title;
  final String subtitle;
  final String imagePath;

  const TreatmentOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });
}

class LowGlucoseScreen extends StatefulWidget {
  final String readingId;
  final double glucoseValue;
  final String userId;

  const LowGlucoseScreen({
    super.key,
    required this.readingId,
    required this.glucoseValue,
    required this.userId,
  });

  @override
  State<LowGlucoseScreen> createState() => _LowGlucoseScreenState();
}

class _LowGlucoseScreenState extends State<LowGlucoseScreen>
    with SingleTickerProviderStateMixin {
  int? selectedFoodIndex;
  bool reminderEnabled = true;
  bool isOtherSelected = false;
  bool isLoadingSavedTreatment = true;
  bool isSaving = false;

  final TextEditingController _otherFoodController = TextEditingController();

  String? savedTreatmentTitle;
  String? savedTreatmentSubtitle;
  String? savedCustomText;

  late final AnimationController _wobbleCtrl;
  late final Animation<double> _wobbleAnim;

  static const List<TreatmentOption> _options = [
    TreatmentOption(
      key: 'orange_juice',
      title: 'Orange Juice',
      subtitle: '120 ml  •  ½ cup',
      imagePath: 'lib/assets/images/orange_juice.png',
    ),
    TreatmentOption(
      key: 'glucose_tablets',
      title: 'Glucose Tablets',
      subtitle: '3–4 tablets',
      imagePath: 'lib/assets/images/glucose_tablets.png',
    ),
    TreatmentOption(
      key: 'regular_soda',
      title: 'Regular Soda',
      subtitle: '150 ml  •  ½ can',
      imagePath: 'lib/assets/images/regular_soda.png',
    ),
    TreatmentOption(
      key: 'honey',
      title: 'Honey',
      subtitle: '1 tablespoon',
      imagePath: 'lib/assets/images/honey.png',
    ),
    TreatmentOption(
      key: 'toast',
      title: 'Toast',
      subtitle: '1 slice',
      imagePath: 'lib/assets/images/toast.png',
    ),
    TreatmentOption(
      key: 'raisins',
      title: 'Raisins',
      subtitle: '2 tablespoons',
      imagePath: 'lib/assets/images/raisins.png',
    ),
  ];

  static const _pageBg = Color(0xFFF4F8FD);
  static const _red = Color(0xFFE85151);
  static const _darkBlue = Color(0xFF1D5FAE);
  static const _borderBlue = Color(0xFF9BC3F2);
  static const _lightPanel = Color(0xFFEAF4FF);
  static const _cardBg = Colors.white;
  static const _bodyText = Color(0xFF284766);
  static const _labelText = Color(0xFF23476C);
  static const _subtleText = Color(0xFF6D8BA8);
  static const _footerText = Color(0xFF6A7E94);

  @override
  void initState() {
    super.initState();

    _wobbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    _wobbleAnim = Tween<double>(
      begin: -0.015,
      end: 0.015,
    ).animate(CurvedAnimation(parent: _wobbleCtrl, curve: Curves.easeInOut));

    _loadSavedTreatment();
  }

  @override
  void dispose() {
    _otherFoodController.dispose();
    _wobbleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedTreatment() async {
    try {
      final reading = await GlucoseApi.getReadingById(widget.readingId);
      final lowTreatment = reading['lowTreatment'];

      if (lowTreatment == null) {
        if (!mounted) return;
        setState(() {
          isLoadingSavedTreatment = false;
        });
        return;
      }

      final type = (lowTreatment['type'] ?? '').toString();
      final presetKey = (lowTreatment['presetKey'] ?? '').toString();
      final title = (lowTreatment['title'] ?? '').toString();
      final subtitle = (lowTreatment['subtitle'] ?? '').toString();
      final customText = (lowTreatment['customText'] ?? '').toString();
      final savedReminder = lowTreatment['reminderEnabled'];

      int? matchedIndex;

      for (int i = 0; i < _options.length; i++) {
        final option = _options[i];

        if (option.key == presetKey || option.title == title) {
          matchedIndex = i;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        if (type == 'other') {
          selectedFoodIndex = null;
          isOtherSelected = true;
          _otherFoodController.text = customText;
        } else {
          selectedFoodIndex = matchedIndex;
          isOtherSelected = false;
          _otherFoodController.clear();
        }

        reminderEnabled = savedReminder is bool ? savedReminder : true;

        savedTreatmentTitle = title.isEmpty ? null : title;
        savedTreatmentSubtitle = subtitle.isEmpty ? null : subtitle;
        savedCustomText = customText.isEmpty ? null : customText;

        isLoadingSavedTreatment = false;
      });
    } catch (e) {
      debugPrint('Failed to load saved low treatment: $e');

      if (!mounted) return;
      setState(() {
        isLoadingSavedTreatment = false;
      });
    }
  }

  Future<void> _confirmTreatment() async {
    final customText = _otherFoodController.text.trim();

    if (selectedFoodIndex == null && !isOtherSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select what you ate first.')),
      );
      return;
    }

    if (isOtherSelected && customText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write what you ate or drank.')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final bool isOther = isOtherSelected;

      final TreatmentOption? selected = selectedFoodIndex == null
          ? null
          : _options[selectedFoodIndex!];

      await GlucoseApi.saveLowTreatment(
        readingId: widget.readingId,
        type: isOther ? 'other' : 'preset',
        presetKey: isOther ? null : selected!.key,
        title: isOther ? 'Other' : selected!.title,
        subtitle: isOther ? '' : selected!.subtitle,
        customText: isOther ? customText : '',
        reminderEnabled: reminderEnabled,
      );

      if (reminderEnabled) {
        try {
          await NotificationService.scheduleRecheckNotification();
        } catch (e) {
          debugPrint('Notification scheduling failed: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reminderEnabled
                ? 'Saved. We will remind you in 15 minutes to check your glucose.'
                : 'Saved. Treatment confirmed.',
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PatientHomeScreen(userId: widget.userId),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save treatment: $e')));
    }
  }

  void _selectPreset(int index) {
    setState(() {
      selectedFoodIndex = index;
      isOtherSelected = false;
      _otherFoodController.clear();
    });
  }

  void _selectOther() {
    setState(() {
      selectedFoodIndex = null;
      isOtherSelected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isMobile = w < 650;
            final isWide = w >= 1100;

            final hPad = isMobile
                ? 16.0
                : isWide
                ? 42.0
                : 26.0;

            final gridCount = isWide ? 3 : 2;
            final gridRatio = isWide
                ? 1.12
                : isMobile
                ? 1.03
                : 1.08;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAlertHeader(isMobile, isWide),
                  const SizedBox(height: 18),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: _buildInfoPanel(),
                  ),

                  const SizedBox(height: 18),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: const Text(
                      'Choose one option below (about 15 g carbs):',
                      style: TextStyle(
                        color: _labelText,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (isLoadingSavedTreatment)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: CircularProgressIndicator(color: _darkBlue),
                      ),
                    )
                  else ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _options.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridCount,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: gridRatio,
                        ),
                        itemBuilder: (_, i) => _buildFoodCard(i),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _buildOtherButton(),
                    ),

                    if (isOtherSelected) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: _buildOtherTextField(),
                      ),
                    ],
                  ],

                  if (savedTreatmentTitle != null ||
                      savedCustomText != null) ...[
                    const SizedBox(height: 14),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _buildSavedTreatmentBox(),
                    ),
                  ],

                  const SizedBox(height: 20),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: _buildReminderCard(isMobile),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: _buildConfirmButton(),
                  ),

                  const SizedBox(height: 14),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: const Text(
                      'If you still feel low or your glucose is not improving, ask for help immediately.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _footerText,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAlertHeader(bool isMobile, bool isWide) {
    final mascot = AnimatedBuilder(
      animation: _wobbleAnim,
      builder: (_, child) {
        return Transform.rotate(angle: _wobbleAnim.value, child: child);
      },
      child: SizedBox(
        width: isMobile ? 120 : (isWide ? 190 : 160),
        height: isMobile ? 120 : (isWide ? 190 : 160),
        child: Image.asset(
          'lib/assets/images/low_mascot.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return _FallbackMascot(size: isMobile ? 120 : (isWide ? 190 : 160));
          },
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 18 : 26,
        18,
        isMobile ? 18 : 26,
        24,
      ),
      decoration: const BoxDecoration(
        color: _red,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderTopRow(),
                const SizedBox(height: 14),
                Center(child: mascot),
                const SizedBox(height: 10),
                _buildGlucoseValueText(isMobile: true),
                const SizedBox(height: 14),
                _buildStatusPill(),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderTopRow(),
                      const SizedBox(height: 22),
                      _buildGlucoseValueText(isMobile: false),
                      const SizedBox(height: 16),
                      _buildStatusPill(),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                mascot,
              ],
            ),
    );
  }

  Widget _buildHeaderTopRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'LOW GLUCOSE ALERT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlucoseValueText({required bool isMobile}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          widget.glucoseValue.toStringAsFixed(0),
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 58 : 70,
            fontWeight: FontWeight.w300,
            height: 0.9,
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 10 : 12),
          child: Text(
            'mg/dL',
            style: TextStyle(
              color: Colors.white70,
              fontSize: isMobile ? 22 : 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFFFCDD2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Low  •  treat now',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _lightPanel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderBlue, width: 1.2),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What to do',
            style: TextStyle(
              color: _darkBlue,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Take 15 grams of fast-acting carbs now. Choose what you ate, then recheck your blood sugar in 15 minutes.',
            style: TextStyle(color: _bodyText, fontSize: 15, height: 1.55),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(int index) {
    final opt = _options[index];
    final selected = selectedFoodIndex == index && !isOtherSelected;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        splashColor: const Color(0xffBFE2FF).withOpacity(0.25),
        highlightColor: const Color(0xffD9EEFF).withOpacity(0.28),
        onTap: () => _selectPreset(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? _darkBlue : _borderBlue,
              width: selected ? 2.1 : 1.3,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xffCFE6FF).withOpacity(0.7),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        opt.imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.fastfood_rounded,
                            size: 44,
                            color: Color(0xFF9BC3F2),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    opt.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF18406D),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    opt.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _subtleText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? _darkBlue : Colors.transparent,
                    border: Border.all(
                      color: selected ? _darkBlue : _borderBlue,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 17)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _selectOther,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOtherSelected ? _darkBlue : _borderBlue,
            width: isOtherSelected ? 2 : 1.3,
          ),
          boxShadow: isOtherSelected
              ? [
                  BoxShadow(
                    color: const Color(0xffCFE6FF).withOpacity(0.7),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: _darkBlue,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Other',
                    style: TextStyle(
                      color: Color(0xFF18406D),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Write what you ate or drank',
                    style: TextStyle(
                      color: _subtleText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOtherSelected ? _darkBlue : Colors.transparent,
                border: Border.all(
                  color: isOtherSelected ? _darkBlue : _borderBlue,
                  width: 2,
                ),
              ),
              child: isOtherSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 17)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherTextField() {
    return TextField(
      controller: _otherFoodController,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: 'Write what you ate or drank',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderBlue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _darkBlue, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildSavedTreatmentBox() {
    final savedText = savedCustomText != null && savedCustomText!.isNotEmpty
        ? savedCustomText!
        : '${savedTreatmentTitle ?? ''}${(savedTreatmentSubtitle != null && savedTreatmentSubtitle!.isNotEmpty) ? ' — ${savedTreatmentSubtitle!}' : ''}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saved treatment',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _darkBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            savedText,
            style: const TextStyle(fontSize: 13, color: _bodyText, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(bool isMobile) {
    final switchWidget = Switch(
      value: reminderEnabled,
      activeColor: Colors.white,
      activeTrackColor: const Color(0xFF8DC2FF),
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.white24,
      onChanged: (v) => setState(() => reminderEnabled = v),
    );

    const icon = Icon(Icons.alarm_rounded, color: Colors.white, size: 28);

    const textCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder after 15 minutes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Turn this on to get a notification to recheck your glucose.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _darkBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: icon,
                    ),
                    const Spacer(),
                    switchWidget,
                  ],
                ),
                const SizedBox(height: 12),
                textCol,
              ],
            )
          : Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: icon,
                ),
                const SizedBox(width: 16),
                const Expanded(child: textCol),
                switchWidget,
              ],
            ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: isSaving || isLoadingSavedTreatment
            ? null
            : _confirmTreatment,
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkBlue,
          disabledBackgroundColor: _darkBlue.withOpacity(0.45),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: isSaving
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Saving...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'I Ate — Remind Me in 15 Minutes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}

class _FallbackMascot extends StatelessWidget {
  final double size;

  const _FallbackMascot({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MascotPainter()),
    );
  }
}

class _MascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final bodyPaint = Paint()..color = const Color(0xFF4A90D9);

    final bodyPath = Path()
      ..moveTo(cx, h * 0.08)
      ..cubicTo(cx + w * 0.45, h * 0.08, cx + w * 0.45, h * 0.72, cx, h * 0.82)
      ..cubicTo(cx - w * 0.45, h * 0.72, cx - w * 0.45, h * 0.08, cx, h * 0.08);

    canvas.drawPath(bodyPath, bodyPaint);

    canvas.drawPath(
      bodyPath,
      Paint()..color = const Color(0xFF5AA3E8).withOpacity(0.6),
    );

    final armPaint = Paint()
      ..color = const Color(0xFF4A90D9)
      ..strokeWidth = w * 0.13
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(cx - w * 0.34, h * 0.48),
      Offset(cx - w * 0.50, h * 0.32),
      armPaint,
    );

    canvas.drawLine(
      Offset(cx + w * 0.34, h * 0.48),
      Offset(cx + w * 0.50, h * 0.32),
      armPaint,
    );

    final legPaint = Paint()
      ..color = const Color(0xFF1E4F8A)
      ..strokeWidth = w * 0.13
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(cx - w * 0.18, h * 0.80),
      Offset(cx - w * 0.18, h * 0.95),
      legPaint,
    );

    canvas.drawLine(
      Offset(cx + w * 0.18, h * 0.80),
      Offset(cx + w * 0.18, h * 0.95),
      legPaint,
    );

    final white = Paint()..color = Colors.white;
    final pupil = Paint()..color = const Color(0xFF1E3A6E);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - w * 0.14, h * 0.42),
        width: w * 0.15,
        height: h * 0.13,
      ),
      white,
    );

    canvas.drawCircle(Offset(cx - w * 0.14, h * 0.44), w * 0.05, pupil);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + w * 0.14, h * 0.42),
        width: w * 0.15,
        height: h * 0.13,
      ),
      white,
    );

    canvas.drawCircle(Offset(cx + w * 0.14, h * 0.44), w * 0.05, pupil);

    final browPaint = Paint()
      ..color = const Color(0xFF2563A8)
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx - w * 0.14, h * 0.35),
        width: w * 0.18,
        height: h * 0.08,
      ),
      3.4,
      2.2,
      false,
      browPaint,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx + w * 0.14, h * 0.35),
        width: w * 0.18,
        height: h * 0.08,
      ),
      3.4,
      2.2,
      false,
      browPaint,
    );

    final mouthPaint = Paint()
      ..color = const Color(0xFF2563A8)
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, h * 0.59),
        width: w * 0.30,
        height: h * 0.10,
      ),
      0.3,
      2.5,
      false,
      mouthPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
