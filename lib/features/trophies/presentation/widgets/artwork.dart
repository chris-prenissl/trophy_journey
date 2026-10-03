import 'package:material_ui/material_ui.dart';

import '../../domain/entities/game.dart';
import '../../domain/entities/trophy.dart';

class Artwork extends StatelessWidget {
  const Artwork({
    super.key,
    required this.asset,
    required this.url,
    required this.size,
    required this.placeholder,
  });

  final String? asset;
  final String? url;
  final double size;
  final IconData placeholder;

  @override
  Widget build(BuildContext context) {
    final asset = this.asset;
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, _, _) => _placeholder(context),
      );
    }

    final url = this.url;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, _, _) => _placeholder(context),
      );
    }

    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) => Container(
    width: size,
    height: size,
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Icon(placeholder, size: size / 2),
  );
}

class GameCover extends StatelessWidget {
  const GameCover({super.key, required this.game, this.size = 56});

  final Game game;
  final double size;

  @override
  Widget build(BuildContext context) => Artwork(
    asset: game.coverAsset,
    url: game.iconUrl,
    size: size,
    placeholder: Icons.videogame_asset,
  );
}

class TrophyIcon extends StatelessWidget {
  const TrophyIcon({super.key, required this.trophy, this.size = 56});

  final Trophy trophy;
  final double size;

  @override
  Widget build(BuildContext context) => Artwork(
    asset: trophy.iconAsset,
    url: trophy.iconUrl,
    size: size,
    placeholder: Icons.emoji_events,
  );
}
