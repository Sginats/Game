import 'package:flutter/material.dart';

import '../../application/services/app_strings.dart';
import '../../application/services/robot_guide_service.dart';
import '../../domain/models/codex.dart';

/// Isolated guide-card widget.
///
/// Manages its own rebuild surface: dismissing a guide message or toggling
/// the recommendation panel only rebuilds this card, not [GameScreen].
///
/// The card is driven by snapshot values passed from the parent. The parent
/// updates these on its normal timer-driven rebuild (≤250 ms), which is fast
/// enough that the user never perceives the latency.
class GuideCard extends StatefulWidget {
  final RobotGuideService guideService;
  final AppStrings strings;

  /// The most recent AI recommendation line, if any.
  final String? recommendation;

  /// The most recent AI flavour line, if any.
  final String? aiLine;

  /// Up to 2 recent guide memories, already extracted by the parent.
  final List<GuideMemoryLog> recentMemories;

  /// Called when the user taps "focus suggested node" inside the card.
  final VoidCallback onFocusSuggestedNode;

  const GuideCard({
    super.key,
    required this.guideService,
    required this.strings,
    required this.recommendation,
    required this.aiLine,
    required this.recentMemories,
    required this.onFocusSuggestedNode,
  });

  @override
  State<GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<GuideCard> {
  @override
  Widget build(BuildContext context) {
    final guideMessage = widget.guideService.currentMessage;

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
          Row(
            children: [
              const Icon(Icons.smart_toy_rounded,
                  color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.strings.robotGuide,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (guideMessage != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withAlpha(14)),
                  ),
                  child: Text(
                    widget.strings
                        .formatGuideMemoryType(guideMessage.type.name),
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (guideMessage != null) const SizedBox(width: 6),
              if (guideMessage != null)
                IconButton(
                  // Dismiss only rebuilds this card — not GameScreen.
                  onPressed: () => setState(widget.guideService.dismiss),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  splashRadius: 18,
                  color: Colors.white54,
                  tooltip: widget.strings.close,
                ),
            ],
          ),
          Text(
            guideMessage == null
                ? widget.strings.noGuideMessage
                : widget.strings.translateContent(guideMessage.text),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (widget.recommendation != null || widget.aiLine != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withAlpha(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.strings.recommendedNext,
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.recommendation != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      widget.strings.formatRecommendation(widget.recommendation!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (widget.aiLine != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.strings.formatAiLine(widget.aiLine!),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: widget.onFocusSuggestedNode,
                    icon: const Icon(Icons.my_location_rounded, size: 16),
                    label: Text(widget.strings.focusSuggestedNode),
                  ),
                ],
              ),
            ),
          ],
          if (widget.recentMemories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.strings.guideMemoryLog,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ...widget.recentMemories.map(
              (memory) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${widget.strings.translateContent(memory.title)}: ${widget.strings.translateContent(memory.content)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
