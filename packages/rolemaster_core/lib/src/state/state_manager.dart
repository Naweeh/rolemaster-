import 'campaign_state.dart';
import 'campaign_state_repository.dart';
import 'state_exceptions.dart';
import 'state_transaction.dart';

final class StateManager {
  StateManager({required CampaignStateRepository repository})
      : _repository = repository;

  final CampaignStateRepository _repository;
  final Set<String> _activeCampaigns = <String>{};

  Future<CampaignState> getState(String campaignId) async {
    final normalizedCampaignId = campaignId.trim();
    if (normalizedCampaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'State Manager campaignId cannot be empty.',
      );
    }
    return await _repository.getByCampaignId(normalizedCampaignId) ??
        CampaignState.initial(normalizedCampaignId);
  }

  Future<CampaignState> execute(StateTransaction transaction) async {
    if (!_activeCampaigns.add(transaction.campaignId)) {
      throw StateTransactionInProgressException(transaction.campaignId);
    }

    try {
      final current = await getState(transaction.campaignId);
      if (current.revision != transaction.expectedRevision) {
        throw StateRevisionConflictException(
          campaignId: transaction.campaignId,
          expectedRevision: transaction.expectedRevision,
          actualRevision: current.revision,
        );
      }
      if (current.updatedAt != null &&
          transaction.changedAt.isBefore(current.updatedAt!)) {
        throw ArgumentError.value(
          transaction.changedAt,
          'changedAt',
          'State transaction cannot move backwards in time.',
        );
      }

      for (final change in transaction.changes) {
        await change.validate();
      }

      final invokedChanges = <StateChange>[];
      try {
        for (final change in transaction.changes) {
          invokedChanges.add(change);
          await change.apply();
        }

        final next = current.advance(transaction.changedAt);
        await _repository.save(next);
        return next;
      } catch (cause) {
        final rollbackFailures = <Object>[];
        for (final change in invokedChanges.reversed) {
          try {
            await change.rollback();
          } catch (rollbackFailure) {
            rollbackFailures.add(rollbackFailure);
          }
        }
        throw StateTransactionException(
          cause: cause,
          rollbackFailures: rollbackFailures,
        );
      }
    } finally {
      _activeCampaigns.remove(transaction.campaignId);
    }
  }
}
