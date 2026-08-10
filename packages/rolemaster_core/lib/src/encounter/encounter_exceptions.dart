final class EncounterNotFoundException implements Exception {
  EncounterNotFoundException(this.encounterId);

  final String encounterId;

  @override
  String toString() => 'Encounter not found: $encounterId';
}

final class EncounterContextException implements Exception {
  EncounterContextException(this.message);

  final String message;

  @override
  String toString() => 'Invalid encounter context: $message';
}
