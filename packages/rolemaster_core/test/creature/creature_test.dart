import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('Creature', () {
    test('normalizes identity, species, category and placement', () {
      final creature = Creature(
        id: ' creature-1 ',
        campaignId: ' campaign-1 ',
        name: ' Lobo Gris ',
        createdAt: DateTime.parse('2026-08-10T12:00:00-03:00'),
        metadata: CreatureMetadata(
          species: ' Lobo ',
          category: ' Bestia ',
          tags: <String>['salvaje', ' Salvaje ', 'bosque'],
        ),
        placement: CreaturePlacement(
          worldId: ' world-1 ',
          locationId: ' location-1 ',
        ),
      );

      expect(creature.id, 'creature-1');
      expect(creature.campaignId, 'campaign-1');
      expect(creature.name, 'Lobo Gris');
      expect(creature.createdAt, DateTime.utc(2026, 8, 10, 15));
      expect(creature.metadata.species, 'Lobo');
      expect(creature.metadata.category, 'Bestia');
      expect(creature.metadata.tags, <String>['salvaje', 'bosque']);
      expect(creature.placement.worldId, 'world-1');
      expect(creature.placement.locationId, 'location-1');
    });

    test('location requires a world', () {
      expect(
        () => CreaturePlacement(locationId: 'location-1'),
        throwsArgumentError,
      );
    });

    test('updates and can explicitly become unplaced', () {
      final creature = Creature(
        id: 'creature-1',
        campaignId: 'campaign-1',
        name: 'Lobo',
        createdAt: DateTime.utc(2026, 8, 10, 10),
        metadata: CreatureMetadata(species: 'Lobo'),
        placement: CreaturePlacement(
          worldId: 'world-1',
          locationId: 'location-1',
        ),
      );

      final updated = creature.update(
        metadata: CreatureMetadata(species: 'Lobo', category: 'Bestia'),
        placement: CreaturePlacement.unplaced(),
        at: DateTime.utc(2026, 8, 10, 11),
      );

      expect(updated.metadata.category, 'Bestia');
      expect(updated.placement.isPlaced, isFalse);
    });

    test('archive is idempotent and blocks updates', () {
      final creature = Creature(
        id: 'creature-1',
        campaignId: 'campaign-1',
        name: 'Lobo',
        createdAt: DateTime.utc(2026, 8, 10, 10),
        metadata: CreatureMetadata(species: 'Lobo'),
      );
      final archived = creature.archive(at: DateTime.utc(2026, 8, 10, 11));

      expect(archived.isArchived, isTrue);
      expect(
        archived.archive(at: DateTime.utc(2026, 8, 10, 12)),
        same(archived),
      );
      expect(
        () => archived.update(
          name: 'No permitido',
          at: DateTime.utc(2026, 8, 10, 12),
        ),
        throwsStateError,
      );
    });
  });
}
