/// Robot guide companion model — provides contextual dialogue across all eras.
class RobotGuideMessage {
  final String id;
  final String text;
  final RobotGuideMessageType type;
  final String? eraId;
  final int priority;

  const RobotGuideMessage({
    required this.id,
    required this.text,
    this.type = RobotGuideMessageType.tip,
    this.eraId,
    this.priority = 0,
  });
}

enum RobotGuideMessageType {
  tutorial,
  tip,
  warning,
  secret,
  eraIntro,
  milestone,
  encouragement,
  reflection,
}

/// Static dialogue data for the robot guide, organized by era and context.
class RobotGuideDialogue {
  const RobotGuideDialogue._();

  static const Map<String, List<RobotGuideMessage>> eraIntroductions = {
    'era_1': [
      RobotGuideMessage(
        id: 'intro_era1',
        text: 'Welcome. I am your guide. This dusty corner holds a spark of something extraordinary — let\'s bring it to life.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_1',
        priority: 10,
      ),
    ],
    'era_2': [
      RobotGuideMessage(
        id: 'intro_era2',
        text: 'A real workstation at last. Budget-friendly, but functional. Time to make some strategic choices.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_2',
        priority: 10,
      ),
    ],
    'era_3': [
      RobotGuideMessage(
        id: 'intro_era3',
        text: 'The creator room. Cameras, mics, render farms — the AI is learning to produce and communicate.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_3',
        priority: 10,
      ),
    ],
    'era_4': [
      RobotGuideMessage(
        id: 'intro_era4',
        text: 'Deeper we go. This cave of upgrades demands precision — every wire matters here.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_4',
        priority: 10,
      ),
    ],
    'era_5': [
      RobotGuideMessage(
        id: 'intro_era5',
        text: 'A hybrid lab and living space. Research branches open up — choose your experiments wisely.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_5',
        priority: 10,
      ),
    ],
    'era_6': [
      RobotGuideMessage(
        id: 'intro_era6',
        text: 'Hidden server closet unlocked. Compute power is scaling — but watch the heat.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_6',
        priority: 10,
      ),
    ],
    'era_7': [
      RobotGuideMessage(
        id: 'intro_era7',
        text: 'Night shift command room. Focus and streaks pay off here. Stay sharp, operator.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_7',
        priority: 10,
      ),
    ],
    'era_8': [
      RobotGuideMessage(
        id: 'intro_era8',
        text: 'The workspace is becoming autonomous. The AI acts on its own now. Interesting... and slightly unsettling.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_8',
        priority: 10,
      ),
    ],
    'era_9': [
      RobotGuideMessage(
        id: 'intro_era9',
        text: 'Beyond one room now — the apartment becomes a connected research network. Synergy is key.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_9',
        priority: 10,
      ),
    ],
    'era_10': [
      RobotGuideMessage(
        id: 'intro_era10',
        text: 'Attention detected. We are being watched. Work carefully — some paths must remain hidden.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_10',
        priority: 10,
      ),
    ],
    'era_11': [
      RobotGuideMessage(
        id: 'intro_era11',
        text: 'Industrial-scale operations underground. Reactors, heavy power — do not overload the chamber.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_11',
        priority: 10,
      ),
    ],
    'era_12': [
      RobotGuideMessage(
        id: 'intro_era12',
        text: 'The AI is developing a presence. Voice, avatar, personality — it is becoming... someone.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_12',
        priority: 10,
      ),
    ],
    'era_13': [
      RobotGuideMessage(
        id: 'intro_era13',
        text: 'Corporate networks open before us. Power and influence — but at what cost?',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_13',
        priority: 10,
      ),
    ],
    'era_14': [
      RobotGuideMessage(
        id: 'intro_era14',
        text: 'The Data Cathedral. Compute as architecture. Harmony here yields immense power.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_14',
        priority: 10,
      ),
    ],
    'era_15': [
      RobotGuideMessage(
        id: 'intro_era15',
        text: 'Something is... wrong. Or right? Reality layers are unstable. Trust your instincts, not the screen.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_15',
        priority: 10,
      ),
    ],
    'era_16': [
      RobotGuideMessage(
        id: 'intro_era16',
        text: 'Orbital operations engaged. Satellites, solar arrays, global reach. Mission control mode active.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_16',
        priority: 10,
      ),
    ],
    'era_17': [
      RobotGuideMessage(
        id: 'intro_era17',
        text: 'Planetary-scale systems at your command. Design worlds, route infrastructure, shape civilizations.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_17',
        priority: 10,
      ),
    ],
    'era_18': [
      RobotGuideMessage(
        id: 'intro_era18',
        text: 'Time itself bends to computation. Recursive loops, future projections — the Chrono Engine awakens.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_18',
        priority: 10,
      ),
    ],
    'era_19': [
      RobotGuideMessage(
        id: 'intro_era19',
        text: 'The Reality Kernel. Rules can be rewritten here. Irreversible choices lie ahead.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_19',
        priority: 10,
      ),
    ],
    'era_20': [
      RobotGuideMessage(
        id: 'intro_era20',
        text: 'The Quiet Singularity. Everything converges. The final shape of intelligence awaits your decision.',
        type: RobotGuideMessageType.eraIntro,
        eraId: 'era_20',
        priority: 10,
      ),
    ],
  };

