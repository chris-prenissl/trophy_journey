import 'package:flutter/widgets.dart';

import '../../features/trophies/presentation/viewmodels/trophy_list_view_model.dart';

/// Exposes the app's view models to the widget tree.
///
/// Widgets that call [AppScope.of] rebuild whenever the view model notifies.
class AppScope extends InheritedNotifier<TrophyListViewModel> {
  const AppScope({
    super.key,
    required TrophyListViewModel viewModel,
    required super.child,
  }) : super(notifier: viewModel);

  static TrophyListViewModel of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found above this context');
    return scope!.notifier!;
  }
}
