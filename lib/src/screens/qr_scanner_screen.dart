import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.front,
    detectionSpeed: DetectionSpeed.normal,
  );
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final code = barcode.rawValue!.trim();
    if (code.isEmpty) return;

    setState(() => _scanned = true);
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Em landscape, width > height. A câmera frontal entrega em portrait,
    // então precisamos rotacionar e escalar para preencher.
    final isLandscape = size.width > size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera com correção de orientação para landscape
          if (isLandscape)
            Center(
              child: RotatedBox(
                quarterTurns: 3, // 270° = rotaciona para landscape
                child: SizedBox(
                  // Após rotacionar, troca width<->height para manter aspect ratio
                  width: size.height,
                  height: size.width,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: size.height,
                      height: size.width,
                      child: MobileScanner(
                        controller: _controller,
                        onDetect: _onDetect,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              fit: BoxFit.cover,
            ),

          // Overlay escuro com recorte central
          const _ScannerOverlay(),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(null),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(Icons.close_rounded, size: 24, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Escanear Comanda',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Aponte a câmera para o QR Code da comanda',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom instruction
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, size: 20, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Aguardando leitura do QR Code...',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanSize = constraints.maxHeight * 0.55;
        final left = (constraints.maxWidth - scanSize) / 2;
        final top = (constraints.maxHeight - scanSize) / 2;

        return Stack(
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: scanSize,
                      height: scanSize,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Container(
                width: scanSize,
                height: scanSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accent, width: 3),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