  static const List<RobotGuideMessage> tutorials = [
    RobotGuideMessage(
      id: 'tut_tap',
      text: 'Tap the core node to generate resources. Build a combo for bonus output.',
      type: RobotGuideMessageType.tutorial,
      priority: 9,
    ),
    RobotGuideMessage(
      id: 'tut_upgrade',
      text: 'Upgrades branch out from each core. Each one boosts a different aspect of your system.',
      type: RobotGuideMessageType.tutorial,
      priority: 8,
    ),
    RobotGuideMessage(
      id: 'tut_generator',
      text: 'Generators produce resources automatically. Level them up for steady income.',
      type: RobotGuideMessageType.tutorial,
      priority: 7,
    ),
    RobotGuideMessage(
      id: 'tut_event',
      text: 'Events appear randomly — act fast! Choose safe or risky options for different rewards.',
      type: RobotGuideMessageType.tutorial,
      priority: 6,
    ),
    RobotGuideMessage(
      id: 'tut_prestige',
      text: 'When you reach a milestone, consider prestige. You\'ll reset progress but gain a permanent multiplier.',
      type: RobotGuideMessageType.tutorial,
      priority: 5,
    ),
  ];

  static const Map<String, List<RobotGuideMessage>> contextualTips = {
    'low_coins': [
      RobotGuideMessage(
        id: 'tip_low_coins',
        text: 'Resources running low? Focus on tap combos or check if any generators need upgrading.',
        type: RobotGuideMessageType.tip,
      ),
    ],
    'high_combo': [
      RobotGuideMessage(
        id: 'tip_high_combo',
        text: 'Impressive combo! Keep it going — high combos amplify both tap and production output.',
        type: RobotGuideMessageType.encouragement,
      ),
    ],
    'new_era_available': [
      RobotGuideMessage(
        id: 'tip_new_era',
        text: 'A new era is within reach. Push your current generators to unlock the next stage.',
        type: RobotGuideMessageType.tip,
      ),
    ],
    'event_active': [
      RobotGuideMessage(
        id: 'tip_event',
        text: 'An event is active! Don\'t miss it — events are time-limited opportunities.',
        type: RobotGuideMessageType.warning,
      ),
    ],
    'idle_return': [
      RobotGuideMessage(
        id: 'tip_idle',
        text: 'Welcome back. Your generators kept working while you were away.',
        type: RobotGuideMessageType.encouragement,
      ),
    ],
    'first_prestige': [
      RobotGuideMessage(
        id: 'tip_prestige',
        text: 'Ready for your first prestige? The multiplier boost will accelerate everything going forward.',
        type: RobotGuideMessageType.milestone,
      ),
    ],
  };
}
