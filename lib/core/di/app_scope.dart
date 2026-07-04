import 'package:flutter/widgets.dart';

import '../../features/trophies/presentation/viewmodels/game_list_view_model.dart';
import '../../features/trophies/presentation/viewmodels/trophy_list_view_model.dart';

typedef TrophyListViewModelFactory = TrophyListViewModel Function(
  String gameId,
);

/// Exposes the app's view models to the widget tree.
///
/// The game-list view model is app-wide state; widgets that call
/// [AppScope.of] rebuild whenever it notifies. Per-game trophy list view
/// models are created on demand via [trophyListViewModelFactory] and owned
/// by the screen that shows them.
class AppScope extends InheritedNotifier<GameListViewModel> {
  const AppScope({
    super.key,
    required GameListViewModel gameListViewModel,
    required this.trophyListViewModelFactory,
    required super.child,
  }) : super(notifier: gameListViewModel);

  final TrophyListViewModelFactory trophyListViewModelFactory;

  static GameListViewModel of(BuildContext context) => _scope(context).notifier!;

  static TrophyListViewModelFactory trophyListFactoryOf(BuildContext context) =>
      _scope(context).trophyListViewModelFactory;

  static AppScope _scope(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found above this context');
    return scope!;
  }
}
