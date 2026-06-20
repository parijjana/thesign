import 'package:flutter/material.dart';

import '../../escape_game.dart';
import '../../palette.dart';

/// M7 shell overlays (GDD §10b). The play space is strictly wordless; the
/// shell is **text/icon-permitted but symbol-first**, so these use standard
/// Material iconography themed to the castle (amber) palette. The title
/// wordmark is a placeholder until the M7.5 art pass draws it as a panel.

const _amber = Palettes.amber;

/// Title screen: wordmark + play. The play space sits frozen behind it.
class TitleOverlay extends StatelessWidget {
  const TitleOverlay(this.game, {super.key});
  final EscapeGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _amber.bg,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Placeholder wordmark — drawn as a signage panel in M7.5.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: _amber.surface,
              border: Border.all(color: _amber.ink, width: 4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'THE SIGN',
              style: TextStyle(
                color: Color(0xFF101010),
                fontSize: 44,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
              ),
            ),
          ),
          const SizedBox(height: 40),
          _ShellButton(
            icon: Icons.play_arrow_rounded,
            size: 92,
            onTap: game.startGame,
          ),
        ],
      ),
    );
  }
}

/// Pause overlay: resume / restart-room / exit-to-title, over a scrim.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay(this.game, {super.key});
  final EscapeGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _amber.ink.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: _amber.bg,
          border: Border.all(color: _amber.ink, width: 4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ShellButton(icon: Icons.play_arrow_rounded, onTap: game.resumeGame),
            const SizedBox(width: 18),
            _ShellButton(
              icon: Icons.replay_rounded,
              onTap: () {
                game.requestReset();
                game.resumeGame();
              },
            ),
            const SizedBox(width: 18),
            _ShellButton(icon: Icons.home_rounded, onTap: game.exitToTitle),
          ],
        ),
      ),
    );
  }
}

/// A round ink-bordered chip with a centred icon — the shell's button look.
class _ShellButton extends StatelessWidget {
  const _ShellButton({required this.icon, required this.onTap, this.size = 68});
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _amber.accentNeutral,
          shape: BoxShape.circle,
          border: Border.all(color: _amber.ink, width: 3),
        ),
        child: Icon(icon, size: size * 0.56, color: _amber.ink),
      ),
    );
  }
}
