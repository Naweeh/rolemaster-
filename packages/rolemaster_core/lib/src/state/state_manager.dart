import 'campaign_state.dart';
import 'campaign_state_repository.dart';
import 'state_change.dart';
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
      for (final change in transaction.changes) {
        invokedChanges.add(change);
        try {
          await change.apply();
        } catch (cause) {
          final rollbackFailures = await _rollback(invokedChanges);
          throw StateTransactionException(
            cause: cause,
            rollbackFailures: rollbackFailures,
          );
        }
      }

      final next = current.advance(transaction.changedAt);
      late final bool saved;
      try {
        saved = await _repository.save(
          next,
          expectedRevision: current.revision,
        );
      } catch (cause) {
        final rollbackFailures = await _rollback(invokedChanges);
        throw StateTransactionException(
          cause: cause,
          rollbackFailures: rollbackFailures,
        );
      }

      if (!saved) {
        final actual = await getState(transaction.campaignId);
        final conflict = StateRevisionConflictException(
          campaignId: transaction.campaignId,
          expectedRevision: current.revision,
          actualRevision: actual.revision,
        );
        final rollbackFailures = await _rollback(invokedChanges);
        if (rollbackFailures.isEmpty) {
          throw conflict;
        }
        throw StateTransactionException(
          cause: conflict,
          rollbackFailures: rollbackFailures,
        );
      }

      return next;
    } finally {
      _activeCampaigns.remove(transaction.campaignId);
    }
  }

  Future<List<Object>> _rollback(List<StateChange> changes) async {
    final failures = <Object>[];
    for (final change in changes.reversed) {
      try {
        await change.rollback();
      } catch (failure) {
        failures.add(failure);
      }
    }
    return failures;
  }
}
