import 'combat_state.dart';

abstract interface class CombatStateRepository {
  Future<CombatState?> getByEncounterId(String encounterId);

  /// Saves the initial revision once, then compares every later revision.
  /// Throws StateError if the stored revision or encounter changes.
  Future<void> save(CombatState state);
}
