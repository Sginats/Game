import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../domain/models/room_scene.dart';

class RoomSceneBackdrop extends StatelessWidget {
  final RoomScene room;
  final RoomSceneState roomState;
  final bool reducedMotion;

  const RoomSceneBackdrop({
    super.key,
    required this.room,
    required this.roomState,
    this.reducedMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _RoomSceneBackdropPainter(
          room: room,
          roomState: roomState,
          reducedMotion: reducedMotion,
        ),
      ),
    );
  }
}

class _RoomSceneBackdropPainter extends CustomPainter {
  final RoomScene room;
  final RoomSceneState roomState;
  final bool reducedMotion;

  const _RoomSceneBackdropPainter({
    required this.room,
    required this.roomState,
    required this.reducedMotion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final base = _colorFromHex(room.themeColors.background);
    final primary = _colorFromHex(room.themeColors.primary);
    final accent = _colorFromHex(room.themeColors.accent);
    final progress = room.transformationStages.isEmpty
        ? 0.18
        : ((roomState.currentTransformationStage + 1) /
                room.transformationStages.length)
            .clamp(0.12, 1.0);
    final changes = _activeChanges();

    _paintAtmosphere(canvas, size, base, primary, accent, progress);
    _paintFloor(canvas, size, base, accent, progress);
    _paintLighting(canvas, size, accent, progress, changes);
    _paintRoomMotif(canvas, size, primary, accent, progress);
    _paintDeskAndScreens(canvas, size, primary, accent, progress, changes);
    _paintCables(canvas, size, accent, progress, changes);
    _paintDetails(canvas, size, primary, accent, progress, changes);
    if (roomState.twistActivated) {
      _paintTwistHalo(canvas, size, accent, progress);
    }
  }

  Set<String> _activeChanges() {
    final changes = <String>{};
    if (room.transformationStages.isEmpty) {
      return changes;
    }
    final lastIndex = roomState.currentTransformationStage.clamp(
      0,
      room.transformationStages.length - 1,
    );
    for (var index = 0; index <= lastIndex; index++) {
      changes.addAll(room.transformationStages[index].environmentChanges);
    }
    return changes;
  }

  void _paintAtmosphere(
    Canvas canvas,
    Size size,
    Color base,
    Color primary,
    Color accent,
    double progress,
  ) {
    final wall = Rect.fromLTWH(0, 0, size.width, size.height * 0.72);
    canvas.drawRect(
      wall,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(base, primary, 0.38)!,
            Color.lerp(base, accent, 0.16)!,
            base.withAlpha(220),
          ],
        ).createShader(wall),
    );

