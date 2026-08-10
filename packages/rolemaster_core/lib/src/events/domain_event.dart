final class DomainEvent {
  DomainEvent({
    required String id,
    required String type,
    required String campaignId,
    required DateTime occurredAt,
    String? entityType,
    String? entityId,
    Map<String, Object?> payload = const <String, Object?>{},
  })  : id = id.trim(),
        type = type.trim(),
        campaignId = campaignId.trim(),
        occurredAt = occurredAt.toUtc(),
        entityType = _normalizeOptionalText(entityType),
        entityId = _normalizeOptionalText(entityId),
        payload = _freezePayload(payload) {
    if (this.id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Domain event id cannot be empty.');
    }
    if (this.type.isEmpty) {
      throw ArgumentError.value(
          type, 'type', 'Domain event type cannot be empty.');
    }
    if (this.campaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'Domain event campaignId cannot be empty.',
      );
    }
  }

  final String id;
  final String type;
  final String campaignId;
  final DateTime occurredAt;
  final String? entityType;
  final String? entityId;
  final Map<String, Object?> payload;

  static String? _normalizeOptionalText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static Map<String, Object?> _freezePayload(Map<String, Object?> payload) {
    return Map<String, Object?>.unmodifiable(
      payload.map(
        (key, value) => MapEntry<String, Object?>(key, _freezeJsonValue(value)),
      ),
    );
  }

  static Object? _freezeJsonValue(Object? value) {
    if (value == null || value is bool || value is num || value is String) {
      return value;
    }
    if (value is List) {
      return List<Object?>.unmodifiable(value.map(_freezeJsonValue));
    }
    if (value is Map) {
      final frozen = <String, Object?>{};
      for (final entry in value.entries) {
        if (entry.key is! String) {
          throw ArgumentError.value(
            value,
            'payload',
            'Domain event payload maps must use String keys.',
          );
        }
        frozen[entry.key as String] = _freezeJsonValue(entry.value);
      }
      return Map<String, Object?>.unmodifiable(frozen);
    }
    throw ArgumentError.value(
      value,
      'payload',
      'Domain event payload must contain JSON-safe values.',
    );
  }
}
