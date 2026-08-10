import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('DomainEvent', () {
    test('normalizes fields and freezes JSON payload deeply', () {
      final sourceList = <Object?>['uno'];
      final event = DomainEvent(
        id: ' event-1 ',
        type: ' world.location_added ',
        campaignId: ' campaign-1 ',
        occurredAt: DateTime(2026, 8, 10, 12),
        entityType: ' location ',
        entityId: ' location-1 ',
        payload: <String, Object?>{
          'name': 'Posada',
          'nested': <String, Object?>{'values': sourceList},
        },
      );

      sourceList.add('dos');

      expect(event.id, 'event-1');
      expect(event.type, 'world.location_added');
      expect(event.campaignId, 'campaign-1');
      expect(event.occurredAt.isUtc, isTrue);
      expect(event.entityType, 'location');
      expect(event.entityId, 'location-1');
      final nested = event.payload['nested'] as Map<String, Object?>;
      expect(nested['values'], <Object?>['uno']);
      expect(() => event.payload['new'] = true, throwsUnsupportedError);
      expect(
        () => (nested['values'] as List<Object?>).add('tres'),
        throwsUnsupportedError,
      );
    });

    test('rejects non JSON-safe nested payload values', () {
      expect(
        () => DomainEvent(
          id: 'event-1',
          type: 'test.event',
          campaignId: 'campaign-1',
          occurredAt: DateTime.utc(2026, 8, 10),
          payload: <String, Object?>{'invalid': DateTime.utc(2026, 8, 10)},
        ),
        throwsArgumentError,
      );
    });
  });
}
