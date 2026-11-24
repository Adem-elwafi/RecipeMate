import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quick category chips displayed below the home search bar.
const homeCategories = <String>[
  'Healthy',
  'Végétarien',
  'Vegan',
  'Keto',
  'Sans gluten',
  'Riche en protéines',
];

/// Local UI state for the dashboard category selector.
class HomeState {
  const HomeState({this.selectedCategory});

  final String? selectedCategory;

  HomeState copyWith({String? selectedCategory, bool clearCategory = false}) =>
      HomeState(
        selectedCategory: clearCategory
            ? null
            : (selectedCategory ?? this.selectedCategory),
      );
}

/// Riverpod controller for the home screen chips.
class HomeController extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();

  void selectCategory(String category) =>
      state = state.copyWith(selectedCategory: category);

  void clearCategory() => state = state.copyWith(clearCategory: true);
}

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);
