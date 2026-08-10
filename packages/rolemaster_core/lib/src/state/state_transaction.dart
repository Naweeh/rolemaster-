import 'state_change.dart';

final class StateTransaction {
  StateTransaction({
    required String campaignId,
    required this.expectedRevision,
    required Iterable<StateChange> changes,
    required DateTime changedAt,
  })  : campaignId = campaignId.trim(),
        changes = List<StateChange>.unmodifiable(changes),
        changedAt = changedAt.toUtc() {
    if (this.campaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'State transaction campaignId cannot be empty.',
      );
    }
    if (expectedRevision < 0) {
      throw ArgumentError.value(
        expectedRevision,
        'expectedRevision',
        'State transaction expectedRevision cannot be negative.',
      );
    }
    if (this.changes.isEmpty) {
      throw ArgumentError('State transaction must contain at least one change.');
    }
  }

  final String campaignId;
  final int expectedRevision;
  final List<StateChange> changes;
  final DateTime changedAt;
}
