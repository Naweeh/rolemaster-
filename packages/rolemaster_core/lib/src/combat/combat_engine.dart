import '../encounter/encounter.dart';
import '../encounter/encounter_status.dart';
import '../resolution/resolution_engine.dart';
import '../resolution/resolution_request.dart';
import '../ruleset/effective_ruleset.dart';
import 'combat_participant.dart';
import 'combat_state.dart';

final class CombatEngine {
  CombatEngine({
    required CombatParticipantResolver participantResolver,
    required ResolutionEngine resolutionEngine,
  })  : _participantResolver = participantResolver,
        _resolutionEngine = resolutionEngine;

  final CombatParticipantResolver _participantResolver;
  final ResolutionEngine _resolutionEngine;

  Future<CombatState> start({
    required Encounter encounter,
    required EffectiveRuleset ruleset,
    required List<String> turnOrder,
  }) async {
    _validateEncounter(encounter, ruleset);
    final participants = await _participantResolver.resolve(encounter);
    if (participants.isEmpty) {
      throw StateError('Combat requires at least one participant.');
    }
    final byKey = <String, CombatParticipant>{
      for (final participant in participants) participant.key: participant,
    };
    final keys = turnOrder.map((key) => key.trim().toLowerCase()).toList();
    if (keys.length != byKey.length ||
        keys.toSet().length != byKey.length ||
        !keys.every(byKey.containsKey)) {
      throw ArgumentError('Turn order must contain each participant once.');
    }
    return CombatState(
      encounterId: encounter.id,
      campaignId: encounter.campaignId,
      rulesetId: ruleset.rulesetId,
      rulesetVersion: ruleset.version,
      turnOrder: <CombatParticipant>[for (final key in keys) byKey[key]!],
    );
  }

  CombatState resolveAction({
    required Encounter encounter,
    required EffectiveRuleset ruleset,
    required CombatState state,
    required String actorKey,
    required ResolutionRequest request,
  }) {
    _validateEncounter(encounter, ruleset);
    if (state.encounterId != encounter.id ||
        state.campaignId != encounter.campaignId ||
        state.rulesetId != ruleset.rulesetId ||
        state.rulesetVersion != ruleset.version) {
      throw StateError('Combat state belongs to another encounter.');
    }
    final encounterKeys =
        encounter.participants.map((item) => item.key).toSet();
    if (encounterKeys.length != state.turnOrder.length ||
        !state.turnOrder.every((item) => encounterKeys.contains(item.key))) {
      throw StateError('Encounter participants changed during combat.');
    }
    final key = actorKey.trim().toLowerCase();
    if (key != state.currentParticipant.key) {
      throw StateError('Only the current participant can act.');
    }
    final result = _resolutionEngine.resolve(
      ruleset: ruleset,
      request: request,
    );
    return state.addAction(CombatAction(actorKey: key, result: result));
  }

  void _validateEncounter(Encounter encounter, EffectiveRuleset ruleset) {
    if (encounter.status != EncounterStatus.active) {
      throw StateError('Combat requires an active encounter.');
    }
    if (ruleset.campaignId != encounter.campaignId) {
      throw StateError('Combat ruleset belongs to another campaign.');
    }
  }
}
