import 'campaign_configuration.dart';
import 'campaign_metadata.dart';

final class Campaign {
  Campaign({
    required String id,
    required String name,
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
    CampaignMetadata? metadata,
    CampaignConfiguration? configuration,
  })  : id = id.trim(),
        name = name.trim(),
        createdAt = createdAt.toUtc(),
        updatedAt = (updatedAt ?? createdAt).toUtc(),
        archivedAt = archivedAt?.toUtc(),
        metadata = metadata ?? CampaignMetadata(),
        configuration = configuration ?? const CampaignConfiguration() {
    if (this.id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Campaign id cannot be empty.');
    }
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Campaign name cannot be empty.');
    }
    if (this.updatedAt.isBefore(this.createdAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'Campaign updatedAt cannot be before createdAt.',
      );
    }
    if (this.archivedAt != null && this.archivedAt!.isBefore(this.createdAt)) {
      throw ArgumentError.value(
        archivedAt,
        'archivedAt',
        'Campaign archivedAt cannot be before createdAt.',
      );
    }
  }

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final CampaignMetadata metadata;
  final CampaignConfiguration configuration;

  bool get isArchived => archivedAt != null;

  Campaign update({
    String? name,
    CampaignMetadata? metadata,
    CampaignConfiguration? configuration,
    required DateTime at,
  }) {
    if (isArchived) {
      throw StateError('Archived campaigns cannot be updated.');
    }
    if (name == null && metadata == null && configuration == null) {
      throw ArgumentError(
        'At least one Campaign field must be provided for update.',
      );
    }

    final normalizedAt = at.toUtc();
    if (normalizedAt.isBefore(updatedAt)) {
      throw ArgumentError.value(
        at,
        'at',
        'Campaign changes cannot move backwards in time.',
      );
    }

    return Campaign(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: normalizedAt,
      metadata: metadata ?? this.metadata,
      configuration: configuration ?? this.configuration,
    );
  }

  Campaign rename({required String name, required DateTime at}) {
    return update(name: name, at: at);
  }

  Campaign archive({required DateTime at}) {
    if (isArchived) {
      return this;
    }

    final normalizedAt = at.toUtc();
    if (normalizedAt.isBefore(updatedAt)) {
      throw ArgumentError.value(
        at,
        'at',
        'Campaign changes cannot move backwards in time.',
      );
    }

    return Campaign(
      id: id,
      name: name,
      createdAt: createdAt,
      updatedAt: normalizedAt,
      archivedAt: normalizedAt,
      metadata: metadata,
      configuration: configuration,
    );
  }
}
