final class StateRevisionConflictException implements Exception {
  StateRevisionConflictException({
    required this.campaignId,
    required this.expectedRevision,
    required this.actualRevision,
  });

  final String campaignId;
  final int expectedRevision;
  final int actualRevision;

  @override
  String toString() {
    return 'Campaign state revision conflict for $campaignId: '
        'expected $expectedRevision, actual $actualRevision.';
  }
}

final class StateTransactionInProgressException implements Exception {
  StateTransactionInProgressException(this.campaignId);

  final String campaignId;

  @override
  String toString() => 'State transaction already in progress: $campaignId';
}

final class StateTransactionException implements Exception {
  StateTransactionException({
    required this.cause,
    Iterable<Object> rollbackFailures = const <Object>[],
  }) : rollbackFailures = List<Object>.unmodifiable(rollbackFailures);

  final Object cause;
  final List<Object> rollbackFailures;

  @override
  String toString() {
    return 'State transaction failed: $cause; '
        'rollback failures: ${rollbackFailures.length}.';
  }
}
