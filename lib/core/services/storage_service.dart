import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Sélection et envoi des images (avatars et photos de recettes).
///
/// Les avatars restent de petites vignettes Base64 stockées dans Firestore,
/// ce qui évite d'exiger le plan Blaze. Les photos de recettes utilisent
/// Firebase Storage (point B2) et produisent une vraie URL HTTPS `imageUrl`.
class StorageService {
  StorageService({this._picker});

  final ImagePicker? _picker;

  ImagePicker get _pickerInstance => _picker ?? ImagePicker();

  Future<XFile?> pickImage(ImageSource source) {
    return _pickerInstance.pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 120,
      maxHeight: 120,
    );
  }

  /// Point B2 : photo de recette en meilleure résolution que l'avatar.
  Future<XFile?> pickRecipeImage(ImageSource source) {
    return _pickerInstance.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1200,
      maxHeight: 1200,
    );
  }

  /// Ancien comportement : vignette Base64 pour les avatars uniquement.
  Future<String> uploadImage({
    required XFile file,
    required String folder,
    required String fileName,
  }) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > 900000) {
      throw Exception(
        'L’image est trop volumineuse (> 1 Mo). Veuillez choisir une photo plus légère.',
      );
    }
    final contentType = _contentType(_extension(file.name));
    final base64String = base64Encode(bytes);
    return 'data:$contentType;base64,$base64String';
  }

  /// Point B2 : upload réel dans `recipe_images/{uid}/{fileName}`.
  ///
  /// En cas d'erreur de configuration Storage (plan Spark non activé, bucket
  /// absent), on retombe sur la vignette Base64 pour ne jamais perdre la
  /// saisie de l'utilisateur. L'erreur complète reste dans les logs.
  Future<String> uploadRecipeImage({
    required XFile file,
    required String uid,
    required String fileName,
  }) async {
    final bytes = await file.readAsBytes();
    final contentType = _contentType(_extension(file.name));
    final reference = FirebaseStorage.instance.ref().child(
      'recipe_images/$uid/$fileName',
    );

    try {
      await reference.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      return await reference.getDownloadURL();
    } on Object catch (error, stackTrace) {
      debugPrint(
        '[Storage] upload impossible, repli Base64 : $error\n$stackTrace',
      );
      return uploadImage(
        file: file,
        folder: 'recipe_images',
        fileName: fileName,
      );
    }
  }

  String _extension(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) {
      return '.jpg';
    }
    return name.substring(dotIndex);
  }

  String _contentType(String extension) {
    return switch (extension.toLowerCase()) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
