import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../escape_game.dart';

/// A full-node SVG backdrop (M7 art hybrid: pixelart-flavoured environment
/// behind the signage foreground). Loads an SVG asset to a `ui.Picture` once
/// and paints it scaled to the node bounds, behind every entity. Used by the
/// night meadow; the interactive pads/figure render on top in signage style.
class Backdrop extends PositionComponent with HasGameReference<EscapeGame> {
  Backdrop(Vector2 position, Vector2 size, {required this.asset})
      : super(position: position, size: size, priority: -100);

  final String asset;
  ui.Picture? _picture;
  ui.Size _intrinsic = const ui.Size(680, 400);

  @override
  Future<void> onLoad() async {
    final info = await vg.loadPicture(SvgAssetLoader(asset), null);
    _picture = info.picture;
    _intrinsic = info.size;
  }

  @override
  void render(ui.Canvas canvas) {
    final pic = _picture;
    if (pic == null) return;
    canvas.save();
    canvas.scale(size.x / _intrinsic.width, size.y / _intrinsic.height);
    canvas.drawPicture(pic);
    canvas.restore();
  }
}
