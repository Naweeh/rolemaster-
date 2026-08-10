import 'encounter.dart';
import 'encounter_status.dart';

abstract interface class EncounterRepository {
  Future<Encounter?> getById(String id);

  Future<List<Encounter>> getForCampaign(
    String campaignId, {
    EncounterStatus? status,
  });

  Future<void> save(Encounter encounter);
}
