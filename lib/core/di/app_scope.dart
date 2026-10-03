import 'package:flutter/widgets.dart';

import 'app_dependencies.dart';

class const AppScope({
  super.key,
  required final AppDependencies dependencies,
  required super.child,
}) extends InheritedWidget {
  static AppDependencies of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found above this context');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      !identical(dependencies, oldWidget.dependencies);
}
