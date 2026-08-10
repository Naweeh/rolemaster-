import 'dart:async';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('StateManager', () {
    test('validates all changes before applying and advances revision', () async {
      final log = <String>[];
      final repository = _MemoryStateRepository();
      final manager = StateManager(repository: repository);
      final first = _RecordingChange(name: 'first', log: log);
      final second = _RecordingChange(name: 'second', log: log);

      final state = await manager.execute(
        StateTransaction(
          campaignId: 'campaign-1',
          expectedRevision: 0,
          changes: <StateChange>[first, second],
          changedAt: DateTime.utc(2026, 8, 10, 12),
        ),
      );

      expect(log, <String>[
        'validate:first',
        'validate:second',
        'apply:first',
        'apply:second',
      ]);
      expect(state.revision, 1);
      expect((await manager.getState('campaign-1')).revision, 1);
    });

    test('validation failure applies nothing and preserves revision', () async {
      final log = <String>[];
      final repository = _MemoryStateRepository();
      final manager = StateManager(repository: repository);
      final first = _RecordingChange(name: 'first', log: log);
      final second = _RecordingChange(
        name: 'second',
        log: log,
        validationError: StateError('invalid'),
      );

      await expectLater(
        manager.execute(
          StateTransaction(
            campaignId: 'campaign-1',
            expectedRevision: 0,
            changes: <StateChange>[first, second],
            changedAt: DateTime.utc(2026, 8, 10, 12),
          ),
        ),
        throwsStateError,
      );

      expect(log, <String>['validate:first', 'validate:second']);
      expect((await manager.getState('campaign-1')).revision, 0);
    });

    test('apply failure rolls back invoked changes in reverse order', () async {
      final log = <String>[];
      final repository = _MemoryStateRepository();
      final manager = StateManager(repository: repository);
      final first = _RecordingChange(name: 'first', log: log);
      final second = _RecordingChange(
        name: 'second',
        log: log,
        applyError: StateError('apply failed'),
      );

      await expectLater(
        manager.execute(
          StateTransaction(
            campaignId: 'campaign-1',
            expectedRevision: 0,
            changes: <StateChange>[first, second],
            changedAt: DateTime.utc(2026, 8, 10, 12),
          ),
        ),
        throwsA(isA<StateTransactionException>()),
      );

      expect(log, <String>[
        'validate:first',
        'validate:second',
        'apply:first',
        'apply:second',
        'rollback:second',
        'rollback:first',
      ]);
      expect((await manager.getState('campaign-1')).revision, 0);
    });

    test('state persistence failure rolls back applied changes', () async {
      final log = <String>[];
      final repository = _MemoryStateRepository(failSave: true);
      final manager = StateManager(repository: repository);
      final change = _RecordingChange(name: 'change', log: log);

      await expectLater(
        manager.execute(
          StateTransaction(
            campaignId: 'campaign-1',
            expectedRevision: 0,
            changes: <StateChange>[change],
            changedAt: DateTime.utc(2026, 8, 10, 12),
          ),
        ),
        throwsA(isA<StateTransactionException>()),
      );

      expect(log, <String>[
        'validate:change',
        'apply:change',
        'rollback:change',
      ]);
    });

    test('reports revision conflicts before validation', () async {
      final repository = _MemoryStateRepository(
        initial: <CampaignState>[
          CampaignState(
            campaignId: 'campaign-1',
            revision: 2,
            updatedAt: DateTime.utc(2026, 8, 10, 11),
          ),
        ],
      );
      final log = <String>[];
      final manager = StateManager(repository: repository);

      await expectLater(
        manager.execute(
          StateTransaction(
            campaignId: 'campaign-1',
            expectedRevision: 1,
            changes: <StateChange>[
              _RecordingChange(name: 'change', log: log),
            ],
            changedAt: DateTime.utc(2026, 8, 10, 12),
          ),
        ),
        throwsA(isA<StateRevisionConflictException>()),
      );

      expect(log, isEmpty);
    });

    test('rejects concurrent transactions for the same campaign', () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final repository = _MemoryStateRepository();
      final manager = StateManager(repository: repository);
      final blocking = _RecordingChange(
        name: 'blocking',
        log: <String>[],
        onApply: () async {
          entered.complete();
          await release.future;
        },
      );

      final first = manager.execute(
        StateTransaction(
          campaignId: 'campaign-1',
          expectedRevision: 0,
          changes: <StateChange>[blocking],
          changedAt: DateTime.utc(2026, 8, 10, 12),
        ),
      );
      await entered.future;

      await expectLater(
        manager.execute(
          StateTransaction(
            campaignId: 'campaign-1',
            expectedRevision: 0,
            changes: <StateChange>[
              _RecordingChange(name: 'second', log: <String>[]),
            ],
            changedAt: DateTime.utc(2026, 8, 10, 12),
          ),
        ),
        throwsA(isA<StateTransactionInProgressException>()),
      );

      release.complete();
      final completed = await first;
      expect(completed.revision, 1);
    });

    test('captures rollback failures without hiding original cause', () async {
      final repository = _MemoryStateRepository();
      final manager = StateManager(repository: repository);
      final first = _RecordingChange(
        name: 'first',
        log: <String>[],
        rollbackError: StateError('rollback failed'),
      );
      final second = _RecordingChange(
        name: 'second',
        log: <String>[],
        applyError: StateError('apply failed'),
      );

      try {
        await manager.execute(
          StateTransaction(
            campaignId: 'campaign-1',
            expectedRevision: 0,
            changes: <StateChange>[first, second],
            changedAt: DateTime.utc(2026, 8, 10, 12),
          ),
        );
        fail('Expected StateTransactionException.');
      } on StateTransactionException catch (error) {
        expect(error.cause, isA<StateError>());
        expect(error.rollbackFailures, hasLength(1));
      }
    });
  });
}

final class _RecordingChange implements StateChange {
  _RecordingChange({
    required this.name,
    required this.log,
    this.validationError,
    this.applyError,
    this.rollbackError,
    this.onApply,
  });

  final String name;
  final List<String> log;
  final Object? validationError;
  final Object? applyError;
  final Object? rollbackError;
  final Future<void> Function()? onApply;

  @override
  Future<void> validate() async {
    log.add('validate:$name');
    if (validationError != null) {
      throw validationError!;
    }
  }

  @override
  Future<void> apply() async {
    log.add('apply:$name');
    if (onApply != null) {
      await onApply!();
    }
    if (applyError != null) {
      throw applyError!;
    }
  }

  @override
  Future<void> rollback() async {
    log.add('rollback:$name');
    if (rollbackError != null) {
      throw rollbackError!;
    }
  }
}

final class _MemoryStateRepository implements CampaignStateRepository {
  _MemoryStateRepository({
    Iterable<CampaignState> initial = const <CampaignState>[],
    this.failSave = false,
  }) {
    for (final state in initial) {
      _states[state.campaignId] = state;
    }
  }

  final bool failSave;
  final Map<String, CampaignState> _states = <String, CampaignState>{};

  @override
  Future<CampaignState?> getByCampaignId(String campaignId) async {
    return _states[campaignId];
  }

  @override
  Future<void> save(CampaignState state) async {
    if (failSave) {
      throw StateError('state persistence failed');
    }
    _states[state.campaignId] = state;
  }
}
