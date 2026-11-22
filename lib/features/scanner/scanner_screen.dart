import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/features/product/models/scanned_product.dart';
import 'package:recipemate/features/product/providers/product_provider.dart';
import 'package:recipemate/features/product/services/open_food_facts_service.dart';
import 'package:recipemate/shared/widgets/app_buttons.dart';
import 'package:recipemate/shared/widgets/app_text_field.dart';

/// Full-screen barcode scanner with live camera preview (when available),
/// simulated fallback, animated laser viewfinder, detected product sheet,
/// and manual EAN entry modal.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key, this.useLiveCamera = true});

  /// Enables native `MobileScanner` camera preview on Android and iOS.
  /// Pass `false` in widget tests or simulated environments.
  final bool useLiveCamera;

  @override
  ConsumerState<ScannerScreen> createState() => ScannerScreenState();
}

/// State for [ScannerScreen], exposed for widget testing of barcode detection.
class ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _scanDebounceWindow = Duration(seconds: 3);

  late final AnimationController _laserController;
  late final Animation<double> _laserAnimation;

  MobileScannerController? _controller;
  late ScannedProduct _detectedProduct;
  bool _torchOn = false;
  bool _isLoadingBarcode = false;
  String? _lastScannedBarcode;
  DateTime? _lastScanTimestamp;

  bool get _shouldUseLiveCamera =>
      widget.useLiveCamera &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _laserAnimation = _laserController.drive(
      CurveTween(curve: Curves.easeInOut),
    );
    _detectedProduct = OpenFoodFactsService.demoProducts.first;

    if (_shouldUseLiveCamera) {
      _controller = MobileScannerController();
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    unawaited(_controller?.dispose());
    super.dispose();
  }

  void _closeScanner() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/fridge');
    }
  }

  void _toggleTorch() {
    final controller = _controller;
    if (controller != null) {
      if (controller.value.isRunning &&
          controller.value.torchState != TorchState.unavailable) {
        unawaited(controller.toggleTorch());
        setState(() {
          _torchOn = !_torchOn;
        });
      }
      return;
    }

    setState(() {
      _torchOn = !_torchOn;
    });
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    unawaited(handleBarcodeCapture(capture));
  }

  /// Processes a detected [BarcodeCapture], debouncing duplicate frames and
  /// resolving product information via Open Food Facts.
  @visibleForTesting
  Future<void> handleBarcodeCapture(BarcodeCapture capture) async {
    String? code;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        code = raw;
        break;
      }
    }

    if (code == null || _isLoadingBarcode) {
      return;
    }

    final now = DateTime.now();
    if (_lastScannedBarcode == code &&
        _lastScanTimestamp != null &&
        now.difference(_lastScanTimestamp!) < _scanDebounceWindow) {
      return;
    }

    _lastScannedBarcode = code;
    _lastScanTimestamp = now;

    setState(() {
      _isLoadingBarcode = true;
    });

    try {
      final product = await ref
          .read(openFoodFactsServiceProvider)
          .fetchProductByBarcode(code);
      if (!mounted) {
        return;
      }
      setState(() {
        _detectedProduct = product;
        _isLoadingBarcode = false;
      });
    } on ProductNotFoundException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingBarcode = false;
      });
      _showErrorSnackBar(error.message);
    } on Exception {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingBarcode = false;
      });
      _showErrorSnackBar(
        'Impossible de récupérer les informations du produit.',
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _openProductDetails(String barcode) {
    unawaited(context.push('/product/$barcode'));
  }

  Future<void> _showManualBarcodeSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _ManualBarcodeSheet(
        onSubmitCode: (code) {
          Navigator.of(sheetContext).pop();
          if (!mounted) {
            return;
          }
          _openProductDetails(code);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          final viewfinderWidth = math.min(
            300.0,
            math.max(200.0, screenWidth - 40),
          );
          final topBarBottom = mediaPadding.top + 12.0 + 46.0;
          final estimatedSheetHeight = 228.0 + mediaPadding.bottom;
          final sheetTop = screenHeight - estimatedSheetHeight;
          final availableMiddle = math.max(140.0, sheetTop - topBarBottom);
          final viewfinderHeight = math.min(170.0, availableMiddle * 0.56);
          const instructionReserve = 86.0;

          final idealViewfinderTop =
              topBarBottom +
              instructionReserve +
              math.max(
                0.0,
                (availableMiddle - instructionReserve - viewfinderHeight) / 2,
              );
          final maxViewfinderTop = math.max(
            topBarBottom + 8.0,
            sheetTop - viewfinderHeight - 16.0,
          );
          final viewfinderTop = idealViewfinderTop.clamp(
            topBarBottom + 8.0,
            maxViewfinderTop,
          );

          final viewfinderRect = Rect.fromLTWH(
            (screenWidth - viewfinderWidth) / 2,
            viewfinderTop,
            viewfinderWidth,
            viewfinderHeight,
          );

          return Stack(
            children: [
              // 1. Background / Camera Layer
              Positioned.fill(
                child: _shouldUseLiveCamera
                    ? MobileScanner(
                        controller: _controller,
                        onDetect: _onBarcodeDetected,
                        placeholderBuilder: (context, child) =>
                            _SimulatedScannerBackground(
                              viewfinderTop: viewfinderRect.top,
                            ),
                        errorBuilder:
                            (
                              BuildContext context,
                              MobileScannerException error,
                              Widget? child,
                            ) {
                              return _SimulatedScannerBackground(
                                viewfinderTop: viewfinderRect.top,
                              );
                            },
                      )
                    : _SimulatedScannerBackground(
                        viewfinderTop: viewfinderRect.top,
                      ),
              ),

              // 2. Dark Cutout Mask
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ScannerOverlayPainter(
                      cutoutRect: viewfinderRect,
                      borderRadius: 16,
                    ),
                  ),
                ),
              ),

              // 3. Centered Viewfinder Frame
              Positioned.fromRect(
                rect: viewfinderRect,
                child: IgnorePointer(
                  child: _ViewfinderFrame(
                    laserAnimation: _laserAnimation,
                    frameHeight: viewfinderRect.height,
                  ),
                ),
              ),

              // 4. Instruction Block above viewfinder
              Positioned(
                left: 20,
                right: 20,
                top: topBarBottom + 6,
                bottom: screenHeight - viewfinderRect.top + 18,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: math.max(0.0, screenWidth - 40),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Scannez le code-barres d'un produit",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Centrez le code dans le cadre, il sera détecté automatiquement.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.35,
                              color: AppColors.scannerHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 5. Top Action Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _ScannerTopBar(
                      torchOn: _torchOn,
                      onClose: _closeScanner,
                      onToggleTorch: _toggleTorch,
                    ),
                  ),
                ),
              ),

              // 6. Bottom Sheet Overlay
              Align(
                alignment: Alignment.bottomCenter,
                child: _DetectedProductSheet(
                  product: _detectedProduct,
                  isLoading: _isLoadingBarcode,
                  bottomSafePadding: mediaPadding.bottom,
                  onTapProduct: () =>
                      _openProductDetails(_detectedProduct.barcode),
                  onManualEntry: _showManualBarcodeSheet,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SimulatedScannerBackground extends StatelessWidget {
  const _SimulatedScannerBackground({required this.viewfinderTop});

  static const List<double> _barcodeWidths = <double>[
    3,
    1,
    4,
    2,
    1,
    3,
    2,
    4,
    1,
    3,
    1,
    2,
    4,
    1,
    3,
    2,
    1,
    4,
    2,
    3,
    1,
    2,
    4,
    1,
    3,
  ];

  final double viewfinderTop;

  @override
  Widget build(BuildContext context) {
    final cardTop = math.max(72.0, viewfinderTop - 90.0);

    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 0.9,
            colors: <Color>[
              AppColors.scannerMockBgMid,
              AppColors.scannerMockBgDark,
              AppColors.darkBackground,
            ],
            stops: <double>[0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: cardTop,
              child: Opacity(
                opacity: 0.8,
                child: Transform.rotate(
                  angle: -0.07,
                  child: Container(
                    width: 200,
                    height: 300,
                    decoration: BoxDecoration(
                      color: AppColors.scannerMockCard,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 60,
                          offset: const Offset(0, 30),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(height: 70, color: AppColors.primary),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 14,
                                      width: 120,
                                      decoration: BoxDecoration(
                                        color: AppColors.macroSalt,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 10,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: AppColors.scannerMockBar,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            left: 30,
                            right: 30,
                            bottom: 34,
                            child: Container(
                              height: 60,
                              color: AppColors.card,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (
                                    var i = 0;
                                    i < _barcodeWidths.length;
                                    i++
                                  ) ...[
                                    Container(
                                      width: _barcodeWidths[i],
                                      color: AppColors.darkBackground,
                                    ),
                                    if (i < _barcodeWidths.length - 1)
                                      const SizedBox(width: 2),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  const _ScannerOverlayPainter({
    required this.cutoutRect,
    required this.borderRadius,
  });

  final Rect cutoutRect;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(
        RRect.fromRectAndRadius(cutoutRect, Radius.circular(borderRadius)),
      );

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter oldDelegate) {
    return oldDelegate.cutoutRect != cutoutRect ||
        oldDelegate.borderRadius != borderRadius;
  }
}

class _ViewfinderFrame extends StatelessWidget {
  const _ViewfinderFrame({
    required this.laserAnimation,
    required this.frameHeight,
  });

  final Animation<double> laserAnimation;
  final double frameHeight;

  @override
  Widget build(BuildContext context) {
    final minTop = math.min(12.0, frameHeight * 0.1);
    final maxTop = math.max(minTop, frameHeight - 24.0);

    return Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _CornerBracketsPainter()),
        ),
        AnimatedBuilder(
          animation: laserAnimation,
          builder: (context, child) {
            final top = minTop + (maxTop - minTop) * laserAnimation.value;
            return Positioned(left: 14, right: 14, top: top, child: child!);
          },
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.orangeAccent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orangeAccent.withValues(alpha: 0.7),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  const _CornerBracketsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 4.0;
    const arm = 36.0;
    const outerRadius = 16.0;
    const halfStroke = strokeWidth / 2;
    const arcRadius = Radius.circular(outerRadius - halfStroke);

    final paint = Paint()
      ..color = AppColors.sage
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final path = Path()
      // Top-left
      ..moveTo(halfStroke, arm)
      ..lineTo(halfStroke, outerRadius)
      ..arcToPoint(const Offset(outerRadius, halfStroke), radius: arcRadius)
      ..lineTo(arm, halfStroke)
      // Top-right
      ..moveTo(size.width - arm, halfStroke)
      ..lineTo(size.width - outerRadius, halfStroke)
      ..arcToPoint(
        Offset(size.width - halfStroke, outerRadius),
        radius: arcRadius,
      )
      ..lineTo(size.width - halfStroke, arm)
      // Bottom-left
      ..moveTo(halfStroke, size.height - arm)
      ..lineTo(halfStroke, size.height - outerRadius)
      ..arcToPoint(
        Offset(outerRadius, size.height - halfStroke),
        radius: arcRadius,
        clockwise: false,
      )
      ..lineTo(arm, size.height - halfStroke)
      // Bottom-right
      ..moveTo(size.width - arm, size.height - halfStroke)
      ..lineTo(size.width - outerRadius, size.height - halfStroke)
      ..arcToPoint(
        Offset(size.width - halfStroke, size.height - outerRadius),
        radius: arcRadius,
      )
      ..lineTo(size.width - halfStroke, size.height - arm);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter oldDelegate) => false;
}

class _ScannerTopBar extends StatelessWidget {
  const _ScannerTopBar({
    required this.torchOn,
    required this.onClose,
    required this.onToggleTorch,
  });

  final bool torchOn;
  final VoidCallback onClose;
  final VoidCallback onToggleTorch;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Semantics(
          button: true,
          label: 'Fermer',
          child: Tooltip(
            message: 'Fermer',
            child: Material(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: onClose,
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Scanner',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          toggled: torchOn,
          label: 'Lampe torche',
          child: Tooltip(
            message: 'Lampe torche',
            child: Material(
              color: torchOn
                  ? AppColors.orangeAccent
                  : Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: onToggleTorch,
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    torchOn ? Icons.flash_on_rounded : Icons.bolt_rounded,
                    color: torchOn ? AppColors.darkBackground : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetectedProductSheet extends StatelessWidget {
  const _DetectedProductSheet({
    required this.product,
    required this.isLoading,
    required this.bottomSafePadding,
    required this.onTapProduct,
    required this.onManualEntry,
  });

  final ScannedProduct product;
  final bool isLoading;
  final double bottomSafePadding;
  final VoidCallback onTapProduct;
  final VoidCallback onManualEntry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 28 + bottomSafePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.sheetHandle,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _DetectedProductCard(
            product: product,
            isLoading: isLoading,
            onTap: onTapProduct,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: onManualEntry,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(
                  color: AppColors.outlineMuted,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                'Saisir le code manuellement',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Données produits : Open Food Facts',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectedProductCard extends StatelessWidget {
  const _DetectedProductCard({
    required this.product,
    required this.isLoading,
    required this.onTap,
  });

  final ScannedProduct product;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _ProductThumbnail(imageUrl: product.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            isLoading
                                ? 'Recherche en cours...'
                                : 'Produit détecté',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tonalGreenText,
                            ),
                          ),
                        ),
                        if (isLoading) ...[
                          const SizedBox(width: 6),
                          const SizedBox(
                            width: 11,
                            height: 11,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.tonalGreenText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.brand} · ${product.quantityLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _NutriScoreBadge(grade: product.nutriScoreGrade),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          url,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const _FallbackProductThumbnail(),
        ),
      );
    }
    return const _FallbackProductThumbnail();
  }
}

class _FallbackProductThumbnail extends StatelessWidget {
  const _FallbackProductThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.freshBadgeBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: AppColors.tonalGreenText,
        size: 24,
      ),
    );
  }
}

class _NutriScoreBadge extends StatelessWidget {
  const _NutriScoreBadge({required this.grade, this.size = 34});

  final String grade;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = _styleForGrade(grade);

    return Semantics(
      label: style.semanticsLabel,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(size <= 24 ? 7 : 9),
        ),
        child: Text(
          style.letter,
          style: GoogleFonts.poppins(
            fontSize: size <= 24 ? 12 : 16,
            fontWeight: FontWeight.w700,
            height: 1,
            color: style.foreground,
          ),
        ),
      ),
    );
  }

  static ({
    String letter,
    Color background,
    Color foreground,
    String semanticsLabel,
  })
  _styleForGrade(String rawGrade) {
    return switch (rawGrade.toLowerCase()) {
      'a' => (
        letter: 'A',
        background: AppColors.nutriScoreA,
        foreground: Colors.white,
        semanticsLabel: 'Nutri-Score A',
      ),
      'b' => (
        letter: 'B',
        background: AppColors.nutriScoreB,
        foreground: Colors.white,
        semanticsLabel: 'Nutri-Score B',
      ),
      'c' => (
        letter: 'C',
        background: AppColors.nutriScoreC,
        foreground: AppColors.textPrimary,
        semanticsLabel: 'Nutri-Score C',
      ),
      'd' => (
        letter: 'D',
        background: AppColors.nutriScoreD,
        foreground: Colors.white,
        semanticsLabel: 'Nutri-Score D',
      ),
      'e' => (
        letter: 'E',
        background: AppColors.nutriScoreE,
        foreground: Colors.white,
        semanticsLabel: 'Nutri-Score E',
      ),
      _ => (
        letter: '?',
        background: AppColors.neutralBadgeBg,
        foreground: AppColors.textSecondary,
        semanticsLabel: 'Nutri-Score non renseigné',
      ),
    };
  }
}

class _ManualBarcodeSheet extends StatefulWidget {
  const _ManualBarcodeSheet({required this.onSubmitCode});

  final ValueChanged<String> onSubmitCode;

  @override
  State<_ManualBarcodeSheet> createState() => _ManualBarcodeSheetState();
}

class _ManualBarcodeSheetState extends State<_ManualBarcodeSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _barcodeController = TextEditingController();

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmitCode(_barcodeController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.sheetHandle,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Saisir un code-barres',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Entrez le numéro EAN imprimé sous le code-barres du produit.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _barcodeController,
                  hintText: 'Ex : 3760123456789',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.search,
                  prefixIcon: const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppColors.textSecondary,
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Veuillez saisir un code-barres.';
                    }
                    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
                      return 'Le code-barres doit contenir uniquement des chiffres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Rechercher',
                  icon: Icons.search_rounded,
                  isFullWidth: true,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 18),
                Text(
                  "Ou tester un code-barres d'exemple :",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final demo in OpenFoodFactsService.demoProducts)
                      _DemoBarcodeChip(
                        product: demo,
                        onTap: () => widget.onSubmitCode(demo.barcode),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoBarcodeChip extends StatelessWidget {
  const _DemoBarcodeChip({required this.product, required this.onTap});

  final ScannedProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.chipBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NutriScoreBadge(grade: product.nutriScoreGrade, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  product.name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
