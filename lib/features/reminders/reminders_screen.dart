import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipemate/core/config/app_config.dart';
import 'package:recipemate/core/models/reminder.dart';
import 'package:recipemate/core/providers/app_providers.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/shared/widgets/app_snack_bar.dart';
import 'package:recipemate/shared/widgets/secondary_app_bar.dart';

/// Point 4/7 : écran « Mes rappels ».
///
/// Liste les rappels à venir et passés depuis Firestore, permet de planifier
/// un rappel de repas (heure + recette ou libellé libre) et d'annuler un
/// rappel futur. La permission est demandée avant la première planification.
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  Future<void> _requestPermissionIfNeeded() async {
    final granted = await ref
        .read(notificationServiceProvider)
        .requestPermission();
    if (granted || !mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Autorisation refusée'),
        content: const Text(
          'Pour recevoir vos rappels, autorisez les notifications dans les '
          'réglages système de votre appareil. Sur Android 12 et plus, '
          'autorisez aussi les alarmes exactes.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMealReminder(String uid) async {
    await _requestPermissionIfNeeded();
    if (!mounted) {
      return;
    }

    // Point A : le dialog possède son contrôleur et le libère dans dispose(),
    // exactement comme pour la création de collection. Aucun contrôleur ne
    // survit donc à l'animation de sortie du dialog.
    final title = await showDialog<String>(
      context: context,
      builder: (_) => const _ReminderNameDialog(
        title: 'Nouveau rappel de repas',
        label: 'Recette ou libellé',
        hint: 'Ex. Salade de quinoa',
        confirmLabel: 'Choisir l’heure',
      ),
    );
    if (title == null || title.isEmpty || !mounted) {
      return;
    }

    final now = DateTime.now();
    final initialDate = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Date du rappel',
      confirmText: 'Valider',
      cancelText: 'Annuler',
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 30),
      helpText: 'Heure du rappel',
      confirmText: 'Valider',
      cancelText: 'Annuler',
    );
    if (time == null || !mounted) {
      return;
    }

    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (scheduledAt.isBefore(DateTime.now())) {
      _showMessage('Choisissez une date et une heure dans le futur.');
      return;
    }

    try {
      await ref
          .read(notificationServiceProvider)
          .createAndSchedule(
            uid: uid,
            type: ReminderType.meal,
            title: title,
            scheduledAt: scheduledAt,
            relatedId: '',
            firestore: ref.read(firestoreServiceProvider),
            useExactAlarm: true,
          );
      _showMessage('Rappel de repas programmé.');
    } on Object {
      _showMessage('Impossible de programmer le rappel. Réessayez.');
    }
  }

  /// Point 4a : planifie automatiquement un rappel X jours avant la péremption
  /// d'un produit du frigo.
  /// Les champs sont saisis manuellement ici ; le frigo peut appeler la même
  /// méthode de service avec les données de `users/{uid}/pantry/{itemId}`.
  Future<void> _addExpiryReminder(String uid) async {
    await _requestPermissionIfNeeded();
    if (!mounted) {
      return;
    }

    // Point A : même garde-fou que pour le rappel de repas.
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _ReminderNameDialog(
        title: 'Rappel de péremption',
        label: 'Nom du produit',
        hint: 'Ex. Yaourt nature',
        confirmLabel: 'Continuer',
      ),
    );
    if (name == null || name.isEmpty || !mounted) {
      return;
    }

    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Date de péremption',
      confirmText: 'Valider',
      cancelText: 'Annuler',
    );
    if (date == null || !mounted) {
      return;
    }
    await _scheduleExpiry(
      uid: uid,
      pantryItemId: 'manuel_${name.hashCode}',
      productName: name,
      expiryDate: date,
    );
  }

  Future<void> _scheduleExpiry({
    required String uid,
    required String pantryItemId,
    required String productName,
    required DateTime expiryDate,
  }) async {
    await _requestPermissionIfNeeded();
    try {
      await ref
          .read(notificationServiceProvider)
          .scheduleExpiryReminder(
            uid: uid,
            pantryItemId: pantryItemId,
            productName: productName,
            expiryDate: expiryDate,
            firestore: ref.read(firestoreServiceProvider),
          );
    } on Exception {
      _showMessage('Ce produit périme trop prochainement.');
    }
  }

  Future<void> _cancel(Reminder reminder) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      return;
    }
    await ref
        .read(notificationServiceProvider)
        .cancelReminder(
          uid: uid,
          reminderId: reminder.id,
          firestore: ref.read(firestoreServiceProvider),
        );
    _showMessage('Rappel annulé.');
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    // Point A4 : SnackBar Material themé, au-dessus de la barre de navigation.
    AppSnackBar.show(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        // Point B : même en cas de session absente, la page reste quitteable.
        appBar: SecondaryAppBar(title: 'Mes rappels'),
        body: Center(child: Text('Connectez-vous pour voir vos rappels.')),
      );
    }

    final remindersAsync = ref.watch(remindersProvider(user.uid));
    final now = DateTime.now();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      // Point B : page secondaire avec retour standard.
      appBar: const SecondaryAppBar(title: 'Mes rappels'),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FloatingActionButton.small(
            heroTag: 'expiry_reminder',
            tooltip: 'Rappel de péremption',
            onPressed: () => _addExpiryReminder(user.uid),
            child: const Icon(Icons.event_available_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'meal_reminder',
            tooltip: 'Rappel de repas',
            onPressed: () => _addMealReminder(user.uid),
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Impossible de charger les rappels.')),
        data: (reminders) {
          final upcoming = reminders
              .where(
                (item) =>
                    item.status == ReminderStatus.pending &&
                    item.scheduledAt.isAfter(now),
              )
              .toList();
          final history = reminders
              .where(
                (item) =>
                    item.status != ReminderStatus.pending ||
                    !item.scheduledAt.isAfter(now),
              )
              .toList();

          if (reminders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Aucun rappel pour le moment. Utilisez le bouton + pour '
                  'programmer un rappel de repas.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                'À venir',
                style: AppTextStyles.sectionHeader.copyWith(
                  color: colors.onSurface,
                ),
              ),
              if (upcoming.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Aucun rappel à venir.',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                )
              else
                ...upcoming.map(
                  (reminder) => _ReminderTile(
                    reminder: reminder,
                    onCancel: () => _cancel(reminder),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Historique',
                style: AppTextStyles.sectionHeader.copyWith(
                  color: colors.onSurface,
                ),
              ),
              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Aucun rappel passé.',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                )
              else
                ...history.map((reminder) => _ReminderTile(reminder: reminder)),
              const SizedBox(height: 40),
              // Point 4 : le rappel de péremption est créé sans formulaire
              // dédié ici car il est piloté par les produits du frigo.
              Center(
                child: Text(
                  'Les rappels de péremption sont programmés '
                  '${AppConfig.expiryReminderLeadDays} jours avant la date '
                  'saisie (bouton au-dessus).',
                  style: AppTextStyles.caption.copyWith(
                    color: colors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Point A : dialog de saisie d'un libellé de rappel.
///
/// Le contrôleur est créé par instance et libéré dans `dispose()` : le dialog
/// reste monté pendant toute l'animation de sortie, ce qui évite qu'un champ
/// texte utilise un contrôleur déjà libéré (cause du crash des collections).
class _ReminderNameDialog extends StatefulWidget {
  const _ReminderNameDialog({
    required this.title,
    required this.label,
    required this.hint,
    required this.confirmLabel,
  });

  final String title;
  final String label;
  final String hint;
  final String confirmLabel;

  @override
  State<_ReminderNameDialog> createState() => _ReminderNameDialogState();
}

class _ReminderNameDialogState extends State<_ReminderNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Point A3 : carte de rappel complète et lisible en modes clair et sombre.
///
/// Titre, date/heure et badges de type/statut sont toujours visibles : les
/// couleurs viennent du thème (jamais de blanc fixe sur fond clair).
class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.reminder, this.onCancel});

  final Reminder reminder;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isMeal = reminder.type == ReminderType.meal;
    final typeLabel = isMeal ? 'Repas' : 'Péremption';
    final statusLabel = switch (reminder.status) {
      ReminderStatus.pending => 'En attente',
      ReminderStatus.sent => 'Envoyé',
      ReminderStatus.cancelled => 'Annulé',
    };

    final typeBackground = isMeal
        ? colors.primaryContainer
        : colors.tertiaryContainer;
    final typeForeground = isMeal
        ? colors.onPrimaryContainer
        : colors.onTertiaryContainer;
    final statusBackground = switch (reminder.status) {
      ReminderStatus.pending => colors.primaryContainer,
      ReminderStatus.sent => colors.tertiaryContainer,
      ReminderStatus.cancelled => colors.errorContainer,
    };
    final statusForeground = switch (reminder.status) {
      ReminderStatus.pending => colors.onPrimaryContainer,
      ReminderStatus.sent => colors.onTertiaryContainer,
      ReminderStatus.cancelled => colors.onErrorContainer,
    };
    final secondaryText = colors.onSurface.withValues(alpha: 0.78);
    final date = reminder.scheduledAt;
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year} à '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isMeal
                        ? Icons.restaurant_rounded
                        : Icons.event_available_outlined,
                    color: typeForeground,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        reminder.title.isEmpty ? 'Rappel' : reminder.title,
                        style: AppTextStyles.subtitle.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: secondaryText,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            dateLabel,
                            style: AppTextStyles.caption.copyWith(
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onCancel != null)
                  IconButton(
                    tooltip: 'Annuler ce rappel',
                    icon: const Icon(Icons.cancel_outlined),
                    color: colors.error,
                    onPressed: onCancel,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                _ReminderBadge(
                  label: typeLabel,
                  background: typeBackground,
                  foreground: typeForeground,
                ),
                const SizedBox(width: 8),
                _ReminderBadge(
                  label: statusLabel,
                  background: statusBackground,
                  foreground: statusForeground,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderBadge extends StatelessWidget {
  const _ReminderBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionMedium.copyWith(color: foreground),
      ),
    );
  }
}
