import 'package:flutter/material.dart';

import '../../domain/models/room_scene.dart';

/// A panel widget that shows the current room's status, including its law,
/// transformation progress, landmark, hazard warning, and twist indicator.
///
/// Expandable sections let the player drill into details without cluttering the
/// default view.
class RoomStatusPanel extends StatefulWidget {
  final RoomScene room;
  final RoomSceneState roomState;
  final int upgradesPurchased;

  const RoomStatusPanel({
    super.key,
    required this.room,
    required this.roomState,
    required this.upgradesPurchased,
  });

  @override
  State<RoomStatusPanel> createState() => _RoomStatusPanelState();
}

class _RoomStatusPanelState extends State<RoomStatusPanel> {
  bool _lawExpanded = false;
  bool _landmarkExpanded = false;

  // Alpha for secondary/dim icon and chevron colors.
  static const int _kSecondaryAlpha = 160;

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final roomState = widget.roomState;
    final upgradesPurchased = widget.upgradesPurchased;

    final nextStageIndex = roomState.currentTransformationStage + 1;
    final nextStage = nextStageIndex < room.transformationStages.length
        ? room.transformationStages[nextStageIndex]
        : null;
    final requiredForNext = nextStage?.requiredUpgrades ?? 0;
    final transformationProgress = nextStage == null || requiredForNext <= 0
        ? 1.0
        : (upgradesPurchased / requiredForNext).clamp(0.0, 1.0);

    return Card(
      color: const Color(0xFF141824),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoomHeader(room),
            const SizedBox(height: 10),
            if (room.roomLaw != null) ...[
              _buildDivider(),
              _buildRoomLawSection(room.roomLaw!),
              const SizedBox(height: 8),
            ],
            _buildDivider(),
            _buildTransformationProgress(
              transformationProgress,
              nextStage,
              upgradesPurchased,
            ),
            if (room.landmark != null) ...[
              const SizedBox(height: 8),
              _buildDivider(),
              _buildLandmarkSection(room.landmark!),
            ],
            if (room.hazard != null) ...[
              const SizedBox(height: 8),
              _buildDivider(),
              _buildHazardWarning(room.hazard!),
            ],
            if (roomState.twistActivated && room.midSceneTwist != null) ...[
              const SizedBox(height: 8),
              _buildDivider(),
              _buildTwistIndicator(room.midSceneTwist!),
            ],
            _buildDivider(),
            _buildMasteryGoalSummary(room, roomState),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomHeader(RoomScene room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          room.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          room.subtitle,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomLawSection(RoomLaw law) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _lawExpanded = !_lawExpanded),
          child: Row(
            children: [
              const Icon(
                Icons.gavel_rounded,
                color: Colors.cyanAccent,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Room Law: ${law.name}',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(
                _lawExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: Colors.cyanAccent.withAlpha(_kSecondaryAlpha),
                size: 16,
              ),
            ],
          ),
        ),
        if (_lawExpanded) ...[
          const SizedBox(height: 4),
          Text(
            law.description,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTransformationProgress(
    double progress,
    TransformationStage? nextStage,
    int bought,
  ) {
    final label = nextStage == null
        ? 'Transformation Complete'
        : '${nextStage.name} — $bought / ${nextStage.requiredUpgrades} upgrades';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.transform_rounded,
              color: Colors.amberAccent,
              size: 14,
            ),
            const SizedBox(width: 6),
            const Text(
              'Transformation',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildLandmarkSection(RoomLandmark landmark) {
    final stageDescription =
        landmark.evolutionStages.isNotEmpty &&
                landmark.currentStage < landmark.evolutionStages.length
            ? landmark.evolutionStages[landmark.currentStage]
            : landmark.description;
    final hasStages = landmark.evolutionStages.length > 1;
    final stageLabel = hasStages
        ? 'Stage ${landmark.currentStage + 1}/${landmark.evolutionStages.length}'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () =>
              setState(() => _landmarkExpanded = !_landmarkExpanded),
          child: Row(
            children: [
              const Icon(
                Icons.place_rounded,
                color: Colors.purpleAccent,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  landmark.name,
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              if (hasStages)
                Text(
                  stageLabel,
                  style: TextStyle(
                    color: Colors.purpleAccent.withAlpha(_kSecondaryAlpha),
                    fontSize: 10,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                _landmarkExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: Colors.purpleAccent.withAlpha(_kSecondaryAlpha),
                size: 16,
              ),
            ],
          ),
        ),
        if (_landmarkExpanded) ...[
          const SizedBox(height: 4),
          Text(
            stageDescription,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHazardWarning(RoomHazard hazard) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hazard: ${hazard.name}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                Text(
                  hazard.description,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwistIndicator(MidSceneTwist twist) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepOrangeAccent.withAlpha(100)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.deepOrangeAccent,
            size: 14,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Twist Active: ${twist.title}',
                  style: const TextStyle(
                    color: Colors.deepOrangeAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                if (twist.effectDescription.isNotEmpty)
                  Text(
                    twist.effectDescription,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryGoalSummary(RoomScene room, RoomSceneState roomState) {
    final secrets = roomState.secretsDiscovered.length;
    final totalSecrets = room.secrets.length;
    final eventsCompleted = roomState.eventsCompleted;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Room Goals',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _goalChip(
                icon: Icons.lock_open_rounded,
                label: 'Secrets $secrets/$totalSecrets',
                done: secrets >= totalSecrets && totalSecrets > 0,
              ),
              const SizedBox(width: 6),
              _goalChip(
                icon: Icons.event_available_rounded,
                label: 'Events $eventsCompleted',
                done: eventsCompleted >= 3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _goalChip({
    required IconData icon,
    required String label,
    required bool done,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: done
            ? Colors.greenAccent.withAlpha(20)
            : Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: done
              ? Colors.greenAccent.withAlpha(80)
              : Colors.white.withAlpha(25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: done ? Colors.greenAccent : Colors.white54,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: done ? Colors.greenAccent : Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Divider(
        color: Colors.white.withAlpha(15),
        height: 1,
      ),
    );
  }
}
