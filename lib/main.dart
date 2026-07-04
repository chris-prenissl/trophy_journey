import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'core/di/app_scope.dart';
import 'features/trophies/data/datasources/progress_local_data_source.dart';
import 'features/trophies/data/datasources/trophy_asset_data_source.dart';
import 'features/trophies/data/repositories/trophy_progress_repository_impl.dart';
import 'features/trophies/data/repositories/trophy_repository_impl.dart';
import 'features/trophies/domain/usecases/get_achieved_trophy_ids.dart';
import 'features/trophies/domain/usecases/get_trophies.dart';
import 'features/trophies/domain/usecases/set_trophy_achieved.dart';
import 'features/trophies/presentation/screens/trophy_list_screen.dart';
import 'features/trophies/presentation/viewmodels/trophy_list_view_model.dart';

void main() {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  final trophyRepository =
      TrophyRepositoryImpl(TrophyAssetDataSource(rootBundle));
  final progressRepository =
      TrophyProgressRepositoryImpl(ProgressLocalDataSource());
  final viewModel = TrophyListViewModel(
    GetTrophies(trophyRepository),
    GetAchievedTrophyIds(progressRepository),
    SetTrophyAchieved(progressRepository),
  )..load();

  runApp(TrophyGuideApp(viewModel: viewModel));
}

class TrophyGuideApp extends StatelessWidget {
  const TrophyGuideApp({super.key, required this.viewModel});

  final TrophyListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      viewModel: viewModel,
      child: MaterialApp(
        title: 'FF Trophy Guide',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B4B8A),
            brightness: Brightness.dark,
          ),
        ),
        home: const TrophyListScreen(),
      ),
    );
  }
}
