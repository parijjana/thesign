import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../escape_game.dart';
import '../../palette.dart';

/// M7 shell overlays (GDD §10b). The play space is strictly wordless; the
/// shell is **text/icon-permitted but symbol-first**, so these use standard
/// Material iconography themed to the castle (amber) palette. The title
/// wordmark is a placeholder until the M7.5 art pass draws it as a panel.
///
/// Navigation is keyboard-first: the game owns the menu cursor
/// ([EscapeGame.shellSelection]) and the action lists; these widgets just
/// render the highlight and forward taps to the very same actions, so mouse
/// and keyboard can never drift apart.

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
          // Always shown selected: Enter/Space (or a tap) starts the game.
          _ShellButton(
            icon: Icons.play_arrow_rounded,
            size: 92,
            selected: true,
            onTap: game.startGame,
          ),
        ],
      ),
    );
  }
}

/// Pause overlay: resume / restart-room / map / exit-to-title, over a scrim.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay(this.game, {super.key});
  final EscapeGame game;

  static const _icons = [
    Icons.play_arrow_rounded,
    Icons.replay_rounded,
    Icons.map_rounded,
    Icons.home_rounded,
  ];

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
        child: _MenuRow(game: game, icons: _icons, actions: game.pauseActions),
      ),
    );
  }
}

/// Win/ending overlay: you escaped the castle. A bright celebration —
/// confetti raining down and balloons drifting up behind the sun seal; keep
/// exploring the meadow (the exit stays free) or go home.
class WinOverlay extends StatefulWidget {
  const WinOverlay(this.game, {super.key});
  final EscapeGame game;

  @override
  State<WinOverlay> createState() => _WinOverlayState();
}

