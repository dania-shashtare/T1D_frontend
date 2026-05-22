import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'services/glucose_api.dart';
import 'services/ai_report_api.dart';

class ReportsScreen extends StatefulWidget {
  final String userId;
  final bool embedded;

  const ReportsScreen({super.key, required this.userId, this.embedded = false});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool isLoading = true;
  String? errorMessage;

  int selectedTab = 0;

  List<ReportReading> allReadings = [];

  bool isAiLoading = false;
  Map<String, dynamic>? aiInsight;
  String? aiError;

  static const Color _pageBg = Color(0xffEAF6FF);
  static const Color _mainBlue = Color(0xff185FA5);
  static const Color _darkBlue = Color(0xff0C447C);
  static const Color _softBlue = Color(0xffEEF7FF);
  static const Color _softBlue2 = Color(0xffDCEEFF);
  static const Color _green = Color(0xff1D9E75);
  static const Color _orange = Color(0xffEF9F27);
  static const Color _red = Color(0xffE24B4A);

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    try {
      final data = await GlucoseApi.getReadings(widget.userId);

      final loaded = data.map((e) => ReportReading.fromApiJson(e)).toList();

      loaded.sort((a, b) {
        final timeCompare = a.time.compareTo(b.time);
        if (timeCompare != 0) return timeCompare;

        final aCreated = a.createdAt ?? a.time;
        final bCreated = b.createdAt ?? b.time;
        return aCreated.compareTo(bCreated);
      });

      final cleaned = _cleanReadings(loaded);

      if (!mounted) return;

      setState(() {
        allReadings = cleaned;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      debugPrint('GLUCOSE REPORT ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  List<ReportReading> _cleanReadings(List<ReportReading> source) {
    final latestBySecond = <String, ReportReading>{};

    for (final r in source) {
      latestBySecond[_secondKey(r.time)] = r;
    }

    final cleaned = latestBySecond.values.toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    final visible = <ReportReading>[];

    for (final r in cleaned) {
      if (visible.isEmpty) {
        visible.add(r);
        continue;
      }

      final prev = visible.last;
      final suspicious = _isSuspiciousJump(prev, r);

      if (!suspicious) {
        visible.add(r);
      }
    }

    return visible;
  }

  bool _isSuspiciousJump(ReportReading prev, ReportReading curr) {
    final seconds = curr.time.difference(prev.time).inSeconds.abs();
    if (seconds <= 0) return false;

    final minutes = seconds / 60.0;
    final delta = (curr.value - prev.value).abs();
    final rate = delta / minutes;

    if (minutes <= 2 && delta >= 120) return true;
    if (minutes <= 5 && rate >= 60) return true;

    return false;
  }

  String _secondKey(DateTime time) {
    return '${time.year}-${time.month}-${time.day} '
        '${time.hour}:${time.minute}:${time.second}';
  }

  DateTime _dateOnly(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  List<ReportReading> _periodReadings() {
    final now = DateTime.now();

    if (selectedTab == 0) {
      final from = _dateOnly(now).subtract(const Duration(days: 6));
      final to = _dateOnly(now).add(const Duration(days: 1));

      return allReadings
          .where((r) => !r.time.isBefore(from) && r.time.isBefore(to))
          .toList();
    }

    if (selectedTab == 1) {
      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 1);

      return allReadings
          .where((r) => !r.time.isBefore(from) && r.time.isBefore(to))
          .toList();
    }

    final from = DateTime(now.year, 1, 1);
    final to = DateTime(now.year + 1, 1, 1);

    return allReadings
        .where((r) => !r.time.isBefore(from) && r.time.isBefore(to))
        .toList();
  }

  ReportStats _buildStats() {
    final readings = _periodReadings();

    if (readings.isEmpty) {
      return ReportStats.empty(periodName: _periodTitle());
    }

    final values = readings.map((e) => e.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);

    final overallAvg = _overallAverageGlucose();

    int low = 0;
    int inRange = 0;
    int high = 0;

    for (final r in readings) {
      if (r.value < 70) {
        low++;
      } else if (r.value > 180) {
        high++;
      } else {
        inRange++;
      }
    }

    final total = readings.length;

    final lowPercent = ((low / total) * 100).round();
    final inRangePercent = ((inRange / total) * 100).round();
    final highPercent = ((high / total) * 100).round();

    final lowEpisodes = _countEpisodes(readings, 'low');
    final highEpisodes = _countEpisodes(readings, 'high');

    final chartPoints = _buildChartPoints(readings);
    final bestLabel = _bestPeriodLabel(chartPoints);
    final worstLabel = _worstPeriodLabel(chartPoints);

    final insight = _buildInsight(
      avg: avg,
      lowPercent: lowPercent,
      highPercent: highPercent,
      inRangePercent: inRangePercent,
      lowEpisodes: lowEpisodes,
      highEpisodes: highEpisodes,
      readings: readings,
    );

    return ReportStats(
      periodName: _periodTitle(),
      averageGlucose: avg,
      estimatedA1c: _estimatedA1c(overallAvg),
      minGlucose: minVal,
      maxGlucose: maxVal,
      totalReadings: total,
      lowPercent: lowPercent,
      inRangePercent: inRangePercent,
      highPercent: highPercent,
      lowEpisodes: lowEpisodes,
      highEpisodes: highEpisodes,
      bestLabel: bestLabel,
      worstLabel: worstLabel,
      insight: insight,
      chartPoints: chartPoints,
      confidence: _confidence(allReadings.length),
    );
  }

  double _overallAverageGlucose() {
    if (allReadings.isEmpty) return 0;

    final values = allReadings.map((e) => e.value).toList();
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _estimatedA1c(double avgGlucose) {
    return (avgGlucose + 46.7) / 28.7;
  }

  String _confidence(int readingsCount) {
    if (readingsCount < 15) return 'Low';
    if (readingsCount < 60) return 'Medium';
    return 'High';
  }

  int _countEpisodes(List<ReportReading> readings, String type) {
    final sorted = [...readings]..sort((a, b) => a.time.compareTo(b.time));

    int count = 0;
    bool inEpisode = false;

    for (final r in sorted) {
      final status = r.value < 70
          ? 'low'
          : r.value > 180
          ? 'high'
          : 'inRange';

      if (status == type && !inEpisode) {
        count++;
        inEpisode = true;
      }

      if (status != type) {
        inEpisode = false;
      }
    }

    return count;
  }

  List<ChartPoint> _buildChartPoints(List<ReportReading> readings) {
    if (selectedTab == 0) {
      return _weeklyChart(readings);
    }

    if (selectedTab == 1) {
      return _monthlyChart(readings);
    }

    return _yearlyChart(readings);
  }

  List<ChartPoint> _weeklyChart(List<ReportReading> readings) {
    final now = DateTime.now();
    final start = _dateOnly(now).subtract(const Duration(days: 6));
    final points = <ChartPoint>[];

    for (int i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final dayReadings = readings
          .where(
            (r) =>
                r.time.year == day.year &&
                r.time.month == day.month &&
                r.time.day == day.day,
          )
          .toList();

      final avg = _averageOrNull(dayReadings);
      points.add(ChartPoint(label: _shortDayName(day.weekday), value: avg));
    }

    return points;
  }

  List<ChartPoint> _monthlyChart(List<ReportReading> readings) {
    final points = <ChartPoint>[];
    final now = DateTime.now();

    for (int week = 1; week <= 4; week++) {
      final startDay = ((week - 1) * 7) + 1;
      final endDay = week == 4 ? 32 : startDay + 7;

      final weekReadings = readings.where((r) {
        return r.time.year == now.year &&
            r.time.month == now.month &&
            r.time.day >= startDay &&
            r.time.day < endDay;
      }).toList();

      final avg = _averageOrNull(weekReadings);

      points.add(ChartPoint(label: 'W$week', value: avg));
    }

    return points;
  }

  List<ChartPoint> _yearlyChart(List<ReportReading> readings) {
    final points = <ChartPoint>[];
    final now = DateTime.now();

    for (int month = 1; month <= 12; month++) {
      final monthReadings = readings.where((r) {
        return r.time.year == now.year && r.time.month == month;
      }).toList();

      final avg = _averageOrNull(monthReadings);

      points.add(ChartPoint(label: _shortMonthName(month), value: avg));
    }

    return points;
  }

  double? _averageOrNull(List<ReportReading> readings) {
    if (readings.isEmpty) return null;
    final values = readings.map((e) => e.value).toList();
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _bestPeriodLabel(List<ChartPoint> points) {
    final valid = points.where((p) => p.value != null).toList();
    if (valid.isEmpty) return '--';

    valid.sort((a, b) {
      final aDistance = (a.value! - 120).abs();
      final bDistance = (b.value! - 120).abs();
      return aDistance.compareTo(bDistance);
    });

    return valid.first.label;
  }

  String _worstPeriodLabel(List<ChartPoint> points) {
    final valid = points.where((p) => p.value != null).toList();
    if (valid.isEmpty) return '--';

    valid.sort((a, b) {
      final aScore = (a.value! - 120).abs();
      final bScore = (b.value! - 120).abs();
      return bScore.compareTo(aScore);
    });

    return valid.first.label;
  }

  String _buildInsight({
    required double avg,
    required int lowPercent,
    required int highPercent,
    required int inRangePercent,
    required int lowEpisodes,
    required int highEpisodes,
    required List<ReportReading> readings,
  }) {
    final mostHighTime = _mostCommonTime(readings, highOnly: true);
    final mostLowTime = _mostCommonTime(readings, lowOnly: true);

    if (lowEpisodes >= 3 || lowPercent >= 15) {
      return 'Repeated low glucose readings were noticed, especially around $mostLowTime. Rechecking patterns with your doctor is recommended.';
    }

    if (highEpisodes >= 3 || highPercent >= 30) {
      return 'High glucose readings were frequent, especially around $mostHighTime. Meal timing, carbs, or insulin timing may need review.';
    }

    if (inRangePercent >= 70) {
      return 'Your glucose was mostly stable during this period. Keep tracking regularly.';
    }

    if (avg > 180) {
      return 'Your average glucose is above target. More detailed review may help identify the reason.';
    }

    return 'Your report shows some variation. More readings will improve the accuracy of future reports.';
  }

  String _mostCommonTime(
    List<ReportReading> readings, {
    bool highOnly = false,
    bool lowOnly = false,
  }) {
    final buckets = {'morning': 0, 'afternoon': 0, 'evening': 0, 'night': 0};

    for (final r in readings) {
      if (highOnly && r.value <= 180) continue;
      if (lowOnly && r.value >= 70) continue;

      final h = r.time.hour;

      if (h >= 5 && h < 12) {
        buckets['morning'] = buckets['morning']! + 1;
      } else if (h >= 12 && h < 17) {
        buckets['afternoon'] = buckets['afternoon']! + 1;
      } else if (h >= 17 && h < 22) {
        buckets['evening'] = buckets['evening']! + 1;
      } else {
        buckets['night'] = buckets['night']! + 1;
      }
    }

    final sorted = buckets.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.first.value == 0) return 'different times';

    return sorted.first.key;
  }

  String _periodTitle() {
    if (selectedTab == 0) return 'Weekly Report';
    if (selectedTab == 1) return 'Monthly Report';
    return 'Yearly Report';
  }

  String _shortDayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }

  String _shortMonthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }

  String _valueText(double? value, {int digits = 0}) {
    if (value == null) return '--';
    return value.toStringAsFixed(digits);
  }

  Color _a1cColor(double? a1c) {
    if (a1c == null) return _green;
    if (a1c < 7) return _green;
    if (a1c < 8) return _orange;
    return _red;
  }

  Map<String, dynamic> _reportPayloadForAi(ReportStats stats) {
    return {
      'period': stats.periodName,
      'readingsCount': stats.totalReadings,
      'averageGlucose': stats.averageGlucose?.round(),
      'estimatedA1c': stats.estimatedA1c?.toStringAsFixed(1),
      'minGlucose': stats.minGlucose?.round(),
      'maxGlucose': stats.maxGlucose?.round(),
      'timeInRange': {
        'lowPercent': stats.lowPercent,
        'inRangePercent': stats.inRangePercent,
        'highPercent': stats.highPercent,
      },
      'episodes': {
        'lowEpisodes': stats.lowEpisodes,
        'highEpisodes': stats.highEpisodes,
      },
      'bestPeriod': stats.bestLabel,
      'mostUnstablePeriod': stats.worstLabel,
      'confidence': stats.confidence,
      'chart': stats.chartPoints
          .map((p) => {'label': p.label, 'averageGlucose': p.value?.round()})
          .toList(),
      'safetyInstruction':
          'Do not prescribe insulin doses or treatment changes. Only explain patterns and suggest contacting a doctor when needed.',
    };
  }

  Future<void> _generateAiInsight(ReportStats stats) async {
    if (isAiLoading) return;

    setState(() {
      isAiLoading = true;
      aiError = null;
      aiInsight = null;
    });

    try {
      final result = await AiReportApi.analyzeReport(
        report: _reportPayloadForAi(stats),
      );

      if (!mounted) return;

      setState(() {
        aiInsight = result;
        isAiLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        aiError = e.toString().replaceAll('Exception: ', '');
        isAiLoading = false;
      });
    }
  }

  String _pdfDateText(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _pdfPeriodText() {
    final now = DateTime.now();

    if (selectedTab == 0) {
      final from = _dateOnly(now).subtract(const Duration(days: 6));
      final to = _dateOnly(now);
      return '${_pdfDateText(from)} to ${_pdfDateText(to)}';
    }

    if (selectedTab == 1) {
      final month = now.month.toString().padLeft(2, '0');
      return '${now.year}-$month';
    }

    return now.year.toString();
  }

  String _safePdfText(dynamic value) {
    if (value == null) return '--';
    return value.toString();
  }

  Future<void> _exportReportPdf(ReportStats stats) async {
    try {
      final pdfBytes = await _buildReportPdf(stats);

      final fileName =
          'glucose_${stats.periodName.toLowerCase().replaceAll(' ', '_')}_${_pdfDateText(DateTime.now())}.pdf';

      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export PDF: $e')));
    }
  }

  Future<Uint8List> _buildReportPdf(ReportStats stats) async {
    final pdf = pw.Document();

    final generatedAt = _pdfDateText(DateTime.now());
    final periodText = _pdfPeriodText();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return [
            _pdfHeader(stats, generatedAt, periodText),
            pw.SizedBox(height: 18),
            _pdfA1cBox(stats),
            pw.SizedBox(height: 14),
            _pdfSectionTitle('Summary'),
            pw.SizedBox(height: 8),
            _pdfStatsGrid(stats),
            pw.SizedBox(height: 16),
            _pdfSectionTitle('Time in Range'),
            pw.SizedBox(height: 8),
            _pdfRangeBar(stats),
            pw.SizedBox(height: 8),
            _pdfRangeLegend(stats),
            pw.SizedBox(height: 16),
            _pdfSectionTitle('Chart Data'),
            pw.SizedBox(height: 8),
            _pdfChartTable(stats),
            pw.SizedBox(height: 16),
            _pdfSectionTitle('Details'),
            pw.SizedBox(height: 8),
            _pdfDetailsTable(stats),
            pw.SizedBox(height: 16),
            _pdfSectionTitle('Smart Insight'),
            pw.SizedBox(height: 8),
            _pdfTextBox(stats.insight),
            pw.SizedBox(height: 16),
            if (aiInsight != null) ...[
              _pdfSectionTitle('AI Analysis'),
              pw.SizedBox(height: 8),
              _pdfAiSection(),
              pw.SizedBox(height: 16),
            ],
            _pdfMedicalNote(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfHeader(
    ReportStats stats,
    String generatedAt,
    String periodText,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#185FA5'),
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Glucose Report',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  stats.periodName,
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 13,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Period: $periodText',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            'Generated: $generatedAt',
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfA1cBox(ReportStats stats) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#EAF6FF'),
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: PdfColor.fromHex('#CFE5FA')),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Estimated A1C',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#0C447C'),
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  '${_valueText(stats.estimatedA1c, digits: 1)}%',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#1D9E75'),
                    fontSize: 34,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Confidence',
                style: pw.TextStyle(
                  color: PdfColor.fromHex('#6F8EA8'),
                  fontSize: 10,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                stats.confidence,
                style: pw.TextStyle(
                  color: PdfColor.fromHex('#0C447C'),
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Based on ${stats.totalReadings} readings',
                style: pw.TextStyle(
                  color: PdfColor.fromHex('#6F8EA8'),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: PdfColor.fromHex('#0C447C'),
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _pdfStatsGrid(ReportStats stats) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#DCEEFF'), width: 1),
      children: [
        pw.TableRow(
          children: [
            _pdfStatCell(
              'Average',
              '${_valueText(stats.averageGlucose)} mg/dL',
            ),
            _pdfStatCell('Highest', '${_valueText(stats.maxGlucose)} mg/dL'),
          ],
        ),
        pw.TableRow(
          children: [
            _pdfStatCell('Lowest', '${_valueText(stats.minGlucose)} mg/dL'),
            _pdfStatCell('Readings', '${stats.totalReadings}'),
          ],
        ),
      ],
    );
  }

  pw.Widget _pdfStatCell(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: PdfColor.fromHex('#6F8EA8'),
              fontSize: 10,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: PdfColor.fromHex('#0C447C'),
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfRangeBar(ReportStats stats) {
    final total = stats.lowPercent + stats.inRangePercent + stats.highPercent;

    if (total == 0) {
      return pw.Container(height: 12, color: PdfColor.fromHex('#EEF7FF'));
    }

    return pw.Row(
      children: [
        _pdfRangeSegment(stats.lowPercent, PdfColor.fromHex('#E24B4A')),
        _pdfRangeSegment(stats.inRangePercent, PdfColor.fromHex('#1D9E75')),
        _pdfRangeSegment(stats.highPercent, PdfColor.fromHex('#EF9F27')),
      ],
    );
  }

  pw.Widget _pdfRangeSegment(int percent, PdfColor color) {
    return pw.Expanded(
      flex: percent == 0 ? 1 : percent,
      child: pw.Container(
        height: 14,
        color: percent == 0 ? PdfColor.fromHex('#EEF7FF') : color,
      ),
    );
  }

  pw.Widget _pdfRangeLegend(ReportStats stats) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _pdfLegendItem(
          'Low',
          '${stats.lowPercent}%',
          PdfColor.fromHex('#E24B4A'),
        ),
        _pdfLegendItem(
          'In Range',
          '${stats.inRangePercent}%',
          PdfColor.fromHex('#1D9E75'),
        ),
        _pdfLegendItem(
          'High',
          '${stats.highPercent}%',
          PdfColor.fromHex('#EF9F27'),
        ),
      ],
    );
  }

  pw.Widget _pdfLegendItem(String label, String value, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(width: 8, height: 8, color: color),
        pw.SizedBox(width: 5),
        pw.Text(
          '$label $value',
          style: pw.TextStyle(color: PdfColor.fromHex('#5F7F99'), fontSize: 10),
        ),
      ],
    );
  }

  pw.Widget _pdfChartTable(ReportStats stats) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#DCEEFF'), width: 1),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#EEF7FF')),
          children: [
            _pdfTableHeader('Period'),
            _pdfTableHeader('Average Glucose'),
          ],
        ),
        ...stats.chartPoints.map(
          (p) => pw.TableRow(
            children: [
              _pdfTableCell(p.label),
              _pdfTableCell(
                p.value == null ? '--' : '${p.value!.toStringAsFixed(0)} mg/dL',
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfDetailsTable(ReportStats stats) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#DCEEFF'), width: 1),
      children: [
        pw.TableRow(
          children: [
            _pdfTableCell('Low episodes'),
            _pdfTableCell('${stats.lowEpisodes}'),
          ],
        ),
        pw.TableRow(
          children: [
            _pdfTableCell('High episodes'),
            _pdfTableCell('${stats.highEpisodes}'),
          ],
        ),
        pw.TableRow(
          children: [
            _pdfTableCell('Best period'),
            _pdfTableCell(stats.bestLabel),
          ],
        ),
        pw.TableRow(
          children: [
            _pdfTableCell('Most unstable period'),
            _pdfTableCell(stats.worstLabel),
          ],
        ),
      ],
    );
  }

  pw.Widget _pdfTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColor.fromHex('#0C447C'),
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _pdfTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: PdfColor.fromHex('#5F7F99'), fontSize: 10.5),
      ),
    );
  }

  pw.Widget _pdfTextBox(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#EEF7FF'),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColor.fromHex('#D8EBFF')),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColor.fromHex('#5F7F99'),
          fontSize: 11,
          lineSpacing: 3,
        ),
      ),
    );
  }

  pw.Widget _pdfAiSection() {
    final risk = _safePdfText(aiInsight?['riskLevel']);
    final summary = _safePdfText(aiInsight?['summary']);
    final warning = _safePdfText(aiInsight?['warning']);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _pdfTextBox('Risk level: ${risk.toUpperCase()}\n\nSummary: $summary'),
        pw.SizedBox(height: 10),
        _pdfAiList('Patterns', aiInsight?['patterns']),
        _pdfAiList('Safe Suggestions', aiInsight?['safeSuggestions']),
        _pdfAiList('Questions for Doctor', aiInsight?['doctorQuestions']),
        if (warning != '--') ...[
          pw.SizedBox(height: 6),
          pw.Text(
            warning,
            style: pw.TextStyle(
              color: PdfColor.fromHex('#7A9AB5'),
              fontSize: 9.5,
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _pdfAiList(String title, dynamic items) {
    final list = items is List ? items : [];

    if (list.isEmpty) return pw.SizedBox();

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: PdfColor.fromHex('#0C447C'),
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          ...list.map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                '- ${item.toString()}',
                style: pw.TextStyle(
                  color: PdfColor.fromHex('#5F7F99'),
                  fontSize: 10.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfMedicalNote() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFF7E8'),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColor.fromHex('#F6D9A8')),
      ),
      child: pw.Text(
        'Medical note: Estimated A1C is calculated from glucose readings using the eAG/A1C formula. It is only an estimate and cannot replace a lab HbA1c test, your doctor, or medical advice. AI analysis is for explanation only and must not be used to change treatment or insulin doses.',
        style: pw.TextStyle(
          color: PdfColor.fromHex('#7A5A25'),
          fontSize: 10,
          lineSpacing: 3,
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final stats = _buildStats();

    final content = SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadReadings,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1000;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                isWide ? 28 : 16,
                widget.embedded ? 0 : 14,
                isWide ? 28 : 16,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 1360 : 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!widget.embedded) _buildHeader(),
                      if (!widget.embedded) const SizedBox(height: 14),

                      if (widget.embedded)
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Glucose Report',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _darkBlue,
                                ),
                              ),
                            ),
                            _circleButton(
                              icon: Icons.download_rounded,
                              onTap: () {
                                final stats = _buildStats();

                                if (stats.totalReadings == 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No readings available to export.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                _exportReportPdf(stats);
                              },
                            ),
                          ],
                        ),

                      if (widget.embedded) const SizedBox(height: 14),

                      _buildTabs(),
                      const SizedBox(height: 14),

                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 120),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (errorMessage != null)
                        _emptyCard(errorMessage!)
                      else if (stats.totalReadings == 0)
                        _emptyCard('No readings available for this period.')
                      else if (isWide)
                        _buildWideReportLayout(stats)
                      else
                        _buildMobileReportLayout(stats),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    if (widget.embedded) {
      return Container(color: _pageBg, child: content);
    }

    return Scaffold(backgroundColor: _pageBg, body: content);
  }

  Widget _buildMobileReportLayout(ReportStats stats) {
    return Column(
      children: [
        _buildA1cCard(stats),
        const SizedBox(height: 12),
        _buildSummaryGrid(stats, isWide: false),
        const SizedBox(height: 12),
        _buildRangeCard(stats),
        const SizedBox(height: 12),
        _buildChartCard(stats, isWide: false),
        const SizedBox(height: 12),
        _buildDetailsCard(stats),
        const SizedBox(height: 12),
        _buildInsightCard(stats),
        const SizedBox(height: 12),
        _buildAiAnalysisCard(stats),
        const SizedBox(height: 12),
        _buildNoteCard(),
      ],
    );
  }

  Widget _buildWideReportLayout(ReportStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildA1cCard(stats),
        const SizedBox(height: 12),
        _buildSummaryGrid(stats, isWide: true),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _buildRangeCard(stats),
                  const SizedBox(height: 12),
                  _buildDetailsCard(stats),
                  const SizedBox(height: 12),
                  _buildInsightCard(stats),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  _buildChartCard(stats, isWide: true),
                  const SizedBox(height: 12),
                  _buildAiAnalysisCard(stats),
                  const SizedBox(height: 12),
                  _buildNoteCard(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _circleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _darkBlue,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Track your glucose trends',
                style: TextStyle(fontSize: 13, color: Color(0xff378ADD)),
              ),
            ],
          ),
        ),
        _circleButton(
          icon: Icons.download_rounded,
          onTap: () {
            final stats = _buildStats();

            if (stats.totalReadings == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No readings available to export.'),
                ),
              );
              return;
            }

            _exportReportPdf(stats);
          },
        ),
      ],
    );
  }

  Widget _circleButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
        ),
        child: Icon(icon, size: 18, color: const Color(0xff378ADD)),
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Weekly', 'Monthly', 'Yearly'];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = selectedTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTab = index;
                  aiInsight = null;
                  aiError = null;
                  isAiLoading = false;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? _mainBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: selected ? Colors.white : _darkBlue,
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildA1cCard(ReportStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _mainBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _mainBlue.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.periodName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${_valueText(stats.estimatedA1c, digits: 1)}%',
                      style: TextStyle(
                        color: _a1cColor(stats.estimatedA1c),
                        fontSize: 36,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Estimated A1C',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Based on your entered glucose readings',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(ReportStats stats, {required bool isWide}) {
    final items = [
      {
        'title': 'Average',
        'value': '${_valueText(stats.averageGlucose)} mg/dL',
        'icon': Icons.show_chart_rounded,
        'color': _mainBlue,
      },
      {
        'title': 'Highest',
        'value': '${_valueText(stats.maxGlucose)} mg/dL',
        'icon': Icons.trending_up_rounded,
        'color': _red,
      },
      {
        'title': 'Lowest',
        'value': '${_valueText(stats.minGlucose)} mg/dL',
        'icon': Icons.trending_down_rounded,
        'color': _orange,
      },
      {
        'title': 'Readings',
        'value': '${stats.totalReadings}',
        'icon': Icons.format_list_numbered_rounded,
        'color': _green,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = isWide ? 4 : 2;
        const spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: _statCard(
                title: item['title'] as String,
                value: item['value'] as String,
                icon: item['icon'] as IconData,
                color: item['color'] as Color,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(color: Color(0xff7A9AB5), fontSize: 12),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  color: _darkBlue,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeCard(ReportStats stats) {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.pie_chart_outline_rounded,
            title: 'Time in Range',
            subtitle: 'Low, target, and high readings',
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                _rangePart(stats.lowPercent, _red),
                _rangePart(stats.inRangePercent, _green),
                _rangePart(stats.highPercent, _orange),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _rangeLabel('Low', '${stats.lowPercent}%', _red)),
              Expanded(
                child: _rangeLabel(
                  'In Range',
                  '${stats.inRangePercent}%',
                  _green,
                ),
              ),
              Expanded(
                child: _rangeLabel('High', '${stats.highPercent}%', _orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangePart(int percent, Color color) {
    return Expanded(
      flex: percent == 0 ? 1 : percent,
      child: Container(
        height: 14,
        color: percent == 0 ? Colors.grey.withOpacity(0.12) : color,
      ),
    );
  }

  Widget _rangeLabel(String title, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            '$title $value',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xff5F7F99),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(ReportStats stats, {required bool isWide}) {
    final validPoints = stats.chartPoints
        .where((p) => p.value != null)
        .toList();

    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.bar_chart_rounded,
            title: selectedTab == 0
                ? 'Daily Average'
                : selectedTab == 1
                ? 'Weekly Comparison'
                : 'Monthly Trend',
            subtitle: 'Average glucose by period',
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: isWide ? 360 : 210,
            child: validPoints.isEmpty
                ? const Center(
                    child: Text(
                      'Not enough data for chart.',
                      style: TextStyle(color: Color(0xff7A9AB5)),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: _chartMaxY(stats.chartPoints),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 50,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.grey.withOpacity(0.13),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: 100,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox();
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Color(0xff7A9AB5),
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
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
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();

                              if (index < 0 ||
                                  index >= stats.chartPoints.length) {
                                return const SizedBox();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  stats.chartPoints[index].label,
                                  style: TextStyle(
                                    color: const Color(0xff7A9AB5),
                                    fontSize: isWide ? 11 : 9.5,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipRoundedRadius: 12,
                          getTooltipColor: (_) => Colors.white,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final point = stats.chartPoints[group.x.toInt()];
                            if (point.value == null) return null;

                            return BarTooltipItem(
                              '${point.label}\n${point.value!.toStringAsFixed(0)} mg/dL',
                              const TextStyle(
                                color: _darkBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      barGroups: List.generate(stats.chartPoints.length, (i) {
                        final point = stats.chartPoints[i];
                        final value = point.value ?? 0;

                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: value,
                              width: isWide
                                  ? selectedTab == 2
                                        ? 18
                                        : 26
                                  : selectedTab == 2
                                  ? 8
                                  : 16,
                              borderRadius: BorderRadius.circular(8),
                              color: _barColor(value),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: _chartMaxY(stats.chartPoints),
                                color: _softBlue,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _chartMaxY(List<ChartPoint> points) {
    final values = points.where((p) => p.value != null).map((p) => p.value!);
    if (values.isEmpty) return 300;

    final maxVal = values.reduce(math.max);
    return math.max(250, ((maxVal + 50) / 50).ceil() * 50).toDouble();
  }

  Color _barColor(double value) {
    if (value == 0) return Colors.grey.shade300;
    if (value < 70 || value > 180) return _red;
    if (value > 140) return _orange;
    return _green;
  }

  Widget _buildDetailsCard(ReportStats stats) {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.fact_check_outlined,
            title: 'Details',
            subtitle: 'Episodes and best/worst period',
          ),
          const SizedBox(height: 12),
          _detailRow('Low episodes', '${stats.lowEpisodes}'),
          _detailRow('High episodes', '${stats.highEpisodes}'),
          _detailRow(
            selectedTab == 0
                ? 'Best day'
                : selectedTab == 1
                ? 'Best week'
                : 'Best month',
            stats.bestLabel,
          ),
          _detailRow(
            selectedTab == 0
                ? 'Most unstable day'
                : selectedTab == 1
                ? 'Most unstable week'
                : 'Most unstable month',
            stats.worstLabel,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Color(0xff5F7F99), fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _darkBlue,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(ReportStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softBlue,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffD8EBFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _softBlue2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: _mainBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Insight',
                  style: TextStyle(
                    color: _darkBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stats.insight,
                  style: const TextStyle(
                    color: Color(0xff5F7F99),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAnalysisCard(ReportStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.auto_awesome_rounded,
            title: 'AI Analysis',
            subtitle: 'Safe pattern explanation from your report',
          ),
          const SizedBox(height: 14),
          if (aiInsight == null && aiError == null && !isAiLoading) ...[
            const Text(
              'Generate an AI explanation for this report. The AI will explain patterns, possible risks, and doctor questions without changing treatment.',
              style: TextStyle(
                color: Color(0xff5F7F99),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => _generateAiInsight(stats),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Generate AI Analysis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mainBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
          if (isAiLoading) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Analyzing glucose patterns...',
                style: TextStyle(color: Color(0xff7A9AB5), fontSize: 12),
              ),
            ),
          ],
          if (aiError != null) ...[
            Text(
              aiError!,
              style: const TextStyle(color: Colors.red, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => _generateAiInsight(stats),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mainBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ),
          ],
          if (aiInsight != null) ...[
            _aiRiskBadge(aiInsight!['riskLevel']?.toString() ?? 'medium'),
            const SizedBox(height: 12),
            _aiTextBlock(
              title: 'Summary',
              text: aiInsight!['summary']?.toString() ?? '--',
            ),
            _aiListBlock(title: 'Patterns', items: aiInsight!['patterns']),
            _aiListBlock(
              title: 'Safe Suggestions',
              items: aiInsight!['safeSuggestions'],
            ),
            _aiListBlock(
              title: 'Questions for Doctor',
              items: aiInsight!['doctorQuestions'],
            ),
            const SizedBox(height: 8),
            Text(
              aiInsight!['warning']?.toString() ??
                  'AI analysis is not medical advice.',
              style: const TextStyle(
                color: Color(0xff7A9AB5),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _aiRiskBadge(String riskLevel) {
    Color color;

    if (riskLevel.toLowerCase() == 'low') {
      color = _green;
    } else if (riskLevel.toLowerCase() == 'high') {
      color = _red;
    } else {
      color = _orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Risk level: ${riskLevel.toUpperCase()}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _aiTextBlock({required String title, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _darkBlue,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xff5F7F99),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiListBlock({required String title, required dynamic items}) {
    final list = items is List ? items : [];

    if (list.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _darkBlue,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ...list.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: _mainBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: const TextStyle(
                        color: Color(0xff5F7F99),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
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

  Widget _buildNoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: const Text(
        'Estimated A1C is calculated from your glucose readings using the eAG/A1C formula. It is only an estimate and cannot replace a lab HbA1c test, your doctor, or medical advice.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xff7A9AB5), fontSize: 11.5, height: 1.4),
      ),
    );
  }

  Widget _whiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _softBlue2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _mainBlue, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _darkBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xff7A9AB5),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 80),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.insert_chart_outlined_rounded,
            color: _mainBlue,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _darkBlue,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ReportReading {
  final String? id;
  final double value;
  final DateTime time;
  final DateTime? createdAt;

  ReportReading({
    this.id,
    required this.value,
    required this.time,
    this.createdAt,
  });

  factory ReportReading.fromApiJson(Map<String, dynamic> json) {
    return ReportReading(
      id: json['_id']?.toString(),
      value: (json['value'] as num).toDouble(),
      time: DateTime.parse(json['readingTime']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class ChartPoint {
  final String label;
  final double? value;

  ChartPoint({required this.label, required this.value});
}

class ReportStats {
  final String periodName;
  final double? averageGlucose;
  final double? estimatedA1c;
  final double? minGlucose;
  final double? maxGlucose;
  final int totalReadings;
  final int lowPercent;
  final int inRangePercent;
  final int highPercent;
  final int lowEpisodes;
  final int highEpisodes;
  final String bestLabel;
  final String worstLabel;
  final String insight;
  final List<ChartPoint> chartPoints;
  final String confidence;

  ReportStats({
    required this.periodName,
    required this.averageGlucose,
    required this.estimatedA1c,
    required this.minGlucose,
    required this.maxGlucose,
    required this.totalReadings,
    required this.lowPercent,
    required this.inRangePercent,
    required this.highPercent,
    required this.lowEpisodes,
    required this.highEpisodes,
    required this.bestLabel,
    required this.worstLabel,
    required this.insight,
    required this.chartPoints,
    required this.confidence,
  });

  factory ReportStats.empty({required String periodName}) {
    return ReportStats(
      periodName: periodName,
      averageGlucose: null,
      estimatedA1c: null,
      minGlucose: null,
      maxGlucose: null,
      totalReadings: 0,
      lowPercent: 0,
      inRangePercent: 0,
      highPercent: 0,
      lowEpisodes: 0,
      highEpisodes: 0,
      bestLabel: '--',
      worstLabel: '--',
      insight: 'Not enough readings to generate insights.',
      chartPoints: [],
      confidence: 'Low',
    );
  }
}
