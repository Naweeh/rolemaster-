import 'domain_event.dart';
import 'event_bus.dart';

final class InMemoryDomainEventBus implements DomainEventBus {
  final List<_Subscription> _subscriptions = <_Subscription>[];

  @override
  EventSubscription subscribe({
    String? type,
    required DomainEventHandler handler,
  }) {
    final normalizedType = _normalizeOptionalType(type);
    final subscription = _Subscription(
      type: normalizedType,
      handler: handler,
      onCancel: _removeSubscription,
    );
    _subscriptions.add(subscription);
    return subscription;
  }

  @override
  Future<void> publish(DomainEvent event) async {
    final snapshot = List<_Subscription>.of(_subscriptions);
    for (final subscription in snapshot) {
      if (subscription.isCancelled) {
        continue;
      }
      if (subscription.type != null && subscription.type != event.type) {
        continue;
      }
      await subscription.handler(event);
    }
  }

  void _removeSubscription(_Subscription subscription) {
    _subscriptions.remove(subscription);
  }

  String? _normalizeOptionalType(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

final class _Subscription implements EventSubscription {
  _Subscription({
    required this.type,
    required this.handler,
    required void Function(_Subscription subscription) onCancel,
  }) : _onCancel = onCancel;

  final String? type;
  final DomainEventHandler handler;
  final void Function(_Subscription subscription) _onCancel;

  bool _cancelled = false;

  @override
  bool get isCancelled => _cancelled;

  @override
  void cancel() {
    if (_cancelled) {
      return;
    }
    _cancelled = true;
    _onCancel(this);
  }
}
