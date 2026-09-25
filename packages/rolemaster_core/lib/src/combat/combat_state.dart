import '../resolution/resolution_result.dart';
import 'combat_participant.dart';

final class CombatAction {
  CombatAction({required String actorKey, required this.result})
      : actorKey = actorKey.trim().toLowerCase() {
    if (this.actorKey.isEmpty) {
      throw ArgumentError('Combat action actorKey is required.');
    }
  }

  final String actorKey;
  final ResolutionResult result;
}

final class CombatState {
  CombatState({
    required String encounterId,
    required String campaignId,
    required Iterable<CombatParticipant> turnOrder,
    this.round = 1,
    this.turnIndex = 0,
    Iterable<CombatAction> actions = const <CombatAction>[],
  })  : encounterId = encounterId.trim(),
        campaignId = campaignId.trim(),
        turnOrder = List<CombatParticipant>.unmodifiable(turnOrder),
        actions = List<CombatAction>.unmodifiable(actions) {
    if (this.encounterId.isEmpty || this.campaignId.isEmpty) {
      throw ArgumentError('Combat encounterId and campaignId are required.');
    }
    if (this.turnOrder.isEmpty ||
        round < 1 ||
        turnIndex < 0 ||
        turnIndex >= this.turnOrder.length) {
      throw ArgumentError('Combat requires participants and a valid turn.');
    }
    if (this.turnOrder.map((item) => item.key).toSet().length !=
        this.turnOrder.length) {
      throw ArgumentError(
          'Combat turn order must contain unique participants.');
    }
    for (final action in this.actions) {
      if (!this.turnOrder.any((item) => item.key == action.actorKey) ||
          action.result.campaignId != this.campaignId) {
        throw ArgumentError('Combat action does not belong to this combat.');
      }
    }
  }

  final String encounterId;
  final String campaignId;
  final List<CombatParticipant> turnOrder;
  final int round;
  final int turnIndex;
  final List<CombatAction> actions;

  CombatParticipant get currentParticipant => turnOrder[turnIndex];

  CombatState advanceTurn() {
    final next = turnIndex + 1;
    return CombatState(
      encounterId: encounterId,
      campaignId: campaignId,
      turnOrder: turnOrder,
      round: next == turnOrder.length ? round + 1 : round,
      turnIndex: next % turnOrder.length,
      actions: actions,
    );
  }

  CombatState addAction(CombatAction action) {
    if (action.actorKey != currentParticipant.key) {
      throw StateError('Only the current participant can act.');
    }
    return CombatState(
      encounterId: encounterId,
      campaignId: campaignId,
      turnOrder: turnOrder,
      round: round,
      turnIndex: turnIndex,
      actions: <CombatAction>[...actions, action],
    );
  }
}
