import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipemate/core/providers/theme_provider.dart';
import 'package:recipemate/core/router/app_router.dart';
import 'package:recipemate/core/services/firebase_service.dart';
import 'package:recipemate/core/services/notification_service.dart';
import 'package:recipemate/core/services/preferences_service.dart';
import 'package:recipemate/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  final themeMode = await PreferencesService.getThemeMode();
  // Point 4/7 : initialise le canal de notifications et le fuseau horaire
  // avant le premier rendu (aucune permission n'est demandée ici).
  await NotificationService().initialize();

  runApp(
    ProviderScope(
      overrides: <Override>[
        initialThemeModeProvider.overrideWithValue(themeMode),
      ],
      child: const RecipeMateApp(),
    ),
  );
}

/// Root widget for RecipeMate application.
class RecipeMateApp extends ConsumerWidget {
  const RecipeMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'RecipeMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
