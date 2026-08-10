import 'domain_event.dart';
import 'event_bus.dart';
import 'event_history_repository.dart';

final class DomainEventDispatcher {
  DomainEventDispatcher({
    required EventHistoryRepository history,
    required DomainEventBus bus,
  })  : _history = history,
        _bus = bus;

  final EventHistoryRepository _history;
  final DomainEventBus _bus;

  Future<void> dispatch(DomainEvent event) async {
    await _history.append(event);
    await _bus.publish(event);
  }
}
