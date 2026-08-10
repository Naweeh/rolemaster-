final class DiceFormula {
  DiceFormula({
    required this.count,
    required this.sides,
    this.modifier = 0,
  }) {
    if (count <= 0) {
      throw ArgumentError.value(count, 'count', 'Dice count must be positive.');
    }
    if (sides < 2) {
      throw ArgumentError.value(
          sides, 'sides', 'Dice sides must be at least 2.');
    }
  }

  final int count;
  final int sides;
  final int modifier;

  String get notation {
    final suffix = modifier == 0
        ? ''
        : modifier > 0
            ? '+$modifier'
            : '$modifier';
    return '${count}d$sides$suffix';
  }
}
