import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:recipemate/core/models/fridge_item.dart';
import 'package:recipemate/core/models/user_profile.dart';

/// Generates tailored anti-waste French recipe ideas using Gemini API
/// with a rich local French demonstration fallback when no API key is configured.
class GeminiRecipeService {
  GeminiRecipeService({
    http.Client? client,
    String apiKey = const String.fromEnvironment('GEMINI_API_KEY'),
  }) : _client = client ?? http.Client(),
       _apiKey = apiKey.trim();

  final http.Client _client;
  final String _apiKey;

  /// Whether a non-empty Gemini API key is configured at build/runtime.
  bool get hasApiKey => _apiKey.isNotEmpty;

  /// Generates a French anti-waste recipe idea based on [fridgeItems] and [profile].
  Future<String> generateAntiWasteIdea({
    required List<FridgeItem> fridgeItems,
    required UserProfile profile,
  }) async {
    final expiringItems = _extractTopExpiring(fridgeItems);
    final availableItems = _extractAvailableItems(fridgeItems);

    if (!hasApiKey) {
      return _buildLocalDemoSuggestion(
        expiringItems: expiringItems,
        availableItems: availableItems,
        profile: profile,
      );
    }

    final prompt = _buildPrompt(
      expiringItems: expiringItems,
      availableItems: availableItems,
      profile: profile,
    );
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-2.0-flash:generateContent?key=${_apiKey.trim()}',
    );

