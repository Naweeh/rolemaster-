import 'encounter.dart';
import 'encounter_exceptions.dart';
import 'encounter_participant.dart';
import 'encounter_repository.dart';

final class AddEncounterParticipant {
  AddEncounterParticipant({
    required EncounterRepository repository,
    required DateTime Function() clock,
  })  : _repository = repository,
        _clock = clock;

  final EncounterRepository _repository;
  final DateTime Function() _clock;

  Future<Encounter> call({
    required String encounterId,
    required String entityType,
    required String entityId,
    String? label,
  }) async {
    final normalizedId = encounterId.trim();
    final encounter = await _repository.getById(normalizedId);
    if (encounter == null) {
      throw EncounterNotFoundException(normalizedId);
    }

    final updated = encounter.addParticipant(
      EncounterParticipant(
        entityType: entityType,
        entityId: entityId,
        label: label,
      ),
      at: _clock(),
    );
    await _repository.save(updated);
    return updated;
  }
}
