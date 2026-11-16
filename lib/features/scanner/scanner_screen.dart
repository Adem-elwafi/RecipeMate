import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';

/// Camera barcode scanner screen (Owner: Adem).
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  final TextEditingController _manualInputController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode != null && barcode.isNotEmpty) {
      _isProcessing = true;
      context.pushReplacement('/product/$barcode');
    }
  }

  void _openManualEntry() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saisie manuelle'),
        content: TextField(
          controller: _manualInputController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Code-barres (ex. 3017620422003)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = _manualInputController.text.trim();
              Navigator.pop(context);
              if (code.isNotEmpty) {
                context.pushReplacement('/product/$code');
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Scanner un produit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: _controller.toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            onPressed: _controller.switchCamera,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 64,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Caméra indisponible ou permission requise',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.subtitle.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _openManualEntry,
                        child: const Text('Saisir le code manuellement'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Viewfinder Frame Overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.sage, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 2,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Prompt & Manual Button
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Text(
                  'Placez le code-barres dans le cadre',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _openManualEntry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    backgroundColor: Colors.black45,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Saisie manuelle'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
