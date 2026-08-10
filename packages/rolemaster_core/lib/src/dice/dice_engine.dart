import '../ruleset/effective_ruleset.dart';
import 'dice_formula.dart';
import 'dice_random_source.dart';
import 'dice_roll_result.dart';

typedef DiceRollIdGenerator = String Function();
typedef DiceClock = DateTime Function();

final class DiceEngine {
  DiceEngine({
    required DiceRandomSource randomSource,
    required DiceRollIdGenerator idGenerator,
    required DiceClock clock,
  })  : _randomSource = randomSource,
        _idGenerator = idGenerator,
        _clock = clock;

  final DiceRandomSource _randomSource;
  final DiceRollIdGenerator _idGenerator;
  final DiceClock _clock;

  DiceRollResult roll({
    required EffectiveRuleset ruleset,
    required DiceFormula formula,
    String? purpose,
  }) {
    final rolls = <int>[];
    for (var index = 0; index < formula.count; index++) {
      final zeroBased = _randomSource.nextInt(formula.sides);
      if (zeroBased < 0 || zeroBased >= formula.sides) {
        throw StateError(
          'DiceRandomSource returned $zeroBased for upper bound '
          '${formula.sides}.',
        );
      }
      rolls.add(zeroBased + 1);
    }

    return DiceRollResult(
      id: _idGenerator(),
      campaignId: ruleset.campaignId,
      rulesetId: ruleset.rulesetId,
      rulesetVersion: ruleset.version,
      formula: formula,
      rolls: rolls,
      purpose: purpose,
      occurredAt: _clock(),
    );
  }
}
