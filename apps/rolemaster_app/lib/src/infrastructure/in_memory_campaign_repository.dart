import 'package:rolemaster_core/rolemaster_core.dart';

final class InMemoryCampaignRepository implements CampaignRepository {
  final List<Campaign> _campaigns = <Campaign>[];

  @override
  Future<Campaign?> getById(String id) async {
    for (final campaign in _campaigns) {
      if (campaign.id == id) {
        return campaign;
      }
    }
    return null;
  }

  @override
  Future<List<Campaign>> getAll({bool includeArchived = false}) async {
    final campaigns = includeArchived
        ? _campaigns
        : _campaigns.where((campaign) => !campaign.isArchived);
    return List<Campaign>.unmodifiable(campaigns);
  }

  @override
  Future<void> save(Campaign campaign) async {
    final index = _campaigns.indexWhere((item) => item.id == campaign.id);
    if (index >= 0) {
      _campaigns[index] = campaign;
      return;
    }
    _campaigns.add(campaign);
  }
}
