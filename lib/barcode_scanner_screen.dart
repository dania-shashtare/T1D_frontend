import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _isScanned = false;

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
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleBarcodeCapture(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      debugPrint("Detected barcode: $code");

      if (code != null && code.isNotEmpty) {
        _isScanned = true;
        Navigator.pop(context, code);
        return;
      }
    }
  }

  Future<void> _showManualBarcodeDialog() async {
    final TextEditingController barcodeController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Enter Barcode"),
          content: TextField(
            controller: barcodeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Example: 7290016004187",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final code = barcodeController.text.trim();
                if (code.isNotEmpty) {
                  Navigator.pop(context, code);
                }
              },
              child: const Text("Continue"),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEAF6FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xffEAF6FF),
        foregroundColor: const Color(0xff17466E),
        title: const Text(
          "Scan Barcode",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xff17466E),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Place the barcode inside the frame to scan your food item",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xff7A9AB5)),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: controller,
                        onDetect: _handleBarcodeCapture,
                      ),
                      Center(
                        child: Container(
                          width: 300,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xff7EC8FF),
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showManualBarcodeDialog,
                icon: const Icon(Icons.keyboard_alt_rounded),
                label: const Text("Enter barcode manually"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff2F7DB7),
                  side: const BorderSide(color: Color(0xff7EC8FF)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xff2F7DB7)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "This feature works best with packaged food products. Hold the barcode close and keep it clear inside the frame.",
                      style: TextStyle(color: Color(0xff5E87A8), fontSize: 13),
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
