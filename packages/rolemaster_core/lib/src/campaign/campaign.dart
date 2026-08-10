final class Campaign {
  Campaign({
    required String id,
    required String name,
    required this.createdAt,
  })  : id = id.trim(),
        name = name.trim() {
    if (this.id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Campaign id cannot be empty.');
    }
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Campaign name cannot be empty.');
    }
  }

  final String id;
  final String name;
  final DateTime createdAt;
}
