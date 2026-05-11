import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'notification_service.dart';
import 'services/glucose_api.dart';
import 'patient_screen.dart';
import 'services/firebase_notification_service.dart';

class TreatmentOption {
  final String key;
  final String title;
  final String amount;
  final int carbs;
  final String imageQuery;
  final String imageUrl;

  const TreatmentOption({
    required this.key,
    required this.title,
    required this.amount,
    required this.carbs,
    required this.imageQuery,
    required this.imageUrl,
  });
}

const String _pexelsKey =
    '36pYRNHhXD1sdl1qwsWjx8ltRmusydlEZSJa9DL72CzVnB9efH10mi9v';

class LowGlucoseScreen extends StatefulWidget {
  final String readingId;
  final double glucoseValue;
  final String userId;
  final double patientWeightKg;

  const LowGlucoseScreen({
    super.key,
    required this.readingId,
    required this.glucoseValue,
    required this.userId,
    required this.patientWeightKg,
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
  bool isLoadingSuggestions = true;
  bool isSaving = false;
  bool aiFailed = false;
  bool hasSavedTreatment = false;

  final TextEditingController _otherFoodController = TextEditingController();

  String? savedTreatmentTitle;
  String? savedTreatmentSubtitle;
  String? savedCustomText;
  String? savedPresetKey;

  List<TreatmentOption> options = [];

  late final AnimationController _wobbleCtrl;
  late final Animation<double> _wobbleAnim;

  double get requiredCarbs => widget.patientWeightKg * 0.3;
  int get requiredCarbsRounded => requiredCarbs.round();

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

    _initLowScreen();
  }

  Future<void> _initLowScreen() async {
    await _loadSavedTreatment();

    if (!mounted) return;

    if (hasSavedTreatment) {
      setState(() {
        isLoadingSuggestions = false;
      });
      return;
    }

    await _loadAiSuggestions();
  }

  @override
  void dispose() {
    _otherFoodController.dispose();
    _wobbleCtrl.dispose();
    super.dispose();
  }

  Future<String> _fetchPexelsImage(String query) async {
    try {
      final q = Uri.encodeComponent('$query food drink');

      final res = await http.get(
        Uri.parse(
          'https://api.pexels.com/v1/search?query=$q&per_page=1&orientation=square',
        ),
        headers: {'Authorization': _pexelsKey},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final photos = data['photos'] as List;

        if (photos.isNotEmpty) {
          return photos[0]['src']['large'] as String;
        }
      }
    } catch (e) {
      debugPrint('Pexels image failed: $e');
    }

    return '';
  }

  Future<void> _loadAiSuggestions() async {
    try {
      final suggestions = await GlucoseApi.getLowTreatmentSuggestions(
        carbsNeeded: requiredCarbsRounded,
        weight: widget.patientWeightKg,
      );

      final List<TreatmentOption> loadedOptions = [];

      for (final item in suggestions) {
        final title = (item['title'] ?? 'Fast carbs').toString();
        final amount = (item['amount'] ?? '').toString();
        final imageQuery = (item['image_query'] ?? title).toString();

        final carbsValue =
            int.tryParse((item['carbs'] ?? requiredCarbsRounded).toString()) ??
            requiredCarbsRounded;

        final imageUrl = await _fetchPexelsImage(imageQuery);

        loadedOptions.add(
          TreatmentOption(
            key: title.toLowerCase().replaceAll(' ', '_'),
            title: title,
            amount: amount,
            carbs: carbsValue,
            imageQuery: imageQuery,
            imageUrl: imageUrl,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        options = loadedOptions;
        aiFailed = options.isEmpty;
        isLoadingSuggestions = false;
      });
    } catch (e) {
      debugPrint('AI suggestions failed: $e');

      if (!mounted) return;

      setState(() {
        options = _backupOptions();
        aiFailed = true;
        isLoadingSuggestions = false;
      });
    }
  }

  List<TreatmentOption> _backupOptions() {
    final c = requiredCarbsRounded;

    return [
      TreatmentOption(
        key: 'orange_juice',
        title: 'Orange Juice',
        amount: 'About ${(c * 8).round()} ml',
        carbs: c,
        imageQuery: 'orange juice',
        imageUrl: '',
      ),
      TreatmentOption(
        key: 'glucose_tablets',
        title: 'Glucose Tablets',
        amount: 'About ${(c / 4).ceil()} tablets',
        carbs: c,
        imageQuery: 'glucose tablets',
        imageUrl: '',
      ),
      TreatmentOption(
        key: 'regular_soda',
        title: 'Regular Soda',
        amount: 'About ${(c * 10).round()} ml',
        carbs: c,
        imageQuery: 'regular soda',
        imageUrl: '',
      ),
      TreatmentOption(
        key: 'honey',
        title: 'Honey',
        amount: 'About ${(c / 17).clamp(0.5, 2.0).toStringAsFixed(1)} tbsp',
        carbs: c,
        imageQuery: 'honey',
        imageUrl: '',
      ),
    ];
  }

  Future<void> _loadSavedTreatment() async {
    try {
      final reading = await GlucoseApi.getReadingById(widget.readingId);
      final lowTreatment = reading['lowTreatment'];

      if (lowTreatment == null) {
        if (!mounted) return;
        setState(() {
          isLoadingSavedTreatment = false;
          hasSavedTreatment = false;
        });
        return;
      }

      final type = (lowTreatment['type'] ?? '').toString();
      final title = (lowTreatment['title'] ?? '').toString();
      final subtitle = (lowTreatment['subtitle'] ?? '').toString();
      final customText = (lowTreatment['customText'] ?? '').toString();
      final presetKey = (lowTreatment['presetKey'] ?? '').toString();
      final savedReminder = lowTreatment['reminderEnabled'];

      final savedImageUrl = (lowTreatment['imageUrl'] ?? '').toString();
      final savedImageQuery = (lowTreatment['imageQuery'] ?? '').toString();

      final selectedCarbs =
          int.tryParse(
            (lowTreatment['selectedCarbs'] ?? requiredCarbsRounded).toString(),
          ) ??
          requiredCarbsRounded;

      if (!mounted) return;

      setState(() {
        hasSavedTreatment = true;
        savedPresetKey = presetKey.isEmpty ? null : presetKey;

        reminderEnabled = savedReminder is bool ? savedReminder : true;

        savedTreatmentTitle = title.isEmpty ? null : title;
        savedTreatmentSubtitle = subtitle.isEmpty ? null : subtitle;
        savedCustomText = customText.isEmpty ? null : customText;

        if (type == 'other') {
          selectedFoodIndex = null;
          isOtherSelected = true;
          _otherFoodController.text = customText;
          options = [];
        } else {
          isOtherSelected = false;
          selectedFoodIndex = 0;

          options = [
            TreatmentOption(
              key: savedPresetKey ?? title.toLowerCase().replaceAll(' ', '_'),
              title: title.isEmpty ? 'Saved treatment' : title,
              amount: subtitle.isEmpty ? 'Saved option' : subtitle,
              carbs: selectedCarbs,
              imageQuery: savedImageQuery.isEmpty ? title : savedImageQuery,
              imageUrl: savedImageUrl,
            ),
          ];
        }

        isLoadingSavedTreatment = false;
      });
    } catch (e) {
      debugPrint('Failed to load saved low treatment: $e');

      if (!mounted) return;
      setState(() {
        isLoadingSavedTreatment = false;
        hasSavedTreatment = false;
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
          : options[selectedFoodIndex!];

      await GlucoseApi.saveLowTreatment(
        readingId: widget.readingId,
        type: isOther ? 'other' : 'preset',
        presetKey: isOther ? null : selected!.key,
        title: isOther ? 'Other' : selected!.title,
        subtitle: isOther
            ? ''
            : '${selected!.amount} • ${selected.carbs}g carbs',
        customText: isOther ? customText : '',
        reminderEnabled: reminderEnabled,
        carbsNeeded: requiredCarbsRounded,
        selectedCarbs: isOther ? requiredCarbsRounded : selected!.carbs,
        imageUrl: isOther ? '' : selected!.imageUrl,
        imageQuery: isOther ? '' : selected!.imageQuery,
      );

      if (reminderEnabled) {
        try {
          Timer(const Duration(minutes: 1), () async {
            try {
              debugPrint('USER ID FOR NOTIFICATION: ${widget.userId}');
              debugPrint('ADDING NOTIFICATION TO FIRESTORE...');

              await NotificationService.showLowGlucoseNotification();

              await FirebaseNotificationService.saveNotificationToFirestore(
                userId: widget.userId,
                title: 'Low glucose follow-up',
                body: '15 minutes passed. Please recheck your glucose.',
                type: 'low_glucose_followup',
              );

              debugPrint('NOTIFICATION ADDED TO FIRESTORE ✅');
            } catch (e) {
              debugPrint('Timer notification/firestore failed: $e');
            }
          });
        } catch (e) {
          debugPrint('Notification failed: $e');
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
                    child: Text(
                      hasSavedTreatment
                          ? 'Saved treatment for this reading'
                          : 'These are the best suggestions for your weight.',
                      style: const TextStyle(
                        color: _labelText,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Text(
                      hasSavedTreatment
                          ? 'This is what you already selected before.'
                          : aiFailed
                          ? 'Backup suggestions close to $requiredCarbsRounded g fast carbs:'
                          : 'AI suggestions close to $requiredCarbsRounded g fast carbs:',
                      style: const TextStyle(
                        color: _subtleText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isLoadingSavedTreatment || isLoadingSuggestions)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: CircularProgressIndicator(color: _darkBlue),
                      ),
                    )
                  else ...[
                    if (options.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: options.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: hasSavedTreatment
                                    ? 1
                                    : gridCount,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: hasSavedTreatment
                                    ? 2.2
                                    : gridRatio,
                              ),
                          itemBuilder: (_, i) => _buildFoodCard(i),
                        ),
                      ),
                    if (!hasSavedTreatment) ...[
                      const SizedBox(height: 14),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: _buildOtherButton(),
                      ),
                    ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What to do',
            style: TextStyle(
              color: _darkBlue,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hasSavedTreatment
                ? 'You already saved what you ate for this low glucose reading.'
                : 'Based on your weight, take $requiredCarbsRounded grams of fast-acting carbs now. Choose what you ate, then recheck your blood sugar in 15 minutes.',
            style: const TextStyle(
              color: _bodyText,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(int index) {
    final opt = options[index];
    final selected = selectedFoodIndex == index && !isOtherSelected;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: hasSavedTreatment ? null : () => _selectPreset(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                opt.imageUrl.isNotEmpty
                    ? Image.network(
                        opt.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imageFallback(),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return _imageFallback(loading: true);
                        },
                      )
                    : _imageFallback(),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 34, 12, 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.74),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          opt.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          opt.amount,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${opt.carbs}g carbs',
                            style: const TextStyle(
                              color: _darkBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? _darkBlue
                          : Colors.white.withOpacity(0.9),
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
      ),
    );
  }

  Widget _imageFallback({bool loading = false}) {
    return Container(
      color: _lightPanel,
      child: Center(
        child: loading
            ? const CircularProgressIndicator(color: _darkBlue, strokeWidth: 2)
            : const Icon(Icons.fastfood_rounded, color: _borderBlue, size: 44),
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
              child: Text(
                'Other — write what you ate or drank',
                style: TextStyle(
                  color: Color(0xFF18406D),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherTextField() {
    return TextField(
      controller: _otherFoodController,
      enabled: !hasSavedTreatment,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: 'Write what you ate or drank',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
      child: Text(
        'Saved treatment: $savedText',
        style: const TextStyle(fontSize: 13, color: _bodyText, height: 1.5),
      ),
    );
  }

  Widget _buildReminderCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _darkBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.alarm_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Reminder after 15 minutes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(
            value: reminderEnabled,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF8DC2FF),
            onChanged: hasSavedTreatment
                ? null
                : (v) => setState(() => reminderEnabled = v),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: isSaving || isLoadingSavedTreatment || isLoadingSuggestions
            ? null
            : hasSavedTreatment
            ? () => Navigator.maybePop(context)
            : _confirmTreatment,
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: isSaving
            ? const Text('Saving...')
            : Text(
                hasSavedTreatment
                    ? 'Back to Chart'
                    : 'I Ate — Remind Me in 15 Minutes',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
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
    return Icon(Icons.warning_rounded, color: Colors.white, size: size * 0.6);
  }
}
