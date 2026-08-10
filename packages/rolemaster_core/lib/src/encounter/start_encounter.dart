import 'encounter.dart';
import 'encounter_exceptions.dart';
import 'encounter_repository.dart';

final class StartEncounter {
  StartEncounter({
    required EncounterRepository repository,
    required DateTime Function() clock,
  })  : _repository = repository,
        _clock = clock;

  final EncounterRepository _repository;
  final DateTime Function() _clock;

  Future<Encounter> call(String encounterId) async {
    final normalizedId = encounterId.trim();
    final encounter = await _repository.getById(normalizedId);
    if (encounter == null) {
      throw EncounterNotFoundException(normalizedId);
    }
    final updated = encounter.start(at: _clock());
    await _repository.save(updated);
    return updated;
  }
}
