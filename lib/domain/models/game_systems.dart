/// Purchase quantity modes for buying upgrades and generators.
enum PurchaseMode {
  x1('1x'),
  x10('10x'),
  x100('100x'),
  max('MAX');

  final String label;
  const PurchaseMode(this.label);
}

/// AI personality traits that shape the AI companion's behavior.
enum AITrait {
  helpful('Helpful'),
  obsessive('Obsessive'),
  chaotic('Chaotic'),
  transcendent('Transcendent');

  final String label;
  const AITrait(this.label);
}

/// Possible game endings.
class Ending {
  final String id;
  final String name;
  final String description;

  const Ending({
    required this.id,
    required this.name,
    this.description = '',
  });

  factory Ending.fromJson(Map<String, dynamic> json) {
    return Ending(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}
