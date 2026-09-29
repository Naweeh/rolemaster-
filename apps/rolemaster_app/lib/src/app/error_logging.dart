import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

typedef RolemasterErrorSink = void Function(
  String event,
  Map<String, Object?> fields,
);

/// Records an error already handled by the UI without including its message.
void recordHandledRolemasterError(
  String event,
  Object error, {
  RolemasterErrorSink? sink,
}) {
  try {
    final fields = <String, Object?>{
      'errorType': error.runtimeType.toString(),
    };
    if (sink != null) {
      sink(event, fields);
    } else {
      developer.log('$event ${jsonEncode(fields)}', name: 'rolemaster.app');
    }
  } catch (_) {
    // Diagnostics must not replace the UI's original error handling.
  }
}

/// Installs privacy-conscious handlers for uncaught application errors.
///
/// The original exception message is deliberately omitted because it may
/// contain campaign data. Existing Flutter and platform handlers still run.
void installRolemasterErrorLogging({RolemasterErrorSink? sink}) {
  void record(String event, Object error, StackTrace? stackTrace) {
    final fields = <String, Object?>{
      'errorType': error.runtimeType.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
    if (sink != null) {
      sink(event, fields);
      return;
    }
    developer.log(
      '$event ${jsonEncode(fields)}',
      name: 'rolemaster.app',
    );
  }

  final previousFlutterHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    record('ui.unhandled_error', details.exception, details.stack);
    previousFlutterHandler?.call(details);
  };

  final dispatcher = PlatformDispatcher.instance;
  final previousPlatformHandler = dispatcher.onError;
  dispatcher.onError = (error, stackTrace) {
    record('app.unhandled_error', error, stackTrace);
    return previousPlatformHandler?.call(error, stackTrace) ?? false;
  };
}