    try {
      final response = await _client
          .post(
            uri,
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, Object?>{
              'contents': <Map<String, Object?>>[
                <String, Object?>{
                  'parts': <Map<String, String>>[
                    <String, String>{'text': prompt},
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final text = _extractCandidateText(_decodeResponseBody(response));
        if (text != null) {
          return text;
        }
      }
    } on TimeoutException {
      // Fall back gracefully to local chef suggestion.
    } on SocketException {
      // Fall back gracefully to local chef suggestion.
    } on http.ClientException {
      // Fall back gracefully to local chef suggestion.
    } on FormatException {
      // Fall back gracefully to local chef suggestion.
    }

    return _buildLocalDemoSuggestion(
      expiringItems: expiringItems,
      availableItems: availableItems,
      profile: profile,
      fromFallback: true,
    );
  }

  /// Closes the underlying HTTP client.
  void dispose() {
    _client.close();
  }

  List<FridgeItem> _extractTopExpiring(List<FridgeItem> fridgeItems) {
    final expiring = fridgeItems.where((item) => item.isExpiringSoon).toList()
      ..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
    return expiring.take(4).toList();
  }

  List<FridgeItem> _extractAvailableItems(List<FridgeItem> fridgeItems) {
    final available = fridgeItems.where((item) => !item.isExpired).toList()
      ..sort((a, b) {
        if (a.hasExpirationDate != b.hasExpirationDate) {
          return a.hasExpirationDate ? -1 : 1;
        }
        return a.expirationDate.compareTo(b.expirationDate);
      });
    return available.take(8).toList();
  }

  String _buildPrompt({
    required List<FridgeItem> expiringItems,
    required List<FridgeItem> availableItems,
    required UserProfile profile,
  }) {
    final expiringText = expiringItems.isEmpty
        ? 'Aucun ingrédient urgent'
        : expiringItems
              .map((i) => '${i.ingredient.name} (${i.shortExpirationLabel})')
              .join(', ');
    final availableText = availableItems.isEmpty
        ? 'Frigo vide'
        : availableItems.map((i) => i.ingredient.name).join(', ');
    final dietsText = profile.diets.isEmpty
        ? 'Équilibré'
        : profile.diets.join(', ');
    final allergiesText = profile.allergies.isEmpty
        ? 'Aucune'
        : profile.allergies.join(', ');

    return 'Tu es un chef cuisinier français expert en cuisine anti-gaspi.\n'
        'Propose UNE idée de recette rapide et savoureuse en français.\n'
        'Ingrédients à consommer en priorité : $expiringText.\n'
        'Autres ingrédients disponibles : $availableText.\n'
        'Régimes du profil : $dietsText.\n'
        'Allergies à exclure impérativement : $allergiesText.\n'
        'Objectif calorique journalier : ${profile.calorieGoal} kcal.\n'
        'Format souhaité : Titre accrocheur, temps de préparation, '
        'ingrédients utilisés et 3 étapes courtes.';
  }

  String? _extractCandidateText(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) {
      return null;
    }
    final candidates = decoded['candidates'];
    if (candidates is! List<Object?> || candidates.isEmpty) {
      return null;
    }
    final firstCandidate = candidates.first;
    if (firstCandidate is! Map<String, Object?>) {
      return null;
    }
    final content = firstCandidate['content'];
    if (content is! Map<String, Object?>) {
      return null;
    }
    final parts = content['parts'];
    if (parts is! List<Object?> || parts.isEmpty) {
      return null;
    }
    final firstPart = parts.first;
    if (firstPart is! Map<String, Object?>) {
      return null;
    }
    final text = firstPart['text'];
    if (text is String && text.trim().isNotEmpty) {
      return text.trim();
    }
    return null;
  }

  String _decodeResponseBody(http.Response response) {
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    if (contentType.contains('charset=')) {
      return response.body;
    }
    try {
      return utf8.decode(response.bodyBytes);
    } on FormatException {
      return response.body;
    }
  }

  String _buildLocalDemoSuggestion({
    required List<FridgeItem> expiringItems,
    required List<FridgeItem> availableItems,
    required UserProfile profile,
    bool fromFallback = false,
  }) {
    final dietLine = profile.diets.isEmpty
        ? 'équilibré'
        : profile.diets.join(' & ').toLowerCase();
    final allergyLine = profile.allergies.isEmpty
        ? 'sans restriction particulière'
        : 'garantie sans ${profile.allergies.join(', ').toLowerCase()}';
    final footer = fromFallback
        ? 'Connexion Gemini indisponible — suggestion locale générée à partir de votre frigo.'
        : 'Mode démonstration locale — ajoutez GEMINI_API_KEY via --dart-define pour activer Gemini live.';

    final priorityList = expiringItems.isNotEmpty
        ? expiringItems
        : availableItems.take(3).toList();

    if (priorityList.isEmpty) {
      return 'Idée anti-gaspi du chef · 15 min\n\n'
          'Votre frigo semble vide pour le moment. Ajoutez quelques ingrédients '
          'frais pour obtenir une recette personnalisée ($dietLine, $allergyLine).\n\n'
          '$footer';
    }

    final names = priorityList.map((item) => item.ingredient.name).toList();
    final leadNames = names.take(3).join(', ');
    final recipeTitle = expiringItems.isNotEmpty
        ? 'Poêlée ou bol anti-gaspi : $leadNames'
        : 'Assiette fraîcheur express : $leadNames';

    final prepMinutes = priorityList.length >= 3 ? 15 : 10;
    final focusDetail = expiringItems.isNotEmpty
        ? 'Priorité anti-gaspi sur : ${expiringItems.map((i) => '${i.ingredient.name} (${i.shortExpirationLabel})').join(', ')}.'
        : 'Ingrédients sélectionnés : $leadNames.';

    return '$recipeTitle · $prepMinutes min\n\n'
        '$focusDetail\n'
        'Recette adaptée à votre profil $dietLine ($allergyLine, objectif ${profile.calorieGoal} kcal/j) :\n\n'
        '1. Préparez et émincez $leadNames en morceaux réguliers.\n'
        '2. Faites revenir ou assemblez à froid avec un filet d’huile d’olive, des herbes et une pointe de citron.\n'
        '3. Servez aussitôt pour profiter de toute la fraîcheur sans rien gaspiller.\n\n'
        '$footer';
  }
}
