import 'dart:async';

import 'domain_event.dart';

typedef DomainEventHandler = FutureOr<void> Function(DomainEvent event);

abstract interface class EventSubscription {
  bool get isCancelled;

  void cancel();
}

abstract interface class DomainEventBus {
  EventSubscription subscribe({
    String? type,
    required DomainEventHandler handler,
  });

  Future<void> publish(DomainEvent event);
}
