import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanned = false;
  bool _torchEnabled = false;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  final MobileScannerController controller = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    controller.dispose();
    super.dispose();
  }

  void _handleBarcodeCapture(BarcodeCapture capture) {
    if (_isScanned) return;
    for (final barcode in capture.barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _isScanned = true;
        Navigator.pop(context, code);
        return;
      }
    }
  }

  void _toggleTorch() {
    setState(() => _torchEnabled = !_torchEnabled);
    controller.toggleTorch();
  }

  void _showManualBarcodeSheet() {
    final TextEditingController barcodeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xffC8DDEC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter barcode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xff0C447C)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Type the barcode number from the package',
                style: TextStyle(fontSize: 13, color: Color(0xff7A9AB5)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: barcodeController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 18,
                  letterSpacing: 1.5,
                  color: Color(0xff0C447C),
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 7290016004187',
                  hintStyle: const TextStyle(
                    fontSize: 15,
                    letterSpacing: 0,
                    color: Color(0xffB5D4F4),
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: const Color(0xffF5FAFE),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xffB5D4F4), width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xffB5D4F4), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xff378ADD), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xff7A9AB5),
                        side: const BorderSide(color: Color(0xffB5D4F4), width: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: const Color(0xffF5FAFE),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        final code = barcodeController.text.trim();
                        if (code.isNotEmpty) {
                          Navigator.pop(context);
                          Navigator.pop(context, code);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff185FA5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEAF6FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xffEAF6FF),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Color(0xff0C447C), size: 18),
          ),
        ),
        title: const Text(
          'Scan barcode',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Color(0xff0C447C)),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Place the barcode inside the frame to scan your food item',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xff7A9AB5)),
            ),
          ),
          const SizedBox(height: 16),

          // Camera area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: controller,
                        onDetect: _handleBarcodeCapture,
                      ),

                      // Dark overlay outside frame
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ScanOverlayPainter(),
                        ),
                      ),

                      // Scan frame with animated line
                      Center(
                        child: SizedBox(
                          width: 260,
                          height: 110,
                          child: Stack(
                            children: [
                              CustomPaint(
                                size: const Size(260, 110),
                                painter: _CornerFramePainter(),
                              ),
                              AnimatedBuilder(
                                animation: _scanLineAnimation,
                                builder: (_, __) => Positioned(
                                  top: 8 + (_scanLineAnimation.value * 86),
                                  left: 8,
                                  right: 8,
                                  child: Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: const Color(0xff7EC8FF).withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Flash button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: _toggleTorch,
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: _torchEnabled
                                  ? const Color(0xff7EC8FF).withOpacity(0.25)
                                  : Colors.white.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _torchEnabled
                                    ? const Color(0xff7EC8FF).withOpacity(0.6)
                                    : Colors.white.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Icon(
                              _torchEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                              color: _torchEnabled ? const Color(0xff7EC8FF) : Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      // Bottom hint
                      Positioned(
                        bottom: 14,
                        left: 0, right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Align barcode with the frame',
                              style: TextStyle(fontSize: 11, color: Colors.white60),
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

          const SizedBox(height: 14),

          // Manual entry button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _showManualBarcodeSheet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xffB5D4F4), width: 1.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.keyboard_alt_rounded, size: 18, color: Color(0xff185FA5)),
                    SizedBox(width: 8),
                    Text(
                      'Enter barcode manually',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xff185FA5)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Info card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xffE6F1FB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xff185FA5)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Works best with packaged food products. Hold the barcode close and keep it clear inside the frame.',
                      style: TextStyle(fontSize: 12, color: Color(0xff5E87A8), height: 1.5),
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
}

class _CornerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xff7EC8FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const r = 8.0;
    const len = 22.0;

    // Top-left
    canvas.drawLine(const Offset(0, len + r), Offset(0, r), paint);
    canvas.drawArc(const Rect.fromLTWH(0, 0, r * 2, r * 2), 3.14, 1.57, false, paint);
    canvas.drawLine(Offset(r, 0), Offset(len + r, 0), paint);

    // Top-right
    canvas.drawLine(Offset(size.width - len - r, 0), Offset(size.width - r, 0), paint);
    canvas.drawArc(Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2), -1.57, 1.57, false, paint);
    canvas.drawLine(Offset(size.width, r), Offset(size.width, len + r), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height - len - r), Offset(0, size.height - r), paint);
    canvas.drawArc(Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2), 1.57, 1.57, false, paint);
    canvas.drawLine(Offset(r, size.height), Offset(len + r, size.height), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - len - r, size.height), Offset(size.width - r, size.height), paint);
    canvas.drawArc(Rect.fromLTWH(size.width - r * 2, size.height - r * 2, r * 2, r * 2), 0, 1.57, false, paint);
    canvas.drawLine(Offset(size.width, size.height - r), Offset(size.width, size.height - len - r), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.45);
    final frameW = 260.0;
    final frameH = 110.0;
    final left = (size.width - frameW) / 2;
    final top = (size.height - frameH) / 2;
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, frameW, frameH),
      const Radius.circular(8),
    );
    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutPath = Path()..addRRect(frameRect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, cutPath),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}