class _WinOverlayState extends State<WinOverlay>
    with SingleTickerProviderStateMixin {
  static const _icons = [Icons.play_arrow_rounded, Icons.home_rounded];
  static const _festive = [
    Color(0xFFF2C94C), // gold
    Color(0xFFEB5757), // red
    Color(0xFF2D9CDB), // blue
    Color(0xFF27AE60), // green
    Color(0xFFBB6BD9), // purple
    Color(0xFFF2994A), // orange
  ];

  late final Ticker _ticker;
  double _t = 0;
  late final List<_Confetto> _confetti;
  late final List<_Balloon> _balloons;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(7);
    _confetti = List.generate(80, (i) {
      return _Confetto(
        x: rng.nextDouble(),
        fall: 0.06 + rng.nextDouble() * 0.10,
        phase: rng.nextDouble(),
        drift: 0.02 + rng.nextDouble() * 0.05,
        driftFreq: 0.5 + rng.nextDouble() * 1.5,
        size: 6 + rng.nextDouble() * 8,
        spin: (rng.nextDouble() - 0.5) * 6,
        round: rng.nextBool(),
        color: _festive[rng.nextInt(_festive.length)],
      );
    });
    _balloons = List.generate(7, (i) {
      return _Balloon(
        x: 0.08 + rng.nextDouble() * 0.84,
        rise: 0.05 + rng.nextDouble() * 0.05,
        phase: rng.nextDouble(),
        sway: 0.01 + rng.nextDouble() * 0.03,
        swayFreq: 0.4 + rng.nextDouble() * 0.8,
        size: 34 + rng.nextDouble() * 22,
        color: _festive[rng.nextInt(_festive.length)],
      );
    });
    _ticker = createTicker((elapsed) {
      setState(() => _t = elapsed.inMicroseconds / 1e6);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _amber.ink.withValues(alpha: 0.6),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CelebrationPainter(_t, _confetti, _balloons),
            ),
          ),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 36, vertical: 30),
              decoration: BoxDecoration(
                color: _amber.bg,
                border: Border.all(color: _amber.ink, width: 4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wb_sunny_rounded,
                      size: 96, color: _amber.accentGoal),
                  const SizedBox(height: 22),
                  _MenuRow(
                      game: widget.game,
                      icons: _icons,
                      actions: widget.game.winActions),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Confetto {
  const _Confetto({
    required this.x,
    required this.fall,
    required this.phase,
    required this.drift,
    required this.driftFreq,
    required this.size,
    required this.spin,
    required this.round,
    required this.color,
  });
  final double x, fall, phase, drift, driftFreq, size, spin;
  final bool round;
  final Color color;
}

class _Balloon {
  const _Balloon({
    required this.x,
    required this.rise,
    required this.phase,
    required this.sway,
    required this.swayFreq,
    required this.size,
    required this.color,
  });
  final double x, rise, phase, sway, swayFreq, size;
  final Color color;
}

/// Hand-drawn party layer: confetti loops downward, balloons loop upward,
/// each on its own phase so the motion never looks gridded.
class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter(this.t, this.confetti, this.balloons);
  final double t;
  final List<_Confetto> confetti;
  final List<_Balloon> balloons;

  @override
  void paint(Canvas canvas, Size size) {
    // Balloons rise (drawn first, behind confetti).
    for (final b in balloons) {
      final prog = (t * b.rise + b.phase) % 1.2; // 0..1.2, off-top margin
      final y = size.height * (1.15 - prog) + b.size;
      final x = (b.x + math.sin(t * b.swayFreq + b.phase * 6) * b.sway) *
          size.width;
      _balloon(canvas, Offset(x, y), b.size, b.color);
    }
    // Confetti falls.
    for (final c in confetti) {
      final prog = (t * c.fall + c.phase) % 1.0;
      final y = size.height * (prog * 1.1 - 0.05);
      final x = (c.x + math.sin(t * c.driftFreq + c.phase * 6) * c.drift) *
          size.width;
      final paint = Paint()..color = c.color;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * c.spin + c.phase * 6);
      if (c.round) {
        canvas.drawCircle(Offset.zero, c.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: c.size, height: c.size * 0.6),
          paint,
        );
      }
      canvas.restore();
    }
  }

  void _balloon(Canvas canvas, Offset c, double s, Color color) {
    final body = Rect.fromCenter(center: c, width: s * 0.82, height: s);
    final paint = Paint()..color = color;
    canvas.drawOval(body, paint);
    // Knot.
    final knot = Path()
      ..moveTo(c.dx - s * 0.07, c.dy + s * 0.5)
      ..lineTo(c.dx + s * 0.07, c.dy + s * 0.5)
      ..lineTo(c.dx, c.dy + s * 0.58)
      ..close();
    canvas.drawPath(knot, paint);
    // String, gently curved.
    final string = Path()
      ..moveTo(c.dx, c.dy + s * 0.58)
      ..quadraticBezierTo(
          c.dx + s * 0.18, c.dy + s * 0.9, c.dx, c.dy + s * 1.25);
    canvas.drawPath(
        string,
        Paint()
          ..color = Colors.white70
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    // A little highlight to read as glossy.
    canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(-s * 0.18, -s * 0.22),
          width: s * 0.22,
          height: s * 0.3),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter old) => old.t != t;
}

/// A row of shell buttons whose highlight tracks the game's keyboard cursor.
class _MenuRow extends StatelessWidget {
  const _MenuRow(
      {required this.game, required this.icons, required this.actions});
  final EscapeGame game;
  final List<IconData> icons;
  final List<void Function()> actions;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.shellSelection,
      builder: (context, sel, child) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < icons.length; i++) ...[
            if (i > 0) const SizedBox(width: 18),
            _ShellButton(
              icon: icons[i],
              selected: i == sel,
              onTap: actions[i],
            ),
          ],
        ],
      ),
    );
  }
}

/// A round ink-bordered chip with a centred icon — the shell's button look.
/// When [selected] (the keyboard cursor is on it) it gets a bright ring.
class _ShellButton extends StatelessWidget {
  const _ShellButton({
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.size = 68,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: selected ? _amber.accentHint : _amber.accentNeutral,
          shape: BoxShape.circle,
          border: Border.all(
            color: _amber.ink,
            width: selected ? 5 : 3,
          ),
        ),
        child: Icon(icon, size: size * 0.56, color: _amber.ink),
      ),
    );
  }
}
