import 'encounter.dart';
import 'encounter_exceptions.dart';
import 'encounter_repository.dart';

final class GetEncounter {
  GetEncounter(this._repository);

  final EncounterRepository _repository;

  Future<Encounter> call(String encounterId) async {
    final normalizedId = encounterId.trim();
    final encounter = await _repository.getById(normalizedId);
    if (encounter == null) {
      throw EncounterNotFoundException(normalizedId);
    }
    return encounter;
  }
}
