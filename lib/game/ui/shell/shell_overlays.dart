import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../escape_game.dart';
import '../../palette.dart';
import '../../save/save_service.dart';
import '../../save/settings.dart';

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

/// Wraps a shell overlay so the overlay ITSELF owns the keyboard while it's the
/// top widget — the reliable path for menu nav. The GameWidget keeps keyboard
/// focus for gameplay (autofocus), so a passive `autofocus` here would NOT
/// steal it; instead this **forcibly requests** focus on mount (post-frame, so
/// the node is attached) and forwards keys to [EscapeGame.handleShellKey]. When
/// the overlay is dismissed the node is disposed and focus returns to the game.
class ShellKeys extends StatefulWidget {
  const ShellKeys({super.key, required this.game, required this.child});
  final EscapeGame game;
  final Widget child;

  @override
  State<ShellKeys> createState() => _ShellKeysState();
}

class _ShellKeysState extends State<ShellKeys> {
  final FocusNode _node = FocusNode(debugLabel: 'shellKeys');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _node.requestFocus();
    });
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      onKeyEvent: (node, event) {
        // KeyDownEvent only (not KeyRepeatEvent) → one step per press.
        if (event is KeyDownEvent &&
            widget.game.handleShellKey(event.logicalKey)) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}

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
          // Play (→ avatar select) and settings, keyboard-navigable. Play is
          // index 0 so Enter on a fresh launch starts straight away.
          ValueListenableBuilder<int>(
            valueListenable: game.shellSelection,
            builder: (context, sel, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ShellButton(
                  icon: Icons.play_arrow_rounded,
                  size: 92,
                  selected: sel == 0,
                  onTap: game.titleActions[0],
                ),
                const SizedBox(width: 22),
                _ShellButton(
                  icon: Icons.settings_rounded,
                  size: 68,
                  selected: sel == 1,
                  onTap: game.titleActions[1],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar / profile select (GDD §10b): pick one of the fixed pictogram avatar
/// slots — no typed names (symbol-first). A slot that already holds a run shows
/// a small resume dot; the keyboard cursor pre-lands on the last-played slot.
/// Esc (or the back button) returns to the title.
class ProfileOverlay extends StatelessWidget {
  const ProfileOverlay(this.game, {super.key});
  final EscapeGame game;

  /// One icon per slot, same order as [SaveService.profileIds] /
  /// [EscapeGame.profileActions]. Friendly creatures — the kitten the claw
  /// rescues, and two companions.
  static const _avatars = [
    Icons.pets, // cat
    Icons.cruelty_free, // bunny
    Icons.flutter_dash, // bird
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _amber.bg,
      alignment: Alignment.center,
      child: Stack(
        children: [
          // Back to title (top-left), mirrors the Esc shortcut.
          Positioned(
            top: 18,
            left: 18,
            child: _ShellButton(
              icon: Icons.arrow_back_rounded,
              size: 56,
              onTap: game.exitToTitle,
            ),
          ),
          Center(
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: game.profilesWithSaves,
              builder: (context, saves, _) => ValueListenableBuilder<int>(
                valueListenable: game.shellSelection,
                builder: (context, sel, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < _avatars.length; i++) ...[
                      if (i > 0) const SizedBox(width: 26),
                      _AvatarSlot(
                        icon: _avatars[i],
                        selected: i == sel,
                        hasSave: saves.contains(SaveService.profileIds[i]),
                        onTap: game.profileActions[i],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One avatar button with an optional resume dot (the slot has a saved run).
class _AvatarSlot extends StatelessWidget {
  const _AvatarSlot({
    required this.icon,
    required this.selected,
    required this.hasSave,
    required this.onTap,
  });
  final IconData icon;
  final bool selected;
  final bool hasSave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _ShellButton(icon: icon, size: 96, selected: selected, onTap: onTap),
        if (hasSave)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _amber.accentGoal,
                shape: BoxShape.circle,
                border: Border.all(color: _amber.ink, width: 3),
              ),
            ),
          ),
      ],
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
    Icons.settings_rounded,
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

/// Settings (GDD §10b): sound + music toggles and the touch-control size
/// preset, all wordless. Reached from the title or the pause menu; Esc or the
/// back row returns to whichever opened it. Rows are a keyboard-navigable list
/// (same-order contract with [EscapeGame.settingsActions]); confirm toggles or
/// cycles the focused row. Sound/music are stored but inert until the audio
/// pass; the size preset live-scales the touch buttons.
class SettingsOverlay extends StatelessWidget {
  const SettingsOverlay(this.game, {super.key});
  final EscapeGame game;

  @override
  Widget build(BuildContext context) {
    // Rebuild on either cursor moves or value changes.
    return ValueListenableBuilder<int>(
      valueListenable: game.settingsVersion,
      builder: (context, _, _) => ValueListenableBuilder<int>(
        valueListenable: game.shellSelection,
        builder: (context, sel, _) {
          final s = game.settings;
          return Container(
            color: _amber.bg,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 26),
              decoration: BoxDecoration(
                color: _amber.surface,
                border: Border.all(color: _amber.ink, width: 4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SettingRow(
                    icon: s.soundOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    selected: sel == 0,
                    onTap: game.settingsActions[0],
                    trailing: _Toggle(on: s.soundOn),
                  ),
                  const SizedBox(height: 16),
                  _SettingRow(
                    icon: s.musicOn
                        ? Icons.music_note_rounded
                        : Icons.music_off_rounded,
                    selected: sel == 1,
                    onTap: game.settingsActions[1],
                    trailing: _Toggle(on: s.musicOn),
                  ),
                  const SizedBox(height: 16),
                  _SettingRow(
                    icon: Icons.touch_app_rounded,
                    selected: sel == 2,
                    onTap: game.settingsActions[2],
                    trailing: _SizePips(scale: s.touchScale),
                  ),
                  const SizedBox(height: 22),
                  _ShellButton(
                    icon: Icons.arrow_back_rounded,
                    size: 60,
                    selected: sel == 3,
                    onTap: game.settingsActions[3],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One settings row: a leading glyph chip + a trailing value widget, in an
/// ink-bordered pill that brightens when the keyboard cursor is on it.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.trailing,
  });
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _amber.accentHint : _amber.accentNeutral,
          border: Border.all(color: _amber.ink, width: selected ? 4 : 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 34, color: _amber.ink),
            const Spacer(),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// A wordless on/off pill — filled ink dot on the right when on, left when off.
class _Toggle extends StatelessWidget {
  const _Toggle({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 28,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: on ? _amber.accentGoal : _amber.bg,
        border: Border.all(color: _amber.ink, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Align(
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: _amber.ink,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Touch-size indicator: 1–3 growing pips, plus a live preview circle at the
/// chosen size (so the effect reads even on desktop, where the touch buttons
/// aren't shown).
class _SizePips extends StatelessWidget {
  const _SizePips({required this.scale});
  final TouchScale scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < TouchScale.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Container(
            width: 10 + i * 5,
            height: 10 + i * 5,
            decoration: BoxDecoration(
              color: i < scale.pips ? _amber.ink : _amber.bg,
              shape: BoxShape.circle,
              border: Border.all(color: _amber.ink, width: 2),
            ),
          ),
        ],
      ],
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
