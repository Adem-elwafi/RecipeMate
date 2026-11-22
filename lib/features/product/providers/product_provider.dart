import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipemate/features/product/models/scanned_product.dart';
import 'package:recipemate/features/product/services/open_food_facts_service.dart';

/// Provides a shared [OpenFoodFactsService] instance.
final openFoodFactsServiceProvider = Provider<OpenFoodFactsService>((ref) {
  final service = OpenFoodFactsService();
  ref.onDispose(service.dispose);
  return service;
});

/// Fetches a [ScannedProduct] by barcode via [openFoodFactsServiceProvider].
final productByBarcodeProvider = FutureProvider.family<ScannedProduct, String>((
  ref,
  barcode,
) {
  return ref.watch(openFoodFactsServiceProvider).fetchProductByBarcode(barcode);
});