    final haze = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.2,
        colors: [
          accent.withAlpha((28 + progress * 34).round()),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.12),
        radius: size.width * 0.6,
      ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), haze);

    for (var index = 0; index < 3; index++) {
      final panel = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * (0.06 + index * 0.3),
          size.height * (0.08 + (index.isEven ? 0.0 : 0.03)),
          size.width * 0.22,
          size.height * 0.34,
        ),
        const Radius.circular(18),
      );
      canvas.drawRRect(
        panel,
        Paint()..color = Colors.white.withAlpha(8 + index * 3),
      );
    }
  }

  void _paintFloor(
    Canvas canvas,
    Size size,
    Color base,
    Color accent,
    double progress,
  ) {
    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..lineTo(size.width, size.height * 0.66)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(base, accent, 0.12)!.withAlpha(180),
            Color.lerp(base, Colors.black, 0.22)!.withAlpha(240),
          ],
        ).createShader(Rect.fromLTWH(0, size.height * 0.66, size.width, size.height * 0.34)),
    );

    final gridPaint = Paint()
      ..color = accent.withAlpha((18 + progress * 20).round())
      ..strokeWidth = 1;
    for (var index = 0; index < 9; index++) {
      final y = size.height * (0.72 + index * 0.035);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _paintLighting(
    Canvas canvas,
    Size size,
    Color accent,
    double progress,
    Set<String> changes,
  ) {
    if (!changes.contains('working_lights') &&
        !changes.contains('monitors_online')) {
      return;
    }
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32);
    final anchors = <double>[0.16, 0.5, 0.84];
    for (final anchor in anchors) {
      final rect = Rect.fromCenter(
        center: Offset(size.width * anchor, size.height * 0.09),
        width: size.width * 0.12,
        height: size.height * 0.03,
      );
      glowPaint.color = accent.withAlpha((50 + progress * 70).round());
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        glowPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        Paint()..color = Colors.white.withAlpha(26),
      );
    }
  }

  void _paintRoomMotif(
    Canvas canvas,
    Size size,
    Color primary,
    Color accent,
    double progress,
  ) {
    switch (room.id) {
      case 'room_01':
        _drawJunkCorner(canvas, size, primary, accent, progress);
        break;
      case 'room_02':
        _drawBudgetSetup(canvas, size, primary, accent, progress);
        break;
      case 'room_03':
        _drawCreatorRoom(canvas, size, primary, accent, progress);
        break;
      case 'room_04':
        _drawUpgradeCave(canvas, size, primary, accent, progress);
        break;
      case 'room_05':
        _drawSmartLabBedroom(canvas, size, primary, accent, progress);
        break;
      case 'room_06':
        _drawServerCloset(canvas, size, primary, accent, progress);
        break;
      case 'room_07':
        _drawCommandRoom(canvas, size, primary, accent, progress);
        break;
      case 'room_08':
        _drawAutonomousWorkspace(canvas, size, primary, accent, progress);
        break;
      case 'room_09':
        _drawResearchApartment(canvas, size, primary, accent, progress);
        break;
      case 'room_10':
        _drawContainmentLoft(canvas, size, primary, accent, progress);
        break;
      case 'room_11':
        _drawPrototypeChamber(canvas, size, primary, accent, progress);
        break;
      case 'room_12':
        _drawSyntheticStudio(canvas, size, primary, accent, progress);
        break;
      case 'room_13':
        _drawCorporateSuite(canvas, size, primary, accent, progress);
        break;
      case 'room_14':
        _drawDataCathedral(canvas, size, primary, accent, progress);
        break;
      case 'room_15':
        _drawSimulationChamber(canvas, size, primary, accent, progress);
        break;
      case 'room_16':
        _drawOrbitalHabitat(canvas, size, primary, accent, progress);
        break;
      case 'room_17':
        _drawPlanetaryForge(canvas, size, primary, accent, progress);
        break;
      case 'room_18':
        _drawChronoRoom(canvas, size, primary, accent, progress);
        break;
      case 'room_19':
        _drawKernelChamber(canvas, size, primary, accent, progress);
        break;
      case 'room_20':
        _drawQuietSingularity(canvas, size, primary, accent, progress);
        break;
    }
  }

  void _paintDeskAndScreens(
    Canvas canvas,
    Size size,
    Color primary,
    Color accent,
    double progress,
    Set<String> changes,
  ) {
    final deskRect = Rect.fromLTWH(
      size.width * 0.26,
      size.height * 0.67,
      size.width * 0.48,
      size.height * 0.12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(deskRect, const Radius.circular(18)),
      Paint()..color = Color.lerp(primary, Colors.black, 0.25)!.withAlpha(180),
    );

    final legPaint = Paint()..color = Colors.white.withAlpha(18);
    for (final x in <double>[0.3, 0.69]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * x,
            size.height * 0.77,
            size.width * 0.02,
            size.height * 0.14,
          ),
          const Radius.circular(10),
        ),
        legPaint,
      );
    }

    if (changes.contains('new_desk') || progress > 0.35) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.38,
            size.height * 0.61,
            size.width * 0.1,
            size.height * 0.06,
          ),
          const Radius.circular(14),
        ),
        Paint()..color = Colors.white.withAlpha(16),
      );
    }

    if (changes.contains('monitors_online') || progress > 0.5) {
      final screenColor = accent.withAlpha((70 + progress * 90).round());
      for (final x in <double>[0.38, 0.49, 0.6]) {
        final screenRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * x,
            size.height * 0.48,
            size.width * 0.085,
            size.height * 0.11,
          ),
          const Radius.circular(12),
        );
        canvas.drawRRect(screenRect, Paint()..color = Colors.black.withAlpha(80));
        canvas.drawRRect(
          screenRect.deflate(4),
          Paint()..color = screenColor,
        );
      }
    }
  }

  void _paintCables(
    Canvas canvas,
    Size size,
    Color accent,
    double progress,
    Set<String> changes,
  ) {
    final cablePaint = Paint()
      ..color = accent.withAlpha(changes.contains('organized_cables') ? 42 : 22)
      ..strokeWidth = changes.contains('organized_cables') ? 2.2 : 1.4
      ..style = PaintingStyle.stroke;
    final cableCount = changes.contains('organized_cables') ? 7 : 4;
    for (var index = 0; index < cableCount; index++) {
      final start = Offset(size.width * (0.15 + index * 0.09), size.height * 0.82);
      final end = Offset(size.width * (0.08 + index * 0.12), size.height * 0.38);
      final midY = size.height * (0.72 - index * 0.03);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + size.width * 0.04,
          midY,
          end.dx - size.width * 0.02,
          midY - size.height * 0.08,
          end.dx,
          end.dy,
        );
      canvas.drawPath(path, cablePaint);
    }
  }

  void _paintDetails(
    Canvas canvas,
    Size size,
    Color primary,
    Color accent,
    double progress,
    Set<String> changes,
  ) {
    if (changes.contains('ambient_particles') && !reducedMotion) {
      final particlePaint = Paint();
      for (var index = 0; index < 26; index++) {
        final dx = size.width * ((index * 73 % 100) / 100);
        final dy = size.height * ((index * 41 % 60) / 100 + 0.16);
        final radius = 1.5 + (index % 3) * 1.4 + progress;
        particlePaint.color = accent.withAlpha(20 + (index % 5) * 8);
        canvas.drawCircle(Offset(dx, dy), radius, particlePaint);
      }
    }

    if (changes.contains('hidden_compartments_revealed')) {
      for (final anchor in <double>[0.12, 0.78]) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * anchor,
            size.height * 0.29,
            size.width * 0.1,
            size.height * 0.16,
          ),
          const Radius.circular(14),
        );
        canvas.drawRRect(rect, Paint()..color = Colors.white.withAlpha(16));
        canvas.drawRRect(
          rect.deflate(8),
          Paint()..color = primary.withAlpha(54),
        );
      }
    }

    if (changes.contains('smart_surfaces')) {
      final paint = Paint()
        ..color = accent.withAlpha(28)
        ..strokeWidth = 1;
      for (var index = 0; index < 12; index++) {
        final x = size.width * (0.2 + index * 0.05);
        canvas.drawLine(
          Offset(x, size.height * 0.38),
          Offset(x + size.width * 0.06, size.height * 0.82),
          paint,
        );
      }
    }

    if (changes.contains('full_transformation')) {
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.4),
        size.height * 0.22,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent.withAlpha(64),
      );
    }
  }

  void _paintTwistHalo(
    Canvas canvas,
    Size size,
    Color accent,
    double progress,
  ) {
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.42),
      size.height * (0.18 + progress * 0.08),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
        ..color = accent.withAlpha(90),
    );
  }

  void _drawJunkCorner(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    for (var index = 0; index < 5; index++) {
      final rect = Rect.fromLTWH(
        size.width * (0.05 + index * 0.08),
        size.height * (0.72 - index * 0.025),
        size.width * 0.06,
        size.height * (0.1 + index * 0.01),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        Paint()..color = Color.lerp(primary, accent, 0.2)!.withAlpha(48),
      );
    }
  }

  void _drawBudgetSetup(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.78, size.height * 0.18, size.width * 0.14, size.height * 0.28),
      const Radius.circular(18),
    );
    canvas.drawRRect(board, Paint()..color = primary.withAlpha(30));
    for (var index = 0; index < 8; index++) {
      canvas.drawCircle(
        Offset(size.width * (0.8 + (index % 4) * 0.03), size.height * (0.22 + (index ~/ 4) * 0.09)),
        4,
        Paint()..color = accent.withAlpha(70),
      );
    }
  }

  void _drawCreatorRoom(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.32),
      size.height * 0.12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = accent.withAlpha(52),
    );
    canvas.drawLine(
      Offset(size.width * 0.82, size.height * 0.44),
      Offset(size.width * 0.82, size.height * 0.68),
      Paint()
        ..color = Colors.white.withAlpha(36)
        ..strokeWidth = 4,
    );
  }

  void _drawUpgradeCave(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    final paint = Paint()..color = primary.withAlpha(34);
    for (var index = 0; index < 6; index++) {
      final x = size.width * (0.12 + index * 0.14);
      final path = Path()
        ..moveTo(x, size.height * 0.68)
        ..lineTo(x + size.width * 0.03, size.height * 0.42)
        ..lineTo(x + size.width * 0.07, size.height * 0.68)
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.46),
      size.height * 0.06,
      Paint()..color = accent.withAlpha(34),
    );
  }

  void _drawSmartLabBedroom(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    final bed = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.07, size.height * 0.62, size.width * 0.18, size.height * 0.1),
      const Radius.circular(18),
    );
    canvas.drawRRect(bed, Paint()..color = primary.withAlpha(28));
    for (var index = 0; index < 5; index++) {
      canvas.drawLine(
        Offset(size.width * 0.24, size.height * (0.18 + index * 0.08)),
        Offset(size.width * 0.42, size.height * (0.14 + index * 0.1)),
        Paint()
          ..color = accent.withAlpha(32)
          ..strokeWidth = 1.6,
      );
    }
  }

  void _drawServerCloset(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    for (var index = 0; index < 3; index++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * (0.08 + index * 0.09),
          size.height * 0.26,
          size.width * 0.07,
          size.height * 0.42,
        ),
        const Radius.circular(14),
      );
      canvas.drawRRect(rect, Paint()..color = primary.withAlpha(34));
      for (var row = 0; row < 5; row++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              rect.left + 10,
              rect.top + 12 + row * 26,
              rect.width - 20,
              10,
            ),
            const Radius.circular(6),
          ),
          Paint()..color = accent.withAlpha(24 + row * 8),
        );
      }
    }
  }

  void _drawCommandRoom(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    for (var index = 0; index < 4; index++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * (0.58 + index * 0.08),
          size.height * 0.18,
          size.width * 0.07,
          size.height * 0.16,
        ),
        const Radius.circular(12),
      );
      canvas.drawRRect(rect, Paint()..color = Colors.black.withAlpha(64));
      canvas.drawRRect(
        rect.deflate(4),
        Paint()..color = accent.withAlpha(44 + index * 8),
      );
    }
  }

  void _drawAutonomousWorkspace(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    for (var index = 0; index < 3; index++) {
      final center = Offset(size.width * (0.2 + index * 0.13), size.height * 0.3);
      canvas.drawCircle(center, 14 + progress * 8, Paint()..color = primary.withAlpha(28));
      for (final angle in <double>[0, math.pi / 2, math.pi, math.pi * 1.5]) {
        final offset = Offset(math.cos(angle), math.sin(angle)) * 24;
        canvas.drawLine(
          center,
          center + offset,
          Paint()
            ..color = accent.withAlpha(44)
            ..strokeWidth = 2,
        );
      }
    }
  }

  void _drawResearchApartment(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    for (var index = 0; index < 3; index++) {
      final shelf = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.8,
          size.height * (0.2 + index * 0.14),
          size.width * 0.1,
          size.height * 0.08,
        ),
        const Radius.circular(10),
      );
      canvas.drawRRect(shelf, Paint()..color = primary.withAlpha(24));
      for (var item = 0; item < 4; item++) {
        canvas.drawRect(
          Rect.fromLTWH(
            shelf.left + 10 + item * 18,
            shelf.top + 12,
            10,
            shelf.height - 24,
          ),
          Paint()..color = accent.withAlpha(32 + item * 6),
        );
      }
    }
  }

  void _drawContainmentLoft(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    final center = Offset(size.width * 0.82, size.height * 0.42);
    for (var ring = 0; ring < 3; ring++) {
      canvas.drawCircle(
        center,
        size.height * (0.06 + ring * 0.045),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = accent.withAlpha(40 + ring * 18),
      );
    }
  }

  void _drawPrototypeChamber(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    final reactor = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.74, size.height * 0.44, size.width * 0.12, size.height * 0.22),
      const Radius.circular(22),
    );
    canvas.drawRRect(reactor, Paint()..color = primary.withAlpha(36));
    canvas.drawCircle(
      reactor.center,
      reactor.width * 0.16,
      Paint()..color = accent.withAlpha(66),
    );
  }

  void _drawSyntheticStudio(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.16, size.width * 0.16, size.height * 0.34),
      const Radius.circular(20),
    );
    canvas.drawRRect(frame, Paint()..color = primary.withAlpha(24));
    canvas.drawRRect(
      frame.deflate(12),
      Paint()..color = accent.withAlpha(28),
    );
  }

  void _drawCorporateSuite(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    final window = Rect.fromLTWH(size.width * 0.74, size.height * 0.08, size.width * 0.2, size.height * 0.28);
    canvas.drawRect(window, Paint()..color = accent.withAlpha(24));
    for (var index = 0; index < 5; index++) {
      final x = window.left + window.width * (index / 5);
      canvas.drawLine(
        Offset(x, window.top),
        Offset(x, window.bottom),
        Paint()
          ..color = Colors.white.withAlpha(16)
          ..strokeWidth = 2,
      );
    }
  }

  void _drawDataCathedral(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    for (var index = 0; index < 3; index++) {
      final left = size.width * (0.12 + index * 0.2);
      final path = Path()
        ..moveTo(left, size.height * 0.64)
        ..lineTo(left + size.width * 0.04, size.height * 0.2)
        ..lineTo(left + size.width * 0.08, size.height * 0.64);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = primary.withAlpha(34),
      );
    }
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.26),
      size.height * 0.07,
      Paint()..color = accent.withAlpha(30),
    );
  }

  void _drawSimulationChamber(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    final paint = Paint()
      ..color = accent.withAlpha(26)
      ..strokeWidth = 1.5;
    for (var index = 0; index < 10; index++) {
      final ratio = index / 9;
      canvas.drawLine(
        Offset(size.width * 0.62, size.height * (0.16 + ratio * 0.34)),
        Offset(size.width * 0.9, size.height * (0.12 + ratio * 0.42)),
        paint,
      );
      canvas.drawLine(
        Offset(size.width * (0.62 + ratio * 0.28), size.height * 0.16),
        Offset(size.width * (0.6 + ratio * 0.3), size.height * 0.56),
        paint,
      );
    }
  }

  void _drawOrbitalHabitat(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    final viewport = Rect.fromCircle(
      center: Offset(size.width * 0.82, size.height * 0.26),
      radius: size.height * 0.12,
    );
    canvas.drawOval(viewport, Paint()..color = Colors.white.withAlpha(16));
    canvas.drawOval(
      viewport.deflate(10),
      Paint()..color = accent.withAlpha(30),
    );
    canvas.drawCircle(
      Offset(viewport.center.dx + viewport.width * 0.08, viewport.center.dy + viewport.height * 0.02),
      viewport.width * 0.12,
      Paint()..color = Colors.white.withAlpha(36),
    );
  }

  void _drawPlanetaryForge(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    final center = Offset(size.width * 0.2, size.height * 0.32);
    canvas.drawCircle(center, size.height * 0.1, Paint()..color = primary.withAlpha(30));
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.18,
        height: size.height * 0.06,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = accent.withAlpha(50),
    );
  }

  void _drawChronoRoom(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    final center = Offset(size.width * 0.78, size.height * 0.38);
    for (var ring = 0; ring < 4; ring++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: size.height * (0.05 + ring * 0.035)),
        math.pi * (0.2 + ring * 0.12),
        math.pi * (0.9 - ring * 0.08),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = accent.withAlpha(32 + ring * 12),
      );
    }
  }

  void _drawKernelChamber(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    final rect = Rect.fromCenter(
      center: Offset(size.width * 0.8, size.height * 0.34),
      width: size.width * 0.18,
      height: size.height * 0.2,
    );
    final paint = Paint()
      ..color = accent.withAlpha(34)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(18)), paint);
    canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
    canvas.drawLine(rect.topRight, rect.bottomLeft, paint);
  }

  void _drawQuietSingularity(Canvas canvas, Size size, Color primary, Color accent, double progress) {
    final center = Offset(size.width * 0.5, size.height * 0.32);
    canvas.drawCircle(center, size.height * 0.09, Paint()..color = accent.withAlpha(44));
    canvas.drawCircle(
      center,
      size.height * 0.14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withAlpha(26),
    );
  }

  static Color _colorFromHex(String hex) {
    final normalized = hex.replaceAll('#', '');
    final buffer = StringBuffer();
    if (normalized.length == 6) buffer.write('ff');
    buffer.write(normalized);
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  bool shouldRepaint(covariant _RoomSceneBackdropPainter oldDelegate) {
    return oldDelegate.room != room ||
        oldDelegate.roomState != roomState ||
        oldDelegate.reducedMotion != reducedMotion;
  }
}
