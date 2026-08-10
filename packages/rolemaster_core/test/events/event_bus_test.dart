import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryDomainEventBus', () {
    test('delivers wildcard and typed subscriptions in registration order',
        () async {
      final bus = InMemoryDomainEventBus();
      final calls = <String>[];
      bus.subscribe(handler: (event) => calls.add('all:${event.id}'));
      bus.subscribe(
        type: DomainEventTypes.worldLocationAdded,
        handler: (event) => calls.add('typed:${event.id}'),
      );
      bus.subscribe(
        type: DomainEventTypes.combatStarted,
        handler: (event) => calls.add('other:${event.id}'),
      );

      await bus.publish(_event('event-1'));

      expect(calls, <String>['all:event-1', 'typed:event-1']);
    });

    test('cancel is idempotent and prevents later delivery', () async {
      final bus = InMemoryDomainEventBus();
      var calls = 0;
      final subscription = bus.subscribe(handler: (_) => calls++);

      subscription.cancel();
      subscription.cancel();
      await bus.publish(_event('event-1'));

      expect(subscription.isCancelled, isTrue);
      expect(calls, 0);
    });

    test('awaits handlers sequentially', () async {
      final bus = InMemoryDomainEventBus();
      final calls = <String>[];
      bus.subscribe(handler: (_) async {
        calls.add('first-start');
        await Future<void>.delayed(Duration.zero);
        calls.add('first-end');
      });
      bus.subscribe(handler: (_) => calls.add('second'));

      await bus.publish(_event('event-1'));

      expect(calls, <String>['first-start', 'first-end', 'second']);
    });
  });

  group('DomainEventDispatcher', () {
    test('appends to history before publishing', () async {
      final operations = <String>[];
      final history = _RecordingHistory(operations: operations);
      final bus = InMemoryDomainEventBus();
      bus.subscribe(handler: (event) => operations.add('publish:${event.id}'));
      final dispatcher = DomainEventDispatcher(history: history, bus: bus);

      await dispatcher.dispatch(_event('event-1'));

      expect(operations, <String>['append:event-1', 'publish:event-1']);
      expect(await history.getById('event-1'), isNotNull);
    });

    test('does not publish when history append fails', () async {
      final history = _RecordingHistory(failAppend: true);
      final bus = InMemoryDomainEventBus();
      var published = false;
      bus.subscribe(handler: (_) => published = true);
      final dispatcher = DomainEventDispatcher(history: history, bus: bus);

      await expectLater(dispatcher.dispatch(_event('event-1')), throwsStateError);

      expect(published, isFalse);
    });
  });
}

DomainEvent _event(String id) {
  return DomainEvent(
    id: id,
    type: DomainEventTypes.worldLocationAdded,
    campaignId: 'campaign-1',
    occurredAt: DateTime.utc(2026, 8, 10, 12),
    entityType: 'location',
    entityId: 'location-1',
    payload: const <String, Object?>{'name': 'Posada'},
  );
}

final class _RecordingHistory implements EventHistoryRepository {
  _RecordingHistory({this.failAppend = false, List<String>? operations})
      : operations = operations ?? <String>[];

  final bool failAppend;
  final List<String> operations;
  final List<DomainEvent> _events = <DomainEvent>[];

  @override
  Future<void> append(DomainEvent event) async {
    if (failAppend) {
      throw StateError('history failed');
    }
    operations.add('append:${event.id}');
    _events.add(event);
  }

  @override
  Future<DomainEvent?> getById(String id) async {
    for (final event in _events) {
      if (event.id == id) {
        return event;
      }
    }
    return null;
  }

  @override
  Future<List<DomainEvent>> getForCampaign(
    String campaignId, {
    String? type,
    int? limit,
  }) async {
    var events = _events
        .where(
          (event) =>
              event.campaignId == campaignId &&
              (type == null || event.type == type),
        )
        .toList(growable: false);
    if (limit != null && limit < events.length) {
      events = events.sublist(events.length - limit);
    }
    return events;
  }
}
