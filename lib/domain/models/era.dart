/// Era model — a technology era in the game.
class Era {
  final String id;
  final String name;
  final String description;
  final int order;
  final String? unlockRequirement;

  const Era({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    this.unlockRequirement,
  });

  factory Era.fromJson(Map<String, dynamic> json) {
    return Era(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      order: json['order'] as int,
      unlockRequirement: json['unlockRequirement'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'order': order,
        'unlockRequirement': unlockRequirement,
      };
}
