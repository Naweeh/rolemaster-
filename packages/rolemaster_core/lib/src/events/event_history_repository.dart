import 'domain_event.dart';

abstract interface class EventHistoryRepository {
  Future<void> append(DomainEvent event);

  Future<DomainEvent?> getById(String id);

  Future<List<DomainEvent>> getForCampaign(
    String campaignId, {
    String? type,
    int? limit,
  });
}
