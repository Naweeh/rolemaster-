import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('Npc', () {
    test('normalizes language profile and placement', () {
      final npc = Npc(
        id: ' npc-1 ',
        campaignId: ' campaign-1 ',
        name: ' El Guardián ',
        createdAt: DateTime.parse('2026-08-10T12:00:00-03:00'),
        metadata: NpcMetadata(
          nativeLanguage: ' Sindarin ',
          knownLanguages: <String>['Común', ' sindarin ', 'común', ''],
          role: ' Guardián ',
          tags: <String>['aliado', ' Aliado ', 'elfo'],
        ),
        placement: NpcPlacement(
          worldId: ' world-1 ',
          locationId: ' location-1 ',
        ),
      );

      expect(npc.id, 'npc-1');
      expect(npc.campaignId, 'campaign-1');
      expect(npc.name, 'El Guardián');
      expect(npc.createdAt, DateTime.utc(2026, 8, 10, 15));
      expect(npc.metadata.nativeLanguage, 'Sindarin');
      expect(npc.metadata.knownLanguages, <String>['Común']);
      expect(npc.metadata.spokenLanguages, <String>['Sindarin', 'Común']);
      expect(npc.metadata.role, 'Guardián');
      expect(npc.metadata.tags, <String>['aliado', 'elfo']);
      expect(npc.placement.worldId, 'world-1');
      expect(npc.placement.locationId, 'location-1');
    });

    test('location requires a world', () {
      expect(
        () => NpcPlacement(locationId: 'location-1'),
        throwsArgumentError,
      );
    });

    test('updates placement and can explicitly become unplaced', () {
      final npc = Npc(
        id: 'npc-1',
        campaignId: 'campaign-1',
        name: 'Guardián',
        createdAt: DateTime.utc(2026, 8, 10, 10),
        metadata: NpcMetadata(nativeLanguage: 'Común'),
        placement: NpcPlacement(worldId: 'world-1', locationId: 'location-1'),
      );

      final updated = npc.update(
        placement: NpcPlacement.unplaced(),
        at: DateTime.utc(2026, 8, 10, 11),
      );

      expect(updated.placement.isPlaced, isFalse);
      expect(updated.id, npc.id);
      expect(updated.createdAt, npc.createdAt);
    });

    test('archive is idempotent and blocks updates', () {
      final npc = Npc(
        id: 'npc-1',
        campaignId: 'campaign-1',
        name: 'Guardián',
        createdAt: DateTime.utc(2026, 8, 10, 10),
        metadata: NpcMetadata(nativeLanguage: 'Común'),
      );
      final archived = npc.archive(at: DateTime.utc(2026, 8, 10, 11));

      expect(archived.isArchived, isTrue);
      expect(archived.archive(at: DateTime.utc(2026, 8, 10, 12)), same(archived));
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
