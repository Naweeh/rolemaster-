import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('Character', () {
    test('normalizes identity and metadata', () {
      final character = Character(
        id: ' character-1 ',
        campaignId: ' campaign-1 ',
        name: ' Aria ',
        createdAt: DateTime.parse('2026-08-10T12:00:00-03:00'),
        metadata: CharacterMetadata(
          playerName: ' Alex ',
          description: ' Exploradora ',
          notes: ' Nota ',
          tags: <String>['Heroe', ' heroe ', '', 'Grupo A'],
        ),
      );

      expect(character.id, 'character-1');
      expect(character.campaignId, 'campaign-1');
      expect(character.name, 'Aria');
      expect(character.createdAt, DateTime.utc(2026, 8, 10, 15));
      expect(character.updatedAt, character.createdAt);
      expect(character.metadata.playerName, 'Alex');
      expect(character.metadata.description, 'Exploradora');
      expect(character.metadata.notes, 'Nota');
      expect(character.metadata.tags, <String>['Heroe', 'Grupo A']);
    });

    test('updates without changing identity or creation timestamp', () {
      final createdAt = DateTime.utc(2026, 8, 10, 10);
      final character = Character(
        id: 'character-1',
        campaignId: 'campaign-1',
        name: 'Aria',
        createdAt: createdAt,
      );

      final updated = character.update(
        name: 'Aria II',
        metadata: CharacterMetadata(playerName: 'Alex'),
        at: DateTime.utc(2026, 8, 10, 11),
      );

      expect(updated.id, character.id);
      expect(updated.campaignId, character.campaignId);
      expect(updated.createdAt, createdAt);
      expect(updated.updatedAt, DateTime.utc(2026, 8, 10, 11));
      expect(updated.name, 'Aria II');
      expect(updated.metadata.playerName, 'Alex');
    });

    test('archive is idempotent and blocks later updates', () {
      final character = Character(
        id: 'character-1',
        campaignId: 'campaign-1',
        name: 'Aria',
        createdAt: DateTime.utc(2026, 8, 10, 10),
      );
      final archived = character.archive(at: DateTime.utc(2026, 8, 10, 11));

      expect(archived.isArchived, isTrue);
      expect(
          archived.archive(at: DateTime.utc(2026, 8, 10, 12)), same(archived));
      expect(
        () => archived.update(
          name: 'No permitido',
          at: DateTime.utc(2026, 8, 10, 12),
        ),
        throwsStateError,
      );
    });

    test('rejects backwards timestamps', () {
      final character = Character(
        id: 'character-1',
        campaignId: 'campaign-1',
        name: 'Aria',
        createdAt: DateTime.utc(2026, 8, 10, 10),
        updatedAt: DateTime.utc(2026, 8, 10, 11),
      );

      expect(
        () => character.update(
          name: 'Aria II',
          at: DateTime.utc(2026, 8, 10, 10, 59),
        ),
        throwsArgumentError,
      );
    });
  });
}
