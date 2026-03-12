/// Era model — a room evolution era in the game.
class Era {
  final String id;
  final String name;
  final String description;
  final int order;
  final String? unlockRequirement;
  final String currency;
  final String rule;

  const Era({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    this.unlockRequirement,
    this.currency = 'Scrap',
    this.rule = '',
  });

  factory Era.fromJson(Map<String, dynamic> json) {
    return Era(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      order: json['order'] as int,
      unlockRequirement: json['unlockRequirement'] as String?,
      currency: json['currency'] as String? ?? 'Scrap',
      rule: json['rule'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'order': order,
        'unlockRequirement': unlockRequirement,
        'currency': currency,
        'rule': rule,
      };
}
