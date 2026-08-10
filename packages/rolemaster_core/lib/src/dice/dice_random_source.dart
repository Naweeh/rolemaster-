import 'dart:math';

abstract interface class DiceRandomSource {
  int nextInt(int upperBoundExclusive);
}

final class DefaultDiceRandomSource implements DiceRandomSource {
  DefaultDiceRandomSource([Random? random]) : _random = random ?? Random();

  final Random _random;

  @override
  int nextInt(int upperBoundExclusive) => _random.nextInt(upperBoundExclusive);
}
