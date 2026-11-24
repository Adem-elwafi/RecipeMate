import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Erreur ImgBB explicite, déjà rédigée en français pour l'utilisateur.
class ImgBBException implements Exception {
  const ImgBBException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Envoi d'images vers l'API officielle ImgBB (`https://api.imgbb.com`).
///
/// La clé n'est jamais codée en dur : elle est lue depuis la variable
/// d'environnement `IMGBB_API_KEY` transmise avec `--dart-define`, ou injectée
/// explicitement (tests). Tant qu'aucune clé n'est fournie, [isConfigured]
/// reste faux et les appelants conservent leur stockage historique.
class ImgBBService {
  ImgBBService({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKey = apiKey ?? apiKeyFromEnvironment;

  /// Valeur lue au démarrage de l'application. Aucune clé réelle n'est incluse
  /// dans le dépôt : voir le README pour la commande `--dart-define`.
  static const String apiKeyFromEnvironment = String.fromEnvironment(
    'IMGBB_API_KEY',
  );

  static const String _uploadPath = '/1/upload';
  static const int _maxBytes = 32 * 1024 * 1024;

  final http.Client _client;
  final String _apiKey;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  /// Envoie [file] et renvoie une URL HTTPS directement exploitable par
  /// `Image.network` / `NetworkImage`.
  Future<String> uploadImage({required XFile file, String? name}) async {
    if (!isConfigured) {
      throw const ImgBBException(
        'Clé API ImgBB absente : configurez IMGBB_API_KEY via --dart-define.',
      );
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const ImgBBException('Le fichier image est vide.');
    }
    if (bytes.length > _maxBytes) {
      throw const ImgBBException(
        'L’image dépasse la limite ImgBB de 32 Mo. Choisissez une photo plus légère.',
      );
    }

    final uri = Uri.https('api.imgbb.com', _uploadPath, <String, dynamic>{
      'key': _apiKey,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
    });
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: file.name.isEmpty ? 'image.jpg' : file.name,
        ),
      );

    late final http.StreamedResponse streamed;
    try {
      streamed = await _client.send(request);
    } on Object {
      throw const ImgBBException(
        'ImgBB est momentanément indisponible. Vérifiez votre connexion Internet.',
      );
    }

    final response = await http.Response.fromStream(streamed);
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on Object {
      throw ImgBBException(
        'Réponse ImgBB invalide (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    final success = body['success'] == true;
    final data = body['data'];
    if (response.statusCode != 200 || !success || data is! Map) {
      final error = body['error'] is Map
          ? (body['error'] as Map)['message']?.toString()
          : body['error']?.toString();
      throw ImgBBException(
        error ?? 'Envoi ImgBB impossible. Réessayez.',
        statusCode: response.statusCode,
      );
    }

    final rawUrl = data['url']?.toString() ?? data['display_url']?.toString();
    if (rawUrl == null) {
      throw const ImgBBException('ImgBB a renvoyé une URL d’image invalide.');
    }
    final parsedUrl = Uri.tryParse(rawUrl);
    if (parsedUrl == null ||
        (parsedUrl.scheme != 'https' && parsedUrl.scheme != 'http') ||
        parsedUrl.host.isEmpty) {
      throw const ImgBBException('ImgBB a renvoyé une URL d’image invalide.');
    }
    return rawUrl;
  }
}
