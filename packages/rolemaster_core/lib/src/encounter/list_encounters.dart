import 'encounter.dart';
import 'encounter_repository.dart';
import 'encounter_status.dart';

final class ListEncounters {
  ListEncounters(this._repository);

  final EncounterRepository _repository;

  Future<List<Encounter>> call(
    String campaignId, {
    EncounterStatus? status,
  }) {
    final normalizedCampaignId = campaignId.trim();
    if (normalizedCampaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'Encounter campaignId cannot be empty.',
      );
    }
    return _repository.getForCampaign(
      normalizedCampaignId,
      status: status,
    );
  }
}
