import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolemaster_app/src/app/error_logging.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('installRolemasterErrorLogging', () {
    late FlutterExceptionHandler? previousFlutterHandler;
    late bool Function(Object, StackTrace)? previousPlatformHandler;

    setUp(() {
      previousFlutterHandler = FlutterError.onError;
      previousPlatformHandler = PlatformDispatcher.instance.onError;
    });

    tearDown(() {
      FlutterError.onError = previousFlutterHandler;
      PlatformDispatcher.instance.onError = previousPlatformHandler;
    });

    test('logs Flutter errors without exception messages', () {
      var previousCalled = false;
      FlutterError.onError = (_) {
        previousCalled = true;
      };
      final events = <(String, Map<String, Object?>)>[];

      installRolemasterErrorLogging(
        sink: (event, fields) => events.add((event, fields)),
      );
      FlutterError.onError!(
        FlutterErrorDetails(
          exception: StateError('secret campaign title'),
          stack: StackTrace.current,
        ),
      );

      expect(events, hasLength(1));
      expect(events.single.$1, 'ui.unhandled_error');
      expect(events.single.$2['errorType'], 'StateError');
      expect(events.single.$2['stackTrace'], isNotNull);
      expect(events.single.$2.toString(), isNot(contains('secret campaign')));
      expect(previousCalled, isTrue);
    });

    test('logs platform errors and preserves the previous handler', () {
      var previousCalled = false;
      PlatformDispatcher.instance.onError = (_, __) {
        previousCalled = true;
        return true;
      };
      final events = <(String, Map<String, Object?>)>[];

      installRolemasterErrorLogging(
        sink: (event, fields) => events.add((event, fields)),
      );
      final handled = PlatformDispatcher.instance.onError!(
        ArgumentError('secret campaign title'),
        StackTrace.current,
      );

      expect(handled, isTrue);
      expect(previousCalled, isTrue);
      expect(events, hasLength(1));
      expect(events.single.$1, 'app.unhandled_error');
      expect(events.single.$2['errorType'], 'ArgumentError');
      expect(events.single.$2['stackTrace'], isNotNull);
      expect(events.single.$2.toString(), isNot(contains('secret campaign')));
    });
  });
}
