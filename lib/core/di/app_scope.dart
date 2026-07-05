import 'package:flutter/widgets.dart';

import '../../features/journey/domain/usecases/has_journey.dart';
import '../../features/journey/presentation/viewmodels/journey_view_model.dart';
import '../../features/trophies/presentation/viewmodels/game_list_view_model.dart';
import '../../features/trophies/presentation/viewmodels/trophy_list_view_model.dart';

typedef TrophyListViewModelFactory = TrophyListViewModel Function(
  String gameId,
);

typedef JourneyViewModelFactory = JourneyViewModel Function(String gameId);

class AppScope extends InheritedNotifier<GameListViewModel> {
  const AppScope({
    super.key,
    required GameListViewModel gameListViewModel,
    required this.trophyListViewModelFactory,
    required this.journeyViewModelFactory,
    required this.hasJourney,
    required super.child,
  }) : super(notifier: gameListViewModel);

  final TrophyListViewModelFactory trophyListViewModelFactory;
  final JourneyViewModelFactory journeyViewModelFactory;
  final HasJourney hasJourney;

  static GameListViewModel of(BuildContext context) => _scope(context).notifier!;

  static TrophyListViewModelFactory trophyListFactoryOf(BuildContext context) =>
      _scope(context).trophyListViewModelFactory;

  static JourneyViewModelFactory journeyFactoryOf(BuildContext context) =>
      _scope(context).journeyViewModelFactory;

  static HasJourney hasJourneyOf(BuildContext context) =>
      _scope(context).hasJourney;

  static AppScope _scope(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found above this context');
    return scope!;
  }
}
