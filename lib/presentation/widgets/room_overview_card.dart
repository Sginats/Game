import 'package:flutter/material.dart';

import '../../application/services/app_strings.dart';
import '../../domain/models/room_scene.dart';

/// Isolated room-overview card widget.
///
/// Displays a summary of the current room's narrative flavor, ambient
/// setup, transformation progress, and environment-change chips.
///
/// Extracting this into its own [StatefulWidget] means that updates to
/// the room scene (transformation advance, twist activation) only rebuild
/// this card. The parent [GameScreen] still passes updated values every
/// timer tick, but repaint is isolated to this widget's own compositor
/// layer via the [RepaintBoundary] applied at the call site.
class RoomOverviewCard extends StatelessWidget {
  final RoomScene room;
  final RoomSceneState roomState;
  final AppStrings strings;

  const RoomOverviewCard({
    super.key,
    required this.room,
    required this.roomState,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final nextStageIndex = roomState.currentTransformationStage + 1;
    final nextStage = nextStageIndex < room.transformationStages.length
        ? room.transformationStages[nextStageIndex]
        : null;
    final currentStageIndex = room.transformationStages.isEmpty
        ? 0
        : roomState.currentTransformationStage
            .clamp(0, room.transformationStages.length - 1);
    final currentStage = room.transformationStages.isEmpty
        ? null
        : room.transformationStages[currentStageIndex];
    final stageProgress = room.transformationStages.isEmpty
        ? 0.0
        : ((roomState.currentTransformationStage + 1) /
                room.transformationStages.length)
            .clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.roomOverview,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.translateContent(room.guideIntroLine),
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                Icons.psychology_alt_rounded,
                '${strings.guideToneLabel}: ${strings.translateContent(room.guideTone)}',
              ),
              _chip(
                Icons.graphic_eq_rounded,
                '${strings.ambientLayersLabel}: ${room.ambientAudioLayers.length}',
              ),
              _chip(
                Icons.auto_awesome_motion_rounded,
                '${strings.secretsTrackedLabel}: ${room.secrets.length}',
              ),
              _chip(
                Icons.bolt_rounded,
                '${strings.twistStatusLabel}: ${roomState.twistActivated ? strings.transformationReady : strings.transformationDormant}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            strings.transformationTrack,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: stageProgress,
            minHeight: 6,
            backgroundColor: Colors.white.withAlpha(12),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 6),
          Text(
            nextStage == null
                ? strings.translateContent(room.completionText)
                : '${strings.translateContent(nextStage.name)}\n${strings.translateContent(nextStage.description)}',
            style: const TextStyle(
                color: Colors.white60, fontSize: 12, height: 1.35),
          ),
          if (currentStage != null) ...[
            const SizedBox(height: 10),
            Text(
              strings.environmentChanges,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: currentStage.environmentChanges
                  .map(
                    (change) => _chip(
                      Icons.blur_on_rounded,
                      strings.formatEnvironmentChange(change),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white60),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
