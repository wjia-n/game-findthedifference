import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const FindTheDifferenceApp());

class FindTheDifferenceApp extends StatelessWidget {
  const FindTheDifferenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Find the Difference',
      tagline: 'Spot every difference in beautiful scenes',
      emoji: '👀',
      slug: 'findthedifference',
      howToPlay:
          '• Two pictures sit side by side — but 5 things changed!\n• Tap a difference on EITHER picture to circle it.\n• You get 90 seconds per scene and 2 hints.\n• Faster eyes = bigger score. Spot all 40 to win!',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) =>
          FindTheDifferenceScreen(players: players, callbacks: cb),
    );
  }
}
