import 'encounter_participant.dart';
import 'encounter_status.dart';

final class Encounter {
  Encounter({
    required String id,
    required String campaignId,
    required String name,
    EncounterStatus status = EncounterStatus.planned,
    Iterable<EncounterParticipant> participants =
        const <EncounterParticipant>[],
    String? worldId,
    String? locationId,
    String? sceneMapId,
    String? notes,
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? closedAt,
  })  : id = _required(id, 'id'),
        campaignId = _required(campaignId, 'campaignId'),
        name = _required(name, 'name'),
        status = status,
        participants = List<EncounterParticipant>.unmodifiable(participants),
        worldId = _optional(worldId),
        locationId = _optional(locationId),
        sceneMapId = _optional(sceneMapId),
        notes = _optional(notes),
        createdAt = createdAt.toUtc(),
        updatedAt = (updatedAt ?? createdAt).toUtc(),
        startedAt = startedAt?.toUtc(),
        closedAt = closedAt?.toUtc() {
    if (this.locationId != null && this.worldId == null) {
      throw ArgumentError('Encounter locationId requires worldId.');
    }
    if (this.updatedAt.isBefore(this.createdAt)) {
      throw ArgumentError('Encounter updatedAt cannot be before createdAt.');
    }
    if (this.startedAt != null && this.startedAt!.isBefore(this.createdAt)) {
      throw ArgumentError('Encounter startedAt cannot be before createdAt.');
    }
    if (this.closedAt != null && this.closedAt!.isBefore(this.createdAt)) {
      throw ArgumentError('Encounter closedAt cannot be before createdAt.');
    }
    if (status == EncounterStatus.planned &&
        (this.startedAt != null || this.closedAt != null)) {
      throw ArgumentError(
          'Planned encounters cannot have start/close timestamps.');
    }
    if (status == EncounterStatus.active && this.startedAt == null) {
      throw ArgumentError('Active encounters require startedAt.');
    }
    if (status == EncounterStatus.active && this.closedAt != null) {
      throw ArgumentError('Active encounters cannot have closedAt.');
    }
    if (status == EncounterStatus.closed &&
        (this.startedAt == null || this.closedAt == null)) {
      throw ArgumentError('Closed encounters require startedAt and closedAt.');
    }
    if (this.startedAt != null &&
        this.closedAt != null &&
        this.closedAt!.isBefore(this.startedAt!)) {
      throw ArgumentError('Encounter closedAt cannot be before startedAt.');
    }

    final seen = <String>{};
    for (final participant in this.participants) {
      if (!seen.add(participant.key)) {
        throw ArgumentError(
            'Encounter participants must be unique by entityType/entityId.');
      }
    }
  }

  final String id;
  final String campaignId;
  final String name;
  final EncounterStatus status;
  final List<EncounterParticipant> participants;
  final String? worldId;
  final String? locationId;
  final String? sceneMapId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? closedAt;

  Encounter addParticipant(
    EncounterParticipant participant, {
    required DateTime at,
  }) {
    if (status == EncounterStatus.closed) {
      throw StateError('Closed encounters cannot change participants.');
    }
    if (participants.any((item) => item.key == participant.key)) {
      throw StateError(
          'Encounter participant already exists: ${participant.key}.');
    }
    return _copyWith(
      participants: <EncounterParticipant>[...participants, participant],
      updatedAt: _normalizedChangeTime(at),
    );
  }

  Encounter removeParticipant({
    required String entityType,
    required String entityId,
    required DateTime at,
  }) {
    if (status == EncounterStatus.closed) {
      throw StateError('Closed encounters cannot change participants.');
    }
    final key = '${entityType.trim().toLowerCase()}:${entityId.trim()}';
    final updatedParticipants =
        participants.where((item) => item.key != key).toList();
    if (updatedParticipants.length == participants.length) {
      throw StateError('Encounter participant not found: $key.');
    }
    return _copyWith(
      participants: updatedParticipants,
      updatedAt: _normalizedChangeTime(at),
    );
  }

  Encounter start({required DateTime at}) {
    if (status != EncounterStatus.planned) {
      throw StateError('Only planned encounters can be started.');
    }
    final normalizedAt = _normalizedChangeTime(at);
    return _copyWith(
      status: EncounterStatus.active,
      startedAt: normalizedAt,
      updatedAt: normalizedAt,
    );
  }

  Encounter close({required DateTime at}) {
    if (status != EncounterStatus.active) {
      throw StateError('Only active encounters can be closed.');
    }
    final normalizedAt = _normalizedChangeTime(at);
    return _copyWith(
      status: EncounterStatus.closed,
      closedAt: normalizedAt,
      updatedAt: normalizedAt,
    );
  }

  DateTime _normalizedChangeTime(DateTime at) {
    final normalized = at.toUtc();
    if (normalized.isBefore(updatedAt)) {
      throw ArgumentError('Encounter changes cannot move backwards in time.');
    }
    return normalized;
  }

  Encounter _copyWith({
    EncounterStatus? status,
    List<EncounterParticipant>? participants,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? closedAt,
  }) {
    return Encounter(
      id: id,
      campaignId: campaignId,
      name: name,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      worldId: worldId,
      locationId: locationId,
      sceneMapId: sceneMapId,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: startedAt ?? this.startedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }
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
