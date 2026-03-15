import 'package:flutter/material.dart';

/// Rarity level for an event result banner — drives styling.
enum EventResultRarity { common, uncommon, rare, epic, legendary }

/// A banner that shows a result message when an event resolves.
///
/// Supports rarity styling and an optional detail line that summarises what
/// actually changed (currency, buff, secret clue, room progression, etc.).
class EventResultBanner extends StatelessWidget {
  /// The main message to display (e.g. event title).
  final String message;

  /// Optional secondary line describing what changed.
  final String? detail;

  /// Rarity of the event — controls accent color and icon.
  final EventResultRarity rarity;

  /// Explicit accent color override.  If null, the color is derived from
  /// [rarity].
  final Color? color;

  const EventResultBanner({
    super.key,
    required this.message,
    this.detail,
    this.rarity = EventResultRarity.common,
    this.color,
  });

  Color get _accentColor {
    if (color != null) return color!;
    switch (rarity) {
      case EventResultRarity.common:
        return const Color(0xFF74E6FF); // cyan-ish
      case EventResultRarity.uncommon:
        return Colors.greenAccent;
      case EventResultRarity.rare:
        return Colors.purpleAccent;
      case EventResultRarity.epic:
        return Colors.deepOrangeAccent;
      case EventResultRarity.legendary:
        return Colors.amberAccent;
    }
  }

  IconData get _icon {
    switch (rarity) {
      case EventResultRarity.common:
        return Icons.check_circle_outline_rounded;
      case EventResultRarity.uncommon:
        return Icons.auto_awesome_rounded;
      case EventResultRarity.rare:
        return Icons.star_rounded;
      case EventResultRarity.epic:
        return Icons.bolt_rounded;
      case EventResultRarity.legendary:
        return Icons.workspace_premium_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withAlpha(28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withAlpha(110)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(_icon, color: accent, size: 16),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    detail!,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
