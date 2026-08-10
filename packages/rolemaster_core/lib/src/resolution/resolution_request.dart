final class ResolutionRequest {
  ResolutionRequest({
    required String ruleId,
    Map<String, Object?> inputs = const <String, Object?>{},
    String? purpose,
  })  : ruleId = _required(ruleId, 'ruleId'),
        inputs = Map<String, Object?>.unmodifiable(inputs),
        purpose = _optional(purpose);

  final String ruleId;
  final Map<String, Object?> inputs;
  final String? purpose;
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, '$field cannot be empty.');
  }
  return normalized;
}

String? _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
