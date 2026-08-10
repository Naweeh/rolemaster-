import 'package:rolemaster_core/rolemaster_core.dart';

final class InMemoryCampaignRepository implements CampaignRepository {
  final List<Campaign> _campaigns = <Campaign>[];

  @override
  Future<List<Campaign>> getAll() async {
    return List<Campaign>.unmodifiable(_campaigns);
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
