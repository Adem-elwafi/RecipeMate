/// Recipe difficulty levels, used by the advanced search filters.
enum Difficulty {
  easy('Facile'),
  medium('Moyen'),
  hard('Difficile');

  const Difficulty(this.label);

  /// Display label in French.
  final String label;
}